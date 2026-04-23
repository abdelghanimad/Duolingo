import 'package:flutter/material.dart';

import 'matching_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.nativeLang,
    required this.learningLang,
  });

  final String nativeLang;
  final String learningLang;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Guess Live')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Native: $nativeLang  •  Learning: $learningLang',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Streak: 0  •  XP: 0  •  Level 1'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.public),
              label: const Text('Find a Partner'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MatchingScreen(
                    nativeLang: nativeLang,
                    learningLang: learningLang,
                  ),
                ));
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.group_outlined),
              label: const Text('Friends (coming soon)'),
              onPressed: null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
