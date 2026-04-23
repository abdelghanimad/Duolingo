/// Abstraction over the WebRTC peer connection lifecycle.
///
/// Concrete implementation uses `flutter_webrtc` and is fed STUN
/// `stun:stun.l.google.com:19302` plus an optional self-hosted TURN.
/// Signaling is exchanged over Supabase Realtime — see
/// [`SupabaseService.roomEventsStream`].
///
/// IMPORTANT — single audio source rule:
///   On both platforms the *same* mic capture must feed both this peer
///   connection AND the on-device STT. See `docs/ARCHITECTURE.md` §3 for
///   the iOS (`AVAudioEngine` tap) and Android (`JavaAudioDeviceModule`
///   `setSamplesReadyCallback`) recipes.
library;

import 'dart:async';

enum CallState { idle, connecting, connected, disconnected, failed }

class ConnectionQuality {
  const ConnectionQuality({required this.rttMs, required this.packetLoss});
  final int rttMs;
  final double packetLoss; // 0.0–1.0
}

abstract class WebRtcService {
  Stream<CallState> get state;
  Stream<ConnectionQuality> get quality;

  /// Audio-level (0.0–1.0) of the *remote* stream, sampled ~30 Hz.
  /// The UI waveform binds to this. The matcher is also fed from this
  /// stream — never the local mic — to prevent self-cheating.
  Stream<double> get remoteAudioLevel;

  Future<void> joinRoom({
    required String roomId,
    required String selfId,
    required String signalingChannel,
  });

  Future<void> setMuted(bool muted);
  Future<void> leave();
}
