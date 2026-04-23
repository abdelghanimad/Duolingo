/// Glues a [SpeechService] partial-transcript stream to the [FuzzyMatcher]
/// and emits a single `WinDetected` event the first time the target is
/// recognized inside the debounce window.
///
/// Pure Dart — no Flutter, no plugins — so it can be unit-tested with
/// synthetic streams.
library;

import 'dart:async';

import '../models/puzzle.dart';
import '../utils/debouncer.dart';
import '../utils/fuzzy_matcher.dart';
import 'speech_service.dart';

class WinDetected {
  const WinDetected({required this.detected, required this.distance});
  final String detected;
  final int distance;
}

class WinDetector {
  WinDetector({
    required this.translation,
    Duration debounce = const Duration(milliseconds: 500),
    this.maxDistance = 1,
    DateTime Function()? clock,
  }) : _debouncer = Debouncer(window: debounce, clock: clock);

  final PuzzleTranslation translation;
  final int maxDistance;
  final Debouncer _debouncer;

  MatchResult _match(String utterance) => FuzzyMatcher.bestMatch(
        utterance,
        translation.allAcceptedForms,
        maxDistance: maxDistance,
      );

  /// Bind to a [SpeechService] stream. The returned stream emits at most
  /// once per debounce window, and at most once per call to [bind] before
  /// the caller cancels its subscription.
  Stream<WinDetected> bind(Stream<PartialTranscript> partials) {
    final controller = StreamController<WinDetected>();
    StreamSubscription<PartialTranscript>? sub;

    sub = partials.listen((p) {
      final m = _match(p.text);
      if (!m.matched) return;
      if (!_debouncer.tryFire()) return;
      controller.add(WinDetected(detected: m.candidate, distance: m.distance));
    }, onError: controller.addError, onDone: () async {
      await sub?.cancel();
      await controller.close();
    });

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
  }
}
