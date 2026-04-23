import 'package:flutter/material.dart';

/// Pulsing red dot + "LIVE" label + elapsed timer + opponent avatar.
/// Matches the top status bar in `docs/ARCHITECTURE.md` §1.3.
class LiveCallStatusBar extends StatefulWidget {
  const LiveCallStatusBar({
    super.key,
    required this.opponentName,
    required this.elapsed,
    this.opponentAvatarUrl,
  });

  final String opponentName;
  final Duration elapsed;
  final String? opponentAvatarUrl;

  @override
  State<LiveCallStatusBar> createState() => _LiveCallStatusBarState();
}

class _LiveCallStatusBarState extends State<LiveCallStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = widget.elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (widget.elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulse,
            child: const Icon(Icons.fiber_manual_record,
                color: Colors.red, size: 14),
          ),
          const SizedBox(width: 6),
          const Text('LIVE',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(width: 12),
          Text('$mm:$ss',
              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
          const Spacer(),
          CircleAvatar(
            radius: 14,
            backgroundImage: widget.opponentAvatarUrl != null
                ? NetworkImage(widget.opponentAvatarUrl!)
                : null,
            child: widget.opponentAvatarUrl == null
                ? Text(widget.opponentName.characters.first)
                : null,
          ),
          const SizedBox(width: 8),
          Text(widget.opponentName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
