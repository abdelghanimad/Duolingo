import 'package:test/test.dart';

import 'package:global_guess_live_core/global_guess_live_core.dart';

void main() {
  group('FuzzyMatcher.bestMatch — exact', () {
    test('matches an exact single-word target inside a sentence', () {
      final r = FuzzyMatcher.bestMatch('I think it is an umbrella', ['umbrella']);
      expect(r.matched, isTrue);
      expect(r.targetWord, 'umbrella');
      expect(r.distance, 0);
    });

    test('returns no-match for unrelated text', () {
      final r = FuzzyMatcher.bestMatch('the sky is blue', ['umbrella']);
      expect(r.matched, isFalse);
    });

    test('returns no-match for empty input', () {
      expect(FuzzyMatcher.bestMatch('', ['umbrella']).matched, isFalse);
      expect(FuzzyMatcher.bestMatch('   ', ['umbrella']).matched, isFalse);
    });
  });

  group('FuzzyMatcher.bestMatch — fuzzy (distance ≤ 1)', () {
    test('tolerates a single-letter typo', () {
      final r = FuzzyMatcher.bestMatch('umbrela', ['umbrella']);
      expect(r.matched, isTrue);
      expect(r.distance, 1);
    });

    test('tolerates a missing trailing letter', () {
      final r = FuzzyMatcher.bestMatch('umbrell', ['umbrella']);
      expect(r.matched, isTrue);
    });

    test('rejects 2+ edits with default cutoff', () {
      final r = FuzzyMatcher.bestMatch('umbrla', ['umbrella']);
      expect(r.matched, isFalse);
    });

    test('respects a custom cutoff', () {
      final r = FuzzyMatcher.bestMatch('umbrla', ['umbrella'], maxDistance: 2);
      expect(r.matched, isTrue);
    });
  });

  group('FuzzyMatcher.bestMatch — synonyms', () {
    test('matches against any candidate', () {
      final r = FuzzyMatcher.bestMatch(
        'I see a parasol over there',
        ['umbrella', 'brolly', 'parasol'],
      );
      expect(r.matched, isTrue);
      expect(r.targetWord, 'parasol');
    });

    test('prefers the closer (lower distance) match', () {
      // "kat" is dist 1 from "cat" and dist 2 from "kitten" — pick "cat".
      final r = FuzzyMatcher.bestMatch('kat', ['cat', 'kitten']);
      expect(r.matched, isTrue);
      expect(r.targetWord, 'cat');
    });
  });

  group('FuzzyMatcher.bestMatch — multi-word targets', () {
    test('matches a multi-word target inside a longer utterance', () {
      final r = FuzzyMatcher.bestMatch(
        'I think this is a tooth brush you know',
        ['tooth brush'],
      );
      expect(r.matched, isTrue);
      expect(r.targetWord, 'tooth brush');
    });

    test('matches Spanish multi-word target', () {
      final r = FuzzyMatcher.bestMatch(
        'creo que es un reloj de arena',
        ['reloj de arena'],
      );
      expect(r.matched, isTrue);
    });
  });

  group('FuzzyMatcher.bestMatch — Arabic', () {
    test('matches with diacritics on the input', () {
      final r = FuzzyMatcher.bestMatch('أعتقد أنها مَظَلَّة', ['مظله']);
      expect(r.matched, isTrue);
    });

    test('matches across alef-variant differences', () {
      // utterance has أ but candidate has ا
      final r = FuzzyMatcher.bestMatch('أحمد جاء', ['احمد']);
      expect(r.matched, isTrue);
    });
  });

  group('FuzzyMatcher.bestMatch — short words', () {
    test('rejects unrelated 3-letter words that differ by 2 edits', () {
      // "kid" vs "key": k=k, i≠e, d≠y → distance 2, > default cutoff.
      final r = FuzzyMatcher.bestMatch('kid', ['key']);
      expect(r.matched, isFalse);
    });

    test('matches one-edit short words (this is by design)', () {
      // "ket" vs "key" is 1 edit. Default cutoff allows it. Callers that
      // want stricter behaviour for very short words should constrain via
      // synonyms or raise the matcher's confidence threshold.
      final r = FuzzyMatcher.bestMatch('ket', ['key']);
      expect(r.matched, isTrue);
      expect(r.distance, 1);
    });
  });
}
