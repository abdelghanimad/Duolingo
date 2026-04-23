/// Thin abstraction over `supabase_flutter`'s `SupabaseClient`.
///
/// Centralising every DB / Realtime call here means:
///   * UI never imports `package:supabase_flutter` directly,
///   * tests can substitute a fake implementation,
///   * RLS expectations are documented next to the call site.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:global_guess_live_core/global_guess_live_core.dart';

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // Bootstrap
  // ---------------------------------------------------------------------------
  static Future<SupabaseService> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    return SupabaseService(Supabase.instance.client);
  }

  // ---------------------------------------------------------------------------
  // Puzzles
  // ---------------------------------------------------------------------------
  Future<Puzzle> fetchPuzzle(String id) async {
    final row = await _client
        .from('puzzles')
        .select()
        .eq('id', id)
        .single();
    return Puzzle.fromJson(row);
  }

  Future<PuzzleTranslation?> fetchTranslation({
    required String puzzleId,
    required String langCode,
  }) async {
    final row = await _client
        .from('puzzle_translations')
        .select()
        .eq('puzzle_id', puzzleId)
        .eq('lang_code', langCode)
        .maybeSingle();
    if (row == null) return null;
    return PuzzleTranslation.fromJson(row);
  }

  // ---------------------------------------------------------------------------
  // Rooms / events
  // ---------------------------------------------------------------------------
  Future<Room> fetchRoom(String id) async {
    final row =
        await _client.from('rooms').select().eq('id', id).single();
    return Room.fromJson(row);
  }

  /// Inserts a `word_detected` event. The Postgres trigger that handles
  /// `won` events is fired by a separate insert with `event_type='won'`,
  /// guarded by the partial unique index.
  Future<void> reportWordDetected({
    required String roomId,
    required String actorId,
    required String detected,
    required int distance,
  }) async {
    await _client.from('room_events').insert({
      'room_id': roomId,
      'event_type': 'word_detected',
      'actor_id': actorId,
      'payload': {'detected': detected, 'distance': distance},
    });
    // Race-safe winning insert. If we lost the race the partial unique index
    // raises 23505, which we deliberately swallow — the *other* device won.
    try {
      await _client.from('room_events').insert({
        'room_id': roomId,
        'event_type': 'won',
        'actor_id': actorId,
        'payload': {'detected': detected, 'distance': distance},
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
  }

  /// Realtime subscription on `room_events` for a given room. The returned
  /// stream is hot — the caller must cancel it.
  Stream<RoomEvent> roomEventsStream(String roomId) {
    return _client
        .from('room_events')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('id')
        .map((rows) => rows.map(RoomEvent.fromJson).toList())
        .expand((events) => events);
  }
}
