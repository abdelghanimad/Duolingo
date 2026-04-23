import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const GlobalGuessLiveApp());

class GlobalGuessLiveApp extends StatelessWidget {
  const GlobalGuessLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Global Guess Live',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // The framework auto-flips the layout for RTL locales (Arabic, Hebrew…)
      // because Material widgets read `Directionality` from the locale.
      home: const OnboardingScreen(),
    );
  }
}
