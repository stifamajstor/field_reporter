import 'package:flutter/material.dart';

/// Field Reporter Application
///
/// This file will contain:
/// - App configuration
/// - GoRouter routing setup
/// - Theme configuration
/// - Provider scoping
///
/// TODO: Implement in Phase 1
class FieldReporterApp extends StatelessWidget {
  const FieldReporterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder - will be replaced with proper implementation
    return MaterialApp(
      title: 'Field Reporter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Field Reporter - Ready for Phase 1'),
        ),
      ),
    );
  }
}
