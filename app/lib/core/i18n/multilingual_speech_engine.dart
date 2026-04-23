import 'dart:async';

import '../i18n/languages.dart';

/// Abstract bridge to the platform speech recogniser. The real
/// implementation in production is `package:speech_to_text`, but we
/// keep the interface narrow so the engine can be mocked in tests and
/// swapped for cloud STT (Google / Azure / Whisper) without touching
/// game code.
abstract class SpeechBackend {
  Future<bool> initialize();
  Future<List<String>> availableLocales();
  Future<void> stop();
  Future<void> listen({
    required String localeId,
    required void Function(String partial, double confidence) onResult,
  });
}

/// Multilingual speech recogniser.
///
/// The player picks the *target* language they want to learn (e.g.
/// Japanese). The engine immediately re-binds the platform listener to
/// that language's `speechTag` (`ja-JP`) so audio is decoded with the
/// correct acoustic + language model. No app restart, no UI flicker.
///
/// Accent tolerance:
///   • We never compare strings character-for-character. Every result
///     is run through a Unicode-normalised similarity score (Dice /
///     Levenshtein-ratio) against every accepted form: the canonical
///     `names[lang]` *and* every entry in `synonyms[lang]`.
///   • The threshold is per-mode and per-skill-level. Beginners get a
///     forgiving 0.55 so a heavy accent still scores a win — the goal
///     is encouragement, not phonetic perfection.
class MultilingualSpeechEngine {
  MultilingualSpeechEngine(this._backend);

  final SpeechBackend _backend;
  LearningLanguage? _current;
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    _ready = await _backend.initialize();
  }

  /// Hot-swap the active learning language. Safe to call while a
  /// listening session is running — we cancel cleanly first.
  Future<void> setLanguage(LearningLanguage lang) async {
    await ensureReady();
    if (_current?.speechTag == lang.speechTag) return;
    await _backend.stop();
    _current = lang;
  }

  /// Resolve the *best* locale tag the device actually supports for
  /// the requested language, falling back from e.g. `ja-JP` -> `ja`.
  Future<String> _resolveLocale(LearningLanguage lang) async {
    final available = (await _backend.availableLocales())
        .map((s) => s.toLowerCase())
        .toSet();
    final tag = lang.speechTag.toLowerCase();
    if (available.contains(tag)) return lang.speechTag;
    final root = tag.split('-').first;
    final fallback = available.firstWhere(
      (a) => a.startsWith('$root-') || a == root,
      orElse: () => lang.speechTag,
    );
    return fallback;
  }

  /// Begin listening; emits guesses + similarity scores.
  Future<Stream<GuessResult>> listenFor({
    required Set<String> acceptedForms, // canonical + synonyms
    required double threshold,          // 0.0 – 1.0
  }) async {
    final lang = _current;
    if (lang == null) {
      throw StateError('setLanguage() must be called before listenFor()');
    }
    final locale = await _resolveLocale(lang);
    final controller = StreamController<GuessResult>();

    await _backend.listen(
      localeId: locale,
      onResult: (heard, confidence) {
        final score = _bestSimilarity(heard, acceptedForms);
        controller.add(GuessResult(
          heard: heard,
          similarity: score,
          succeeded: score >= threshold,
          recogniserConfidence: confidence,
        ));
      },
    );
    return controller.stream;
  }

  // ---------------------------------------------------------------
  // Similarity — Sørensen–Dice on Unicode-normalised character bigrams.
  // Works for non-Latin scripts (CJK, Arabic, Devanagari) without any
  // language-specific tokenisation.
  // ---------------------------------------------------------------
  static double _bestSimilarity(String heard, Set<String> accepted) {
    if (accepted.isEmpty) return 0;
    final h = _normalise(heard);
    if (h.isEmpty) return 0;
    var best = 0.0;
    for (final candidate in accepted) {
      final s = _diceCoefficient(h, _normalise(candidate));
      if (s > best) best = s;
    }
    return best;
  }

  static String _normalise(String s) {
    // Strip combining marks so accents/diacritics don't sink the score.
    // Covers: Latin/IPA combining marks (U+0300–U+036F), Arabic harakat
    // & tatweel (U+064B–U+065F, U+0670, U+06D6–U+06ED, U+0640), Hebrew
    // niqqud (U+0591–U+05BD, U+05BF, U+05C1–U+05C2, U+05C4–U+05C5,
    // U+05C7), Devanagari combining marks (U+0951–U+0954, U+0981,
    // U+093C, U+094D), and the generic combining-half-marks block
    // (U+FE20–U+FE2F). This is enough for the languages we ship; full
    // ICU NFD normalisation would be ideal but pulls in a heavy
    // dependency we don't yet need.
    final lower = s.toLowerCase().trim();
    final out = StringBuffer();
    for (final cu in lower.runes) {
      if (_isCombining(cu)) continue;
      out.writeCharCode(cu);
    }
    return out.toString();
  }

  static bool _isCombining(int cu) {
    return (cu >= 0x0300 && cu <= 0x036F) ||      // Latin combining marks
        cu == 0x0640 ||                             // Arabic tatweel
        (cu >= 0x064B && cu <= 0x065F) ||           // Arabic harakat
        cu == 0x0670 ||                             // Arabic alef above
        (cu >= 0x06D6 && cu <= 0x06ED) ||           // Quranic marks
        (cu >= 0x0591 && cu <= 0x05BD) ||           // Hebrew niqqud
        cu == 0x05BF ||
        cu == 0x05C1 || cu == 0x05C2 ||
        cu == 0x05C4 || cu == 0x05C5 || cu == 0x05C7 ||
        cu == 0x093C || cu == 0x094D || cu == 0x0981 || // Devanagari
        (cu >= 0x0951 && cu <= 0x0954) ||
        (cu >= 0xFE20 && cu <= 0xFE2F);             // Combining half-marks
  }

  static double _diceCoefficient(String a, String b) {
    if (a == b) return 1;
    if (a.length < 2 || b.length < 2) return 0;
    final aBigrams = <String, int>{};
    for (var i = 0; i < a.length - 1; i++) {
      final bg = a.substring(i, i + 2);
      aBigrams[bg] = (aBigrams[bg] ?? 0) + 1;
    }
    var matches = 0;
    for (var i = 0; i < b.length - 1; i++) {
      final bg = b.substring(i, i + 2);
      final c = aBigrams[bg] ?? 0;
      if (c > 0) {
        matches++;
        aBigrams[bg] = c - 1;
      }
    }
    return (2.0 * matches) / ((a.length - 1) + (b.length - 1));
  }
}

class GuessResult {
  const GuessResult({
    required this.heard,
    required this.similarity,
    required this.succeeded,
    required this.recogniserConfidence,
  });

  final String heard;
  final double similarity;
  final bool succeeded;
  final double recogniserConfidence;
}
