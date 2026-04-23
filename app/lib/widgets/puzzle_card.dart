import 'package:flutter/material.dart';

/// The central card showing the opponent's puzzle vector.
///
/// We deliberately accept either a network URL or a bundled asset path —
/// per the zero-cost strategy (`docs/ARCHITECTURE.md` §4.4) the most-played
/// puzzles are pre-bundled in `assets/puzzles/`.
class PuzzleCard extends StatelessWidget {
  const PuzzleCard({
    super.key,
    required this.vectorUrl,
    required this.instruction,
  });

  final String vectorUrl;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    final isAsset = !vectorUrl.startsWith('http');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: SizedBox(
              width: 180,
              height: 180,
              child: isAsset
                  ? Image.asset('assets/$vectorUrl',
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined, size: 80))
                  : Image.network(vectorUrl,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined, size: 80)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
