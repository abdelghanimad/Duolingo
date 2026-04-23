import 'dart:async';

import 'package:test/test.dart';

import 'package:global_guess_live_core/global_guess_live_core.dart';

PuzzleTranslation _t({
  String target = 'umbrella',
  List<String> synonyms = const ['parasol', 'brolly'],
}) =>
    PuzzleTranslation(
      puzzleId: 'p1',
      langCode: 'en',
      targetWord: target,
      acceptedSynonyms: synonyms,
    );

void main() {
  group('WinDetector', () {
    test('emits exactly one event when the target word is heard', () async {
      final detector = WinDetector(translation: _t());
      final partials = Stream.fromIterable(const [
        PartialTranscript(text: 'hmm', isFinal: false),
        PartialTranscript(text: 'maybe an umbrella', isFinal: false),
      ]);

      final events = await detector.bind(partials).toList();
      expect(events, hasLength(1));
      expect(events.single.detected, 'umbrella');
      expect(events.single.distance, 0);
    });

    test('does not emit for unrelated speech', () async {
      final detector = WinDetector(translation: _t());
      final partials = Stream.fromIterable(const [
        PartialTranscript(text: 'the sky is blue', isFinal: true),
      ]);

      final events = await detector.bind(partials).toList();
      expect(events, isEmpty);
    });

    test('debounces duplicate firings within the window', () async {
      var t = DateTime(2025, 1, 1);
      final detector = WinDetector(
        translation: _t(),
        debounce: const Duration(milliseconds: 500),
        clock: () => t,
      );

      final controller = StreamController<PartialTranscript>();
      final out = detector.bind(controller.stream);
      final received = <WinDetected>[];
      final sub = out.listen(received.add);

      controller.add(const PartialTranscript(text: 'umbrella', isFinal: false));
      await Future<void>.delayed(Duration.zero);

      // Same utterance fires again 200 ms later — must be suppressed.
      t = t.add(const Duration(milliseconds: 200));
      controller.add(const PartialTranscript(text: 'umbrella!', isFinal: true));
      await Future<void>.delayed(Duration.zero);

      // 600 ms later — past the window — fires again.
      t = t.add(const Duration(milliseconds: 600));
      controller.add(const PartialTranscript(text: 'umbrella again', isFinal: true));
      await Future<void>.delayed(Duration.zero);

      await controller.close();
      await sub.cancel();

      expect(received, hasLength(2));
    });

    test('matches against synonyms', () async {
      final detector = WinDetector(translation: _t());
      final partials = Stream.fromIterable(const [
        PartialTranscript(text: 'looks like a parasol to me', isFinal: true),
      ]);
      final events = await detector.bind(partials).toList();
      expect(events, hasLength(1));
      expect(events.single.detected, 'parasol');
    });

    test('Arabic: matches across diacritics', () async {
      final detector = WinDetector(
        translation: _t(target: 'مظله', synonyms: const []),
      );
      final partials = Stream.fromIterable(const [
        PartialTranscript(text: 'أعتقد أنها مَظَلَّة', isFinal: true),
      ]);
      final events = await detector.bind(partials).toList();
      expect(events, hasLength(1));
    });
  });
}
