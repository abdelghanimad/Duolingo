// Catalogue of supported learning languages for the Universal Language
// Engine. Each entry maps to the same BCP-47 keys used in
// `items.names` / `items.synonyms` (see supabase/migrations/0001_*).
//
// `speechTag` is what we hand to the platform speech recogniser
// (Android / iOS / Web). It can differ from `code` when the OS expects
// a country: e.g. learning generic "ar" but listening as "ar-SA".

class LearningLanguage {
  const LearningLanguage({
    required this.code,        // BCP-47 root used as JSONB key
    required this.nativeName,  // Always shown in the language's own script
    required this.englishName, // Fallback / search
    required this.flag,        // Flag emoji — works on every OS without assets
    required this.speechTag,   // Tag passed to SpeechToText.listen(localeId:)
    this.isRtl = false,
  });

  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
  final String speechTag;
  final bool isRtl;
}

/// 50+ languages — matches the minimum enforced by the
/// `items_min_50_languages` CHECK constraint in Postgres.
const List<LearningLanguage> kSupportedLanguages = <LearningLanguage>[
  LearningLanguage(code: 'ar',      nativeName: 'العربية',    englishName: 'Arabic',      flag: '🇸🇦', speechTag: 'ar-SA', isRtl: true),
  LearningLanguage(code: 'en',      nativeName: 'English',    englishName: 'English',     flag: '🇺🇸', speechTag: 'en-US'),
  LearningLanguage(code: 'fr',      nativeName: 'Français',   englishName: 'French',      flag: '🇫🇷', speechTag: 'fr-FR'),
  LearningLanguage(code: 'es',      nativeName: 'Español',    englishName: 'Spanish',     flag: '🇪🇸', speechTag: 'es-ES'),
  LearningLanguage(code: 'de',      nativeName: 'Deutsch',    englishName: 'German',      flag: '🇩🇪', speechTag: 'de-DE'),
  LearningLanguage(code: 'it',      nativeName: 'Italiano',   englishName: 'Italian',     flag: '🇮🇹', speechTag: 'it-IT'),
  LearningLanguage(code: 'pt',      nativeName: 'Português',  englishName: 'Portuguese',  flag: '🇵🇹', speechTag: 'pt-PT'),
  LearningLanguage(code: 'nl',      nativeName: 'Nederlands', englishName: 'Dutch',       flag: '🇳🇱', speechTag: 'nl-NL'),
  LearningLanguage(code: 'ru',      nativeName: 'Русский',    englishName: 'Russian',     flag: '🇷🇺', speechTag: 'ru-RU'),
  LearningLanguage(code: 'uk',      nativeName: 'Українська', englishName: 'Ukrainian',   flag: '🇺🇦', speechTag: 'uk-UA'),
  LearningLanguage(code: 'pl',      nativeName: 'Polski',     englishName: 'Polish',      flag: '🇵🇱', speechTag: 'pl-PL'),
  LearningLanguage(code: 'cs',      nativeName: 'Čeština',    englishName: 'Czech',       flag: '🇨🇿', speechTag: 'cs-CZ'),
  LearningLanguage(code: 'sk',      nativeName: 'Slovenčina', englishName: 'Slovak',      flag: '🇸🇰', speechTag: 'sk-SK'),
  LearningLanguage(code: 'ro',      nativeName: 'Română',     englishName: 'Romanian',    flag: '🇷🇴', speechTag: 'ro-RO'),
  LearningLanguage(code: 'hu',      nativeName: 'Magyar',     englishName: 'Hungarian',   flag: '🇭🇺', speechTag: 'hu-HU'),
  LearningLanguage(code: 'el',      nativeName: 'Ελληνικά',   englishName: 'Greek',       flag: '🇬🇷', speechTag: 'el-GR'),
  LearningLanguage(code: 'tr',      nativeName: 'Türkçe',     englishName: 'Turkish',     flag: '🇹🇷', speechTag: 'tr-TR'),
  LearningLanguage(code: 'fa',      nativeName: 'فارسی',      englishName: 'Persian',     flag: '🇮🇷', speechTag: 'fa-IR', isRtl: true),
  LearningLanguage(code: 'he',      nativeName: 'עברית',      englishName: 'Hebrew',      flag: '🇮🇱', speechTag: 'he-IL', isRtl: true),
  LearningLanguage(code: 'ur',      nativeName: 'اردو',       englishName: 'Urdu',        flag: '🇵🇰', speechTag: 'ur-PK', isRtl: true),
  LearningLanguage(code: 'hi',      nativeName: 'हिन्दी',       englishName: 'Hindi',       flag: '🇮🇳', speechTag: 'hi-IN'),
  LearningLanguage(code: 'bn',      nativeName: 'বাংলা',       englishName: 'Bengali',     flag: '🇧🇩', speechTag: 'bn-BD'),
  LearningLanguage(code: 'ta',      nativeName: 'தமிழ்',      englishName: 'Tamil',       flag: '🇮🇳', speechTag: 'ta-IN'),
  LearningLanguage(code: 'te',      nativeName: 'తెలుగు',     englishName: 'Telugu',      flag: '🇮🇳', speechTag: 'te-IN'),
  LearningLanguage(code: 'ja',      nativeName: '日本語',      englishName: 'Japanese',    flag: '🇯🇵', speechTag: 'ja-JP'),
  LearningLanguage(code: 'ko',      nativeName: '한국어',       englishName: 'Korean',      flag: '🇰🇷', speechTag: 'ko-KR'),
  LearningLanguage(code: 'zh',      nativeName: '简体中文',    englishName: 'Chinese (S)', flag: '🇨🇳', speechTag: 'zh-CN'),
  LearningLanguage(code: 'zh-Hant', nativeName: '繁體中文',    englishName: 'Chinese (T)', flag: '🇹🇼', speechTag: 'zh-TW'),
  LearningLanguage(code: 'th',      nativeName: 'ไทย',        englishName: 'Thai',        flag: '🇹🇭', speechTag: 'th-TH'),
  LearningLanguage(code: 'vi',      nativeName: 'Tiếng Việt', englishName: 'Vietnamese',  flag: '🇻🇳', speechTag: 'vi-VN'),
  LearningLanguage(code: 'id',      nativeName: 'Indonesia',  englishName: 'Indonesian',  flag: '🇮🇩', speechTag: 'id-ID'),
  LearningLanguage(code: 'ms',      nativeName: 'Melayu',     englishName: 'Malay',       flag: '🇲🇾', speechTag: 'ms-MY'),
  LearningLanguage(code: 'tl',      nativeName: 'Tagalog',    englishName: 'Tagalog',     flag: '🇵🇭', speechTag: 'fil-PH'),
  LearningLanguage(code: 'sw',      nativeName: 'Kiswahili',  englishName: 'Swahili',     flag: '🇰🇪', speechTag: 'sw-KE'),
  LearningLanguage(code: 'am',      nativeName: 'አማርኛ',       englishName: 'Amharic',     flag: '🇪🇹', speechTag: 'am-ET'),
  LearningLanguage(code: 'ha',      nativeName: 'Hausa',      englishName: 'Hausa',       flag: '🇳🇬', speechTag: 'ha-NG'),
  LearningLanguage(code: 'yo',      nativeName: 'Yorùbá',     englishName: 'Yoruba',      flag: '🇳🇬', speechTag: 'yo-NG'),
  LearningLanguage(code: 'zu',      nativeName: 'isiZulu',    englishName: 'Zulu',        flag: '🇿🇦', speechTag: 'zu-ZA'),
  LearningLanguage(code: 'af',      nativeName: 'Afrikaans',  englishName: 'Afrikaans',   flag: '🇿🇦', speechTag: 'af-ZA'),
  LearningLanguage(code: 'sv',      nativeName: 'Svenska',    englishName: 'Swedish',     flag: '🇸🇪', speechTag: 'sv-SE'),
  LearningLanguage(code: 'no',      nativeName: 'Norsk',      englishName: 'Norwegian',   flag: '🇳🇴', speechTag: 'nb-NO'),
  LearningLanguage(code: 'da',      nativeName: 'Dansk',      englishName: 'Danish',      flag: '🇩🇰', speechTag: 'da-DK'),
  LearningLanguage(code: 'fi',      nativeName: 'Suomi',      englishName: 'Finnish',     flag: '🇫🇮', speechTag: 'fi-FI'),
  LearningLanguage(code: 'is',      nativeName: 'Íslenska',   englishName: 'Icelandic',   flag: '🇮🇸', speechTag: 'is-IS'),
  LearningLanguage(code: 'et',      nativeName: 'Eesti',      englishName: 'Estonian',    flag: '🇪🇪', speechTag: 'et-EE'),
  LearningLanguage(code: 'lv',      nativeName: 'Latviešu',   englishName: 'Latvian',     flag: '🇱🇻', speechTag: 'lv-LV'),
  LearningLanguage(code: 'lt',      nativeName: 'Lietuvių',   englishName: 'Lithuanian',  flag: '🇱🇹', speechTag: 'lt-LT'),
  LearningLanguage(code: 'sl',      nativeName: 'Slovenščina',englishName: 'Slovenian',   flag: '🇸🇮', speechTag: 'sl-SI'),
  LearningLanguage(code: 'hr',      nativeName: 'Hrvatski',   englishName: 'Croatian',    flag: '🇭🇷', speechTag: 'hr-HR'),
  LearningLanguage(code: 'sr',      nativeName: 'Српски',     englishName: 'Serbian',     flag: '🇷🇸', speechTag: 'sr-RS'),
  LearningLanguage(code: 'bg',      nativeName: 'Български',  englishName: 'Bulgarian',   flag: '🇧🇬', speechTag: 'bg-BG'),
  LearningLanguage(code: 'ca',      nativeName: 'Català',     englishName: 'Catalan',     flag: '🇪🇸', speechTag: 'ca-ES'),
  LearningLanguage(code: 'eu',      nativeName: 'Euskara',    englishName: 'Basque',      flag: '🇪🇸', speechTag: 'eu-ES'),
  LearningLanguage(code: 'gl',      nativeName: 'Galego',     englishName: 'Galician',    flag: '🇪🇸', speechTag: 'gl-ES'),
  LearningLanguage(code: 'cy',      nativeName: 'Cymraeg',    englishName: 'Welsh',       flag: '🇬🇧', speechTag: 'cy-GB'),
  LearningLanguage(code: 'ga',      nativeName: 'Gaeilge',    englishName: 'Irish',       flag: '🇮🇪', speechTag: 'ga-IE'),
];
