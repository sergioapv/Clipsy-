import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'core/config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw immediately; initialisation runs inside StartupApp so a failure is
  // shown on screen instead of leaving the app on the system splash.
  runApp(
    Env.isSupabaseConfigured ? const StartupApp() : const ConfigMissingApp(),
  );
}
