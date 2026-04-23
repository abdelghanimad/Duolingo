/// Interface for the on-device speech recognizer.
///
/// Concrete implementations:
///   * `speech_to_text` plugin → wraps SFSpeechRecognizer (iOS) and
///     Android's `SpeechRecognizer` with `EXTRA_PREFER_OFFLINE = true`.
///   * Vosk (TODO) — fallback for languages without OS support.
///
/// All implementations MUST honour:
///   * `requiresOnDeviceRecognition = true` (privacy + zero cost),
///   * continuous listening (no push-to-talk),
///   * partial results streamed as they arrive (~100 ms cadence),
///   * automatic restart on Android 30 s timeout.
library;

import 'dart:async';

class PartialTranscript {
  const PartialTranscript({required this.text, required this.isFinal});
  final String text;
  final bool isFinal;
}

abstract class SpeechService {
  /// Asks the OS for microphone + speech-recognition permission.
  Future<bool> requestPermissions();

  /// Starts continuous, on-device recognition for [langCode] (BCP-47 short
  /// form, e.g. `en`, `ar`, `es`). Returns a stream of partial transcripts.
  ///
  /// On platforms where the underlying API has a hard timeout (Android 12+),
  /// the implementation is expected to transparently restart recognition
  /// while the stream subscription is alive.
  Stream<PartialTranscript> start(String langCode);

  Future<void> stop();
}
