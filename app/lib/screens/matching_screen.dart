import 'package:flutter/material.dart';

import 'game_room_screen.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({
    super.key,
    required this.nativeLang,
    required this.learningLang,
  });

  final String nativeLang;
  final String learningLang;

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // In a real build, this is where SupabaseService.findOrCreateRoom(...)
    // would be awaited. For the scaffold we go straight to the GameRoom
    // after a short delay so the flow is demoable end-to-end.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameRoomScreen(
          nativeLang: widget.nativeLang,
          learningLang: widget.learningLang,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spin,
              child: const Icon(Icons.public, size: 96),
            ),
            const SizedBox(height: 24),
            const Text('Searching for a partner…',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
