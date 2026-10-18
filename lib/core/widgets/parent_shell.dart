import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';

/// Bottom navigation for parent mode.
class ParentShell extends StatelessWidget {
  const ParentShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.video_library_rounded),
            selectedIcon: const Icon(Icons.video_library_rounded),
            label: l10n.navPlaylists,
          ),
          NavigationDestination(
            icon: const Icon(Icons.public_rounded),
            selectedIcon: const Icon(Icons.public_rounded),
            label: l10n.navCommunity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
