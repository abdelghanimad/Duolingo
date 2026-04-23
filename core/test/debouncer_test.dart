import 'package:test/test.dart';

import 'package:global_guess_live_core/global_guess_live_core.dart';

void main() {
  group('Debouncer', () {
    test('first fire always succeeds', () {
      final d = Debouncer(window: const Duration(milliseconds: 500));
      expect(d.tryFire(), isTrue);
    });

    test('second fire inside the window is suppressed', () {
      var t = DateTime(2025, 1, 1);
      final d = Debouncer(
        window: const Duration(milliseconds: 500),
        clock: () => t,
      );
      expect(d.tryFire(), isTrue);
      t = t.add(const Duration(milliseconds: 200));
      expect(d.tryFire(), isFalse);
    });

    test('fire after the window succeeds again', () {
      var t = DateTime(2025, 1, 1);
      final d = Debouncer(
        window: const Duration(milliseconds: 500),
        clock: () => t,
      );
      expect(d.tryFire(), isTrue);
      t = t.add(const Duration(milliseconds: 600));
      expect(d.tryFire(), isTrue);
    });

    test('reset clears state', () {
      var t = DateTime(2025, 1, 1);
      final d = Debouncer(
        window: const Duration(milliseconds: 500),
        clock: () => t,
      );
      expect(d.tryFire(), isTrue);
      d.reset();
      expect(d.tryFire(), isTrue);
    });
  });
}
