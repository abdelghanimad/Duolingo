/// Fuzzy matching of free-form STT text against a set of target words.
///
/// We keep the algorithm small and dependency-free:
///   * Normalize both sides via [TextNormalizer].
///   * For every word in the candidate sentence, compare it against every
///     target with Levenshtein distance.
///   * Accept a match when distance ≤ [maxDistance] (default 1).
///
/// The default `maxDistance = 1` tolerates a single insertion / deletion /
/// substitution — enough to swallow a missed plural ("apples" vs "apple")
/// or a misheard consonant, without producing false positives on short
/// words like "key" / "kid".
library;

import 'text_normalizer.dart';

class MatchResult {
  const MatchResult({
    required this.matched,
    required this.candidate,
    required this.targetWord,
    required this.distance,
  });

  final bool matched;
  final String candidate;
  final String targetWord;
  final int distance;

  static const MatchResult none = MatchResult(
    matched: false,
    candidate: '',
    targetWord: '',
    distance: -1,
  );
}

class FuzzyMatcher {
  /// Returns the best (lowest-distance) match between any token of [utterance]
  /// and any of [targets]. If nothing is within [maxDistance], returns
  /// [MatchResult.none].
  ///
  /// Both [utterance] and [targets] are normalized internally — callers can
  /// pass raw STT text and raw DB rows.
  ///
  /// For multi-word targets (e.g. "tooth brush", "reloj de arena") the full
  /// normalized utterance is also compared as a whole, so that
  /// "i think it is a tooth brush" still matches "tooth brush".
  static MatchResult bestMatch(
    String utterance,
    Iterable<String> targets, {
    int maxDistance = 1,
  }) {
    final normalizedUtterance = TextNormalizer.normalize(utterance);
    if (normalizedUtterance.isEmpty) return MatchResult.none;

    final tokens = normalizedUtterance.split(' ').where((t) => t.isNotEmpty);

    MatchResult best = MatchResult.none;

    for (final rawTarget in targets) {
      final target = TextNormalizer.normalize(rawTarget);
      if (target.isEmpty) continue;

      final isMultiWord = target.contains(' ');

      if (isMultiWord) {
        // Sliding-window over tokens of the same width as the target.
        final targetTokenCount = target.split(' ').length;
        final allTokens = normalizedUtterance.split(' ');
        for (var i = 0; i + targetTokenCount <= allTokens.length; i++) {
          final window = allTokens.sublist(i, i + targetTokenCount).join(' ');
          final d = _levenshtein(window, target, maxDistance);
          if (d <= maxDistance &&
              (best.distance == -1 || d < best.distance)) {
            best = MatchResult(
              matched: true,
              candidate: window,
              targetWord: rawTarget,
              distance: d,
            );
            if (d == 0) return best;
          }
        }
      } else {
        for (final tok in tokens) {
          final d = _levenshtein(tok, target, maxDistance);
          if (d <= maxDistance &&
              (best.distance == -1 || d < best.distance)) {
            best = MatchResult(
              matched: true,
              candidate: tok,
              targetWord: rawTarget,
              distance: d,
            );
            if (d == 0) return best;
          }
        }
      }
    }

    return best;
  }

  /// Bounded Levenshtein distance. Returns `cutoff + 1` once any cell in the
  /// dp row exceeds [cutoff], so we stop early on long strings.
  static int _levenshtein(String a, String b, int cutoff) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    if ((a.length - b.length).abs() > cutoff) return cutoff + 1;

    final n = a.length;
    final m = b.length;
    var prev = List<int>.generate(m + 1, (i) => i);
    var curr = List<int>.filled(m + 1, 0);

    for (var i = 1; i <= n; i++) {
      curr[0] = i;
      var rowMin = curr[0];
      for (var j = 1; j <= m; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        var v = del < ins ? del : ins;
        if (sub < v) v = sub;
        curr[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > cutoff) return cutoff + 1;
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[m];
  }
}
