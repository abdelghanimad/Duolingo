import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/audio_waveform.dart';
import '../widgets/live_call_status_bar.dart';
import '../widgets/puzzle_card.dart';
import 'result_screen.dart';

/// The heart of the app — all the wiring is here in skeleton form. The
/// concrete WebRTC + STT plumbing is documented in `docs/ARCHITECTURE.md`
/// §3 and lives behind the `WebRtcService` / `SpeechService` interfaces.
class GameRoomScreen extends StatefulWidget {
  const GameRoomScreen({
    super.key,
    required this.nativeLang,
    required this.learningLang,
  });

  final String nativeLang;
  final String learningLang;

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  final DateTime _startedAt = DateTime.now();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  double _remoteLevel = 0;
  bool _muted = false;

  // Demo target word that the matcher would be listening for.
  static const _demoTarget = 'umbrella';

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
        // Fake waveform animation in the scaffold; the production version
        // binds to WebRtcService.remoteAudioLevel.
        _remoteLevel = 0.3 + 0.6 * ((_elapsed.inSeconds % 4) / 4);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _simulateWin() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        won: true,
        targetWord: _demoTarget,
        durationMs: _elapsed.inMilliseconds,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Room'),
        actions: [
          IconButton(
            tooltip: _muted ? 'Unmute' : 'Mute (pauses game)',
            icon: Icon(_muted ? Icons.mic_off : Icons.mic),
            onPressed: () => setState(() => _muted = !_muted),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LiveCallStatusBar(
              opponentName: 'Sara',
              elapsed: _elapsed,
            ),
            const Spacer(),
            const PuzzleCard(
              vectorUrl: 'puzzles/umbrella.svg',
              instruction: 'Describe this picture to your friend',
            ),
            const Spacer(),
            AudioWaveform(level: _remoteLevel),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('💡 Listening for: "$_demoTarget"',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            // Dev-only button to walk the flow without real STT.
            OutlinedButton(
              onPressed: _simulateWin,
              child: const Text('(dev) Simulate win event'),
            ),
          ],
        ),
      ),
    );
  }
}
