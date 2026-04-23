import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.won,
    required this.targetWord,
    required this.durationMs,
  });

  final bool won;
  final String targetWord;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 96,
                color: won ? AppTheme.winGold : AppTheme.softRed,
              ),
              const SizedBox(height: 16),
              Text(
                won ? 'You won!' : 'Better luck next time',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Word', style: Theme.of(context).textTheme.labelMedium),
                      Text(targetWord,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Divider(height: 24),
                      Text('${(durationMs / 1000).toStringAsFixed(1)} s',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
                child: const Text('Play again'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
