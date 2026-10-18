import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/pin_setup_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/unlock_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/kid_mode/presentation/kid_mode_screen.dart';
import '../../features/playlists/presentation/playlist_detail_screen.dart';
import '../../features/playlists/presentation/playlist_editor_screen.dart';
import '../../features/playlists/presentation/playlists_screen.dart';
import '../../features/playlists/presentation/youtube_browser_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/parent_shell.dart';
import 'app_gate.dart';
import 'redirect.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// The app's top-level navigator, for routes shown above the parent shell.
final rootNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final gate = ValueNotifier<AppGate>(ref.read(appGateProvider));
  ref.listen(appGateProvider, (_, next) => gate.value = next);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: gate,
    redirect: (context, state) => redirectFor(gate.value, state.uri),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.pinSetup,
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.unlock,
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: Routes.kid,
        builder: (context, state) => const KidModeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ParentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.playlists,
                builder: (context, state) => const PlaylistsScreen(),
                routes: [
                  // Before ':id' so "new" isn't read as an id.
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PlaylistEditorScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PlaylistDetailScreen(
                      playlistId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => PlaylistEditorScreen(
                          playlistId: state.pathParameters['id'],
                        ),
                      ),
                      GoRoute(
                        path: 'browse',
                        // Full screen, above the bottom navigation.
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => YouTubeBrowserScreen(
                          playlistId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.community,
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'pin',
                    builder: (context, state) =>
                        const PinSetupScreen(isChange: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
}
