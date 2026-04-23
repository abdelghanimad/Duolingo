import 'package:test/test.dart';

import 'package:global_guess_live_core/global_guess_live_core.dart';

void main() {
  group('TextNormalizer.normalize', () {
    test('lowercases and strips punctuation', () {
      expect(TextNormalizer.normalize('Hello, World!'), 'hello world');
    });

    test('collapses whitespace', () {
      expect(TextNormalizer.normalize('  too   many   spaces  '),
          'too many spaces');
    });

    test('returns empty for empty / whitespace input', () {
      expect(TextNormalizer.normalize(''), '');
      expect(TextNormalizer.normalize('   '), '');
    });

    test('removes Arabic diacritics (harakat)', () {
      // مَظَلَّة (with full diacritics) → مظله (folded ة → ه, no harakat)
      expect(TextNormalizer.normalize('مَظَلَّة'), 'مظله');
    });

    test('folds alef variants to bare alef', () {
      expect(TextNormalizer.normalize('أحمد'), 'احمد');
      expect(TextNormalizer.normalize('إيمان'), 'ايمان');
      expect(TextNormalizer.normalize('آمال'), 'امال');
    });

    test('folds ta marbuta to ha', () {
      expect(TextNormalizer.normalize('قطة'), 'قطه');
    });

    test('folds alef maksura to ya', () {
      expect(TextNormalizer.normalize('مستشفى'), 'مستشفي');
    });

    test('keeps non-Arabic non-ASCII letters', () {
      expect(TextNormalizer.normalize('Café'), 'café');
      expect(TextNormalizer.normalize('Über!'), 'über');
    });

    test('strips tatweel', () {
      // كــتاب → كتاب
      expect(TextNormalizer.normalize('كــتاب'), 'كتاب');
    });
  });
}
