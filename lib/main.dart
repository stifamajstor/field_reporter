import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize services in Phase 1
  // - Local database (Drift)
  // - Secure storage
  // - Connectivity monitoring

  runApp(
    const ProviderScope(
      child: FieldReporterApp(),
    ),
  );
}
