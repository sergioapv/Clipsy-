import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/env.dart';
import 'core/storage/secure_session_storage.dart';
import 'core/storage/secure_store.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/clipsy_logo.dart';

/// Everything the app needs before its first real screen.
class BootstrapResult {
  const BootstrapResult({required this.prefs, required this.secureStore});

  final SharedPreferences prefs;
  final SecureStore secureStore;
}

/// A startup step that failed, with the step named so the error on screen
/// is actionable.
class BootstrapException implements Exception {
  const BootstrapException(this.step, this.cause);

  final String step;
  final Object cause;

  @override
  String toString() => '$step: $cause';
}

typedef Bootstrapper = Future<BootstrapResult> Function();

/// Real startup: preferences, then Supabase (which reads the stored session
/// from the keystore). Each step is time-limited so nothing can hang forever.
Future<BootstrapResult> defaultBootstrap() async {
  const timeout = Duration(seconds: 15);
  const secureStore = FlutterSecureStore();

  Future<T> step<T>(String name, Future<T> Function() run) async {
    try {
      return await run().timeout(timeout);
    } on TimeoutException {
      throw BootstrapException(name, 'timed out after ${timeout.inSeconds}s');
    } on Object catch (e) {
      throw BootstrapException(name, e);
    }
  }

  final prefs = await step('Loading settings', SharedPreferences.getInstance);
  await step(
    'Connecting to Supabase',
    () => Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: const SecureSessionStorage(secureStore),
        // Only treat our own callback as an auth redirect; other deep links
        // (e.g. "Share to Clipsy" later) must not be swallowed.
        detectSessionInUriPredicate: (uri) =>
            uri.scheme == AppConfig.authRedirectScheme &&
            uri.host == AppConfig.authRedirectHost,
      ),
    ),
  );
  return BootstrapResult(prefs: prefs, secureStore: secureStore);
}

/// Shows a splash immediately, runs [bootstrap], then hands over to
/// [ClipsyApp]. Failures are shown on screen with a retry instead of leaving
/// the app stuck on the system splash screen.
class StartupApp extends StatefulWidget {
  const StartupApp({this.bootstrap = defaultBootstrap, super.key});

  final Bootstrapper bootstrap;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  BootstrapResult? _result;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      final result = await widget.bootstrap();
      if (mounted) setState(() => _result = result);
    } on Object catch (e, st) {
      debugPrint('Clipsy startup failed: $e\n$st');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return ProviderScope(
        // Screens show errors with a retry button instead of silently retrying.
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(result.prefs),
          secureStoreProvider.overrideWithValue(result.secureStore),
        ],
        child: const ClipsyApp(),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ClipsyLogo(),
                  const SizedBox(height: 32),
                  if (_error == null)
                    const CircularProgressIndicator()
                  else ...[
                    // Not localised: localisation isn't loaded yet, and this
                    // text is mainly for the parent to report the problem.
                    const Text(
                      "Clipsy couldn't start",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      '$_error',
                      key: const Key('startup-error'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _run,
                      child: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the app when the build is missing its Supabase config.
class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Clipsy is missing its Supabase configuration.\n\n'
            'Run with:\nflutter run --dart-define-from-file=.env\n\n'
            'See README.md → Setup.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
