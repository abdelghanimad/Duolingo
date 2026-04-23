-- =============================================================================
--  Global Guess Live — initial schema
--  Postgres / Supabase
-- =============================================================================
--  Conventions:
--   * UUID primary keys for user-visible entities
--   * timestamptz everywhere; default now() at millisecond resolution
--   * Append-only event log (`room_events`) is the source of truth
--   * Row-level security ON for every table that contains user data
-- =============================================================================

create extension if not exists "pgcrypto";

-- Local-dev convenience: Supabase always provides `auth.uid()`. When running
-- this migration outside Supabase (e.g. plain Postgres in CI / local tests),
-- create a no-op stub so the RLS policies below still parse and apply.
do $$
begin
    if not exists (select 1 from pg_namespace where nspname = 'auth') then
        create schema auth;
    end if;
    if not exists (
        select 1 from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'auth' and p.proname = 'uid'
    ) then
        create function auth.uid() returns uuid language sql stable as $f$
            select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
        $f$;
    end if;
end $$;

-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------
create table if not exists public.users (
    id              uuid primary key default gen_random_uuid(),
    auth_uid        uuid unique,                       -- maps to auth.users.id
    display_name    text not null check (char_length(display_name) between 1 and 40),
    native_lang     text not null check (char_length(native_lang)   = 2),
    learning_lang   text not null check (char_length(learning_lang) = 2),
    level           int  not null default 1 check (level between 1 and 100),
    xp              int  not null default 0 check (xp >= 0),
    avatar_url      text,
    created_at      timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- puzzles + translations
-- -----------------------------------------------------------------------------
create table if not exists public.puzzles (
    id          uuid primary key default gen_random_uuid(),
    slug        text unique not null,                  -- e.g. 'umbrella'
    vector_url  text not null,                         -- SVG on CDN / Storage
    category    text not null,                         -- 'tools', 'food', ...
    difficulty  int  not null check (difficulty between 1 and 5),
    is_active   boolean not null default true,
    created_at  timestamptz not null default now()
);

create table if not exists public.puzzle_translations (
    puzzle_id          uuid not null references public.puzzles(id) on delete cascade,
    lang_code          text not null check (char_length(lang_code) = 2),
    target_word        text not null,
    accepted_synonyms  text[] not null default '{}',
    phonetic           text,
    primary key (puzzle_id, lang_code)
);

create index if not exists puzzle_translations_lang_word_idx
    on public.puzzle_translations (lang_code, target_word);

create index if not exists puzzle_translations_synonyms_gin
    on public.puzzle_translations using gin (accepted_synonyms);

-- -----------------------------------------------------------------------------
-- rooms
-- -----------------------------------------------------------------------------
do $$ begin
    create type public.room_status as enum ('waiting', 'active', 'finished');
exception when duplicate_object then null; end $$;

create table if not exists public.rooms (
    id                          uuid primary key default gen_random_uuid(),
    code                        text unique not null,           -- 6-char share code
    status                      public.room_status not null default 'waiting',
    player_a                    uuid references public.users(id) on delete set null,
    player_b                    uuid references public.users(id) on delete set null,
    puzzle_for_a                uuid references public.puzzles(id),
    puzzle_for_b                uuid references public.puzzles(id),
    started_at                  timestamptz,
    ended_at                    timestamptz,
    winner_id                   uuid references public.users(id),
    webrtc_signaling_channel    text not null,
    created_at                  timestamptz not null default now()
);

create index if not exists rooms_status_created_idx
    on public.rooms (status, created_at desc);

-- -----------------------------------------------------------------------------
-- room_events  — append-only event log
-- -----------------------------------------------------------------------------
do $$ begin
    create type public.room_event_type as enum (
        'joined', 'puzzle_revealed', 'word_detected', 'won', 'left', 'interrupted'
    );
exception when duplicate_object then null; end $$;

create table if not exists public.room_events (
    id          bigserial primary key,
    room_id     uuid not null references public.rooms(id) on delete cascade,
    event_type  public.room_event_type not null,
    actor_id    uuid references public.users(id),
    payload     jsonb not null default '{}'::jsonb,
    created_at  timestamptz not null default clock_timestamp()
);

create index if not exists room_events_room_created_idx
    on public.room_events (room_id, created_at desc);

-- Race-safe: at most one 'won' event per room ever wins.
create unique index if not exists room_events_one_won_per_room
    on public.room_events (room_id) where event_type = 'won';

-- -----------------------------------------------------------------------------
-- game_results
-- -----------------------------------------------------------------------------
create table if not exists public.game_results (
    room_id      uuid primary key references public.rooms(id) on delete cascade,
    winner_id    uuid references public.users(id),
    loser_id     uuid references public.users(id),
    duration_ms  int  not null check (duration_ms >= 0),
    puzzle_id    uuid references public.puzzles(id),
    xp_awarded   int  not null default 0 check (xp_awarded >= 0),
    created_at   timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- learned_words
-- -----------------------------------------------------------------------------
create table if not exists public.learned_words (
    user_id       uuid not null references public.users(id) on delete cascade,
    puzzle_id     uuid not null references public.puzzles(id) on delete cascade,
    lang_code     text not null check (char_length(lang_code) = 2),
    times_seen    int  not null default 0 check (times_seen >= 0),
    times_won     int  not null default 0 check (times_won  >= 0),
    last_seen_at  timestamptz not null default now(),
    primary key (user_id, puzzle_id, lang_code)
);

-- =============================================================================
-- Trigger: on a 'won' event, finalize the room and write game_results.
-- Runs in the same transaction as the INSERT so observers see a consistent state.
-- =============================================================================
create or replace function public.handle_won_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_loser     uuid;
    v_started   timestamptz;
    v_puzzle    uuid;
begin
    if new.event_type <> 'won' then
        return new;
    end if;

    select
        case when r.player_a = new.actor_id then r.player_b else r.player_a end,
        coalesce(r.started_at, r.created_at),
        case when r.player_a = new.actor_id then r.puzzle_for_a else r.puzzle_for_b end
    into v_loser, v_started, v_puzzle
    from public.rooms r
    where r.id = new.room_id
    for update;

    update public.rooms
       set status    = 'finished',
           winner_id = new.actor_id,
           ended_at  = new.created_at
     where id = new.room_id;

    insert into public.game_results
        (room_id, winner_id, loser_id, duration_ms, puzzle_id, xp_awarded)
    values
        (new.room_id,
         new.actor_id,
         v_loser,
         greatest(0, (extract(epoch from (new.created_at - v_started)) * 1000)::int),
         v_puzzle,
         10)
    on conflict (room_id) do nothing;

    return new;
end;
$$;

drop trigger if exists trg_room_events_won on public.room_events;
create trigger trg_room_events_won
    after insert on public.room_events
    for each row
    when (new.event_type = 'won')
    execute function public.handle_won_event();

-- =============================================================================
-- Row-Level Security
-- =============================================================================
alter table public.users               enable row level security;
alter table public.puzzles             enable row level security;
alter table public.puzzle_translations enable row level security;
alter table public.rooms               enable row level security;
alter table public.room_events         enable row level security;
alter table public.game_results        enable row level security;
alter table public.learned_words       enable row level security;

-- helper: current user's internal id
create or replace function public.current_user_id() returns uuid
    language sql stable as $$
    select id from public.users where auth_uid = auth.uid()
$$;

-- users: read self + opponents in your rooms; write self only
drop policy if exists users_read_self  on public.users;
create policy users_read_self on public.users
    for select using (auth_uid = auth.uid());

drop policy if exists users_write_self on public.users;
create policy users_write_self on public.users
    for update using (auth_uid = auth.uid()) with check (auth_uid = auth.uid());

-- puzzles + translations: public read
drop policy if exists puzzles_public_read on public.puzzles;
create policy puzzles_public_read on public.puzzles
    for select using (true);

drop policy if exists puzzle_translations_public_read on public.puzzle_translations;
create policy puzzle_translations_public_read on public.puzzle_translations
    for select using (true);

-- rooms: only the two players
drop policy if exists rooms_players_read on public.rooms;
create policy rooms_players_read on public.rooms
    for select using (
        player_a = public.current_user_id()
        or player_b = public.current_user_id()
    );

drop policy if exists rooms_players_update on public.rooms;
create policy rooms_players_update on public.rooms
    for update using (
        player_a = public.current_user_id()
        or player_b = public.current_user_id()
    );

-- room_events: read + insert restricted to the two players of the room
drop policy if exists room_events_players_read on public.room_events;
create policy room_events_players_read on public.room_events
    for select using (
        exists (
            select 1 from public.rooms r
            where r.id = room_events.room_id
              and (r.player_a = public.current_user_id()
                   or r.player_b = public.current_user_id())
        )
    );

drop policy if exists room_events_players_insert on public.room_events;
create policy room_events_players_insert on public.room_events
    for insert with check (
        actor_id = public.current_user_id()
        and exists (
            select 1 from public.rooms r
            where r.id = room_events.room_id
              and (r.player_a = public.current_user_id()
                   or r.player_b = public.current_user_id())
        )
    );

-- game_results: visible to participants
drop policy if exists game_results_participants_read on public.game_results;
create policy game_results_participants_read on public.game_results
    for select using (
        winner_id = public.current_user_id()
        or loser_id = public.current_user_id()
    );

-- learned_words: owner only
drop policy if exists learned_words_owner_all on public.learned_words;
create policy learned_words_owner_all on public.learned_words
    for all using (user_id = public.current_user_id())
            with check (user_id = public.current_user_id());

-- =============================================================================
-- Realtime publication (Supabase needs this to broadcast row changes)
-- =============================================================================
do $$ begin
    perform 1 from pg_publication where pubname = 'supabase_realtime';
    if found then
        execute 'alter publication supabase_realtime add table public.rooms';
        execute 'alter publication supabase_realtime add table public.room_events';
    end if;
exception when duplicate_object then null;
end $$;
