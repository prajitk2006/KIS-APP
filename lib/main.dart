import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/setup_screen.dart';

void main() {
  runApp(const KisApp());
}

class KisApp extends StatelessWidget {
  const KisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KIS - Keep It Simple',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
