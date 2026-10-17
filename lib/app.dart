import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';

class ClipsyApp extends ConsumerStatefulWidget {
  const ClipsyApp({super.key});

  @override
  ConsumerState<ClipsyApp> createState() => _ClipsyAppState();
}

class _ClipsyAppState extends ConsumerState<ClipsyApp> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _hiddenAt;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt = DateTime.now(),
      onShow: _maybeRelock,
    );
  }

  /// Relock parent mode after a while in the background, so handing the
  /// device to a child later doesn't leave parent mode open.
  void _maybeRelock() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt != null &&
        DateTime.now().difference(hiddenAt) > AppConfig.parentRelockAfter) {
      ref.read(parentSessionProvider.notifier).lock();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
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
