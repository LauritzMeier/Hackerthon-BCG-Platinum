import 'package:flutter/material.dart';

import '../mock/mock_shell.dart';
import 'app_theme.dart';

class LongevityCompassApp extends StatelessWidget {
  const LongevityCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Longevity Compass',
      theme: AppTheme.build(),
      debugShowCheckedModeBanner: false,
      home: const MockCompassShell(),
    );
  }
}
