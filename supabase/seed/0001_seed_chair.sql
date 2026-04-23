-- =====================================================================
-- Seed: one fully-localised item ("chair") demonstrating the 50+
-- language requirement.  Keep this file idempotent.
-- =====================================================================

INSERT INTO categories(id, icon, names, sort_order) VALUES
  ('home_tools', 'home_repair_service',
   '{"en":"Home tools","ar":"أدوات منزلية","fr":"Outils ménagers","ja":"家庭用品","zh":"家居用品","es":"Herramientas del hogar","de":"Haushaltsgeräte","ru":"Домашние инструменты","tr":"Ev aletleri","pt":"Ferramentas domésticas"}'::jsonb,
   10),
  ('tech',       'devices',
   '{"en":"Technology","ar":"تكنولوجيا","fr":"Technologie","ja":"テクノロジー","zh":"科技","es":"Tecnología","de":"Technologie","ru":"Технологии","tr":"Teknoloji","pt":"Tecnologia"}'::jsonb,
   20),
  ('space',      'rocket_launch',
   '{"en":"Space","ar":"فضاء","fr":"Espace","ja":"宇宙","zh":"太空","es":"Espacio","de":"Weltraum","ru":"Космос","tr":"Uzay","pt":"Espaço"}'::jsonb,
   30),
  ('sport',      'sports_soccer',
   '{"en":"Sport","ar":"رياضة","fr":"Sport","ja":"スポーツ","zh":"运动","es":"Deporte","de":"Sport","ru":"Спорт","tr":"Spor","pt":"Esporte"}'::jsonb,
   40),
  ('professions','work',
   '{"en":"Professions","ar":"مهن","fr":"Métiers","ja":"職業","zh":"职业","es":"Profesiones","de":"Berufe","ru":"Профессии","tr":"Meslekler","pt":"Profissões"}'::jsonb,
   50)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------
-- "chair" in 60 languages — used to validate the 50+ CHECK constraint.
-- Inlined as a JSONB literal because jsonb_build_object() caps at 100
-- function arguments (i.e. 50 key/value pairs).
-- ---------------------------------------------------------------------
INSERT INTO items(category_id, slug, image_path, names, synonyms)
VALUES (
  'home_tools',
  'chair',
  'home_tools/chair.webp',
  $${
    "ar":"كرسي","en":"chair","fr":"chaise","es":"silla",
    "de":"Stuhl","it":"sedia","pt":"cadeira","nl":"stoel",
    "ru":"стул","uk":"стілець","pl":"krzesło","cs":"židle",
    "sk":"stolička","ro":"scaun","hu":"szék","el":"καρέκλα",
    "tr":"sandalye","fa":"صندلی","he":"כיסא","ur":"کرسی",
    "hi":"कुर्सी","bn":"চেয়ার","ta":"நாற்காலி","te":"కుర్చీ",
    "ja":"椅子","ko":"의자","zh":"椅子","zh-Hant":"椅子",
    "th":"เก้าอี้","vi":"ghế","id":"kursi","ms":"kerusi",
    "tl":"silya","sw":"kiti","am":"ወንበር","ha":"kujera",
    "yo":"àga","zu":"isihlalo","af":"stoel","sv":"stol",
    "no":"stol","da":"stol","fi":"tuoli","is":"stóll",
    "et":"tool","lv":"krēsls","lt":"kėdė","sl":"stol",
    "hr":"stolica","sr":"столица","bg":"стол","mk":"стол",
    "sq":"karrige","mt":"siġġu","eu":"aulki","ca":"cadira",
    "gl":"cadeira","cy":"cadair","ga":"cathaoir","la":"sella"
  }$$::jsonb,
  '{"en":["chair","seat"],"ar":["كرسي","كرسى"],"ja":["椅子","チェア"]}'::jsonb
)
ON CONFLICT (slug) DO NOTHING;
