-- =============================================================================
--  Seed data: a small starter puzzle bank, with translations in 5 languages.
--  Languages: en, ar, es, fr, de
-- =============================================================================

insert into public.puzzles (slug, vector_url, category, difficulty) values
    ('umbrella',     'puzzles/umbrella.svg',     'objects',  1),
    ('key',          'puzzles/key.svg',          'objects',  1),
    ('clock',        'puzzles/clock.svg',        'objects',  1),
    ('toothbrush',   'puzzles/toothbrush.svg',   'hygiene',  2),
    ('hourglass',    'puzzles/hourglass.svg',    'objects',  3),
    ('apple',        'puzzles/apple.svg',        'food',     1),
    ('bicycle',      'puzzles/bicycle.svg',      'transport',2),
    ('cat',          'puzzles/cat.svg',          'animals',  1),
    ('book',         'puzzles/book.svg',         'objects',  1),
    ('moon',         'puzzles/moon.svg',         'nature',   2)
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------------
-- Translations.
-- `accepted_synonyms` is intentionally short and lowercase; matching is fuzzy.
-- ---------------------------------------------------------------------------
with p as (select id, slug from public.puzzles)
insert into public.puzzle_translations (puzzle_id, lang_code, target_word, accepted_synonyms, phonetic)
select p.id, t.lang_code, t.target_word, t.synonyms, t.phonetic
from p
join (values
    -- umbrella
    ('umbrella',   'en', 'umbrella',   array['brolly','parasol'],            'ʌmˈbrɛlə'),
    ('umbrella',   'ar', 'مظلة',        array['شمسية','مظله'],                 NULL),
    ('umbrella',   'es', 'paraguas',   array['sombrilla'],                    NULL),
    ('umbrella',   'fr', 'parapluie',  array['ombrelle'],                     NULL),
    ('umbrella',   'de', 'regenschirm',array['schirm'],                       NULL),
    -- key
    ('key',        'en', 'key',        array['keys'],                         'kiː'),
    ('key',        'ar', 'مفتاح',       array['مفاتيح'],                       NULL),
    ('key',        'es', 'llave',      array['llaves'],                       NULL),
    ('key',        'fr', 'clé',        array['clef','cles'],                  NULL),
    ('key',        'de', 'schlüssel',  array['schluessel'],                   NULL),
    -- clock
    ('clock',      'en', 'clock',      array['watch'],                        NULL),
    ('clock',      'ar', 'ساعة',        array['ساعه'],                         NULL),
    ('clock',      'es', 'reloj',      array['relojes'],                      NULL),
    ('clock',      'fr', 'horloge',    array['montre','pendule'],             NULL),
    ('clock',      'de', 'uhr',        array['wanduhr'],                      NULL),
    -- toothbrush
    ('toothbrush', 'en', 'toothbrush', array['tooth brush'],                  NULL),
    ('toothbrush', 'ar', 'فرشاة أسنان', array['فرشاه اسنان','فرشاة الأسنان'],   NULL),
    ('toothbrush', 'es', 'cepillo de dientes', array['cepillo dental'],       NULL),
    ('toothbrush', 'fr', 'brosse à dents',     array['brosse a dents'],       NULL),
    ('toothbrush', 'de', 'zahnbürste', array['zahnbuerste'],                  NULL),
    -- hourglass
    ('hourglass',  'en', 'hourglass',  array['sandglass','sand timer'],       NULL),
    ('hourglass',  'ar', 'ساعة رملية',  array['ساعه رمليه'],                   NULL),
    ('hourglass',  'es', 'reloj de arena', array['ampolleta'],                NULL),
    ('hourglass',  'fr', 'sablier',    array[]::text[],                       NULL),
    ('hourglass',  'de', 'sanduhr',    array['stundenglas'],                  NULL),
    -- apple
    ('apple',      'en', 'apple',      array['apples'],                       NULL),
    ('apple',      'ar', 'تفاحة',       array['تفاح','تفاحه'],                 NULL),
    ('apple',      'es', 'manzana',    array['manzanas'],                     NULL),
    ('apple',      'fr', 'pomme',      array['pommes'],                       NULL),
    ('apple',      'de', 'apfel',      array['äpfel','aepfel'],               NULL),
    -- bicycle
    ('bicycle',    'en', 'bicycle',    array['bike','cycle'],                 NULL),
    ('bicycle',    'ar', 'دراجة',       array['دراجه','دراجة هوائية'],         NULL),
    ('bicycle',    'es', 'bicicleta',  array['bici'],                         NULL),
    ('bicycle',    'fr', 'vélo',       array['velo','bicyclette'],            NULL),
    ('bicycle',    'de', 'fahrrad',    array['rad'],                          NULL),
    -- cat
    ('cat',        'en', 'cat',        array['kitten','kitty'],               NULL),
    ('cat',        'ar', 'قطة',         array['قط','قطه','هرة'],               NULL),
    ('cat',        'es', 'gato',       array['gata','gatito'],                NULL),
    ('cat',        'fr', 'chat',       array['chatte','chaton'],              NULL),
    ('cat',        'de', 'katze',      array['kater','kätzchen'],             NULL),
    -- book
    ('book',       'en', 'book',       array['novel'],                        NULL),
    ('book',       'ar', 'كتاب',        array['كتب'],                          NULL),
    ('book',       'es', 'libro',      array['libros'],                       NULL),
    ('book',       'fr', 'livre',      array['bouquin'],                      NULL),
    ('book',       'de', 'buch',       array['bücher','buecher'],             NULL),
    -- moon
    ('moon',       'en', 'moon',       array['lunar'],                        NULL),
    ('moon',       'ar', 'قمر',         array['القمر'],                        NULL),
    ('moon',       'es', 'luna',       array['lunas'],                        NULL),
    ('moon',       'fr', 'lune',       array[]::text[],                       NULL),
    ('moon',       'de', 'mond',       array['vollmond'],                     NULL)
) as t(slug, lang_code, target_word, synonyms, phonetic)
  on (t.slug = p.slug)
on conflict (puzzle_id, lang_code) do nothing;
