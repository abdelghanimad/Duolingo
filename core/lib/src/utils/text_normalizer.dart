/// Text normalization for STT output.
///
/// On-device speech recognizers return free-form text with casing,
/// punctuation and (for Arabic) diacritics that vary from one utterance to
/// the next. To compare reliably against a target word we normalize both
/// sides through the same pipeline.
library;

class TextNormalizer {
  TextNormalizer._();

  // Arabic diacritics (harakat + tatweel + small marks), U+064B..U+065F,
  // U+0670, U+06D6..U+06ED, U+0640.
  static final RegExp _arabicDiacritics =
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

  // Strip everything that is not a letter, digit or whitespace.
  // Uses Unicode property classes so it works for Arabic, Cyrillic, etc.
  static final RegExp _punctuation =
      RegExp(r'[^\p{L}\p{N}\s]+', unicode: true);

  static final RegExp _whitespace = RegExp(r'\s+');

  // Common Arabic letter normalizations: alef variants → bare alef,
  // ta marbuta → ha, alef maksura → ya. These are widely accepted in
  // search/matching contexts and dramatically reduce false negatives
  // when STT picks one form and the target is stored in another.
  static const Map<String, String> _arabicLetterFolds = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ة': 'ه',
    'ى': 'ي',
  };

  /// Returns a canonicalized lowercase form of [input], safe to feed to
  /// equality / Levenshtein checks.
  ///
  /// The pipeline is deliberately conservative — it never throws and never
  /// returns null. Empty / whitespace-only input becomes `''`.
  static String normalize(String input) {
    if (input.isEmpty) return '';

    var s = input.toLowerCase();

    // Drop Arabic diacritics first so they don't interfere with letter folds.
    s = s.replaceAll(_arabicDiacritics, '');

    // Apply Arabic letter folds.
    if (_containsArabic(s)) {
      _arabicLetterFolds.forEach((from, to) {
        s = s.replaceAll(from, to);
      });
    }

    // Strip punctuation but keep whitespace.
    s = s.replaceAll(_punctuation, ' ');

    // Collapse whitespace.
    s = s.replaceAll(_whitespace, ' ').trim();

    return s;
  }

  static bool _containsArabic(String s) {
    for (final code in s.codeUnits) {
      if (code >= 0x0600 && code <= 0x06FF) return true;
    }
    return false;
  }
}
