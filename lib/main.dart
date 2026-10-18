import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'core/config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicences);
  // Draw immediately; initialisation runs inside StartupApp so a failure is
  // shown on screen instead of leaving the app on the system splash.
  runApp(
    Env.isSupabaseConfigured ? const StartupApp() : const ConfigMissingApp(),
  );
}

/// The bundled typefaces' licences, for the licences page.
Stream<LicenseEntry> _fontLicences() async* {
  for (final (family, file) in [
    ('League Spartan', 'LeagueSpartan-OFL.txt'),
    ('Figtree', 'Figtree-OFL.txt'),
  ]) {
    final text = await rootBundle.loadString('assets/fonts/$file');
    yield LicenseEntryWithLineBreaks([family], text);
  }
}
