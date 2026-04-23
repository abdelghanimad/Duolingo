/// Lightweight, time-source-injectable debouncer used by the win-detector
/// to prevent duplicate `word_detected` events for the same utterance.
///
/// Pure Dart, no Flutter / Timer dependency, easy to unit-test.
library;

class Debouncer {
  Debouncer({required this.window, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Duration window;
  final DateTime Function() _clock;
  DateTime? _lastFire;

  /// Returns `true` if the caller should fire the event now, `false` if it
  /// was suppressed because it falls inside the debounce [window] of the
  /// previous fire.
  bool tryFire() {
    final now = _clock();
    if (_lastFire == null || now.difference(_lastFire!) >= window) {
      _lastFire = now;
      return true;
    }
    return false;
  }

  void reset() => _lastFire = null;
}
