import 'package:flutter/material.dart';

import 'lobby_screen.dart';

/// Minimal onboarding: native language → learning language → level.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _langs = {
    'en': 'English',
    'ar': 'العربية',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  String _native = 'en';
  String _learning = 'es';
  int _level = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text('I speak…', style: Theme.of(context).textTheme.titleMedium),
            DropdownButton<String>(
              isExpanded: true,
              value: _native,
              items: _langs.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _native = v!),
            ),
            const SizedBox(height: 24),
            Text('I want to learn…',
                style: Theme.of(context).textTheme.titleMedium),
            DropdownButton<String>(
              isExpanded: true,
              value: _learning,
              items: _langs.entries
                  .where((e) => e.key != _native)
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _learning = v!),
            ),
            const SizedBox(height: 24),
            Text('Level: $_level',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _level.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_level',
              onChanged: (v) => setState(() => _level = v.toInt()),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LobbyScreen(
                      nativeLang: _native,
                      learningLang: _learning,
                    ),
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
