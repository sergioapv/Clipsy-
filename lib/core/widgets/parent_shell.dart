import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/playlists/presentation/playlist_providers.dart';
import '../../features/playlists/presentation/share_intake_sheet.dart';
import '../l10n/l10n.dart';

/// Bottom navigation for parent mode. Also where links shared to Clipsy are
/// handled: this shell only exists once parent mode is unlocked.
class ParentShell extends ConsumerStatefulWidget {
  const ParentShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends ConsumerState<ParentShell> {
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    // A link shared while parent mode was locked (or that launched the app).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingShareProvider);
      if (pending != null) unawaited(_handle(pending));
    });
  }

  Future<void> _handle(String text) async {
    if (_handling) return;
    _handling = true;
    try {
      await handleSharedLink(context, ref, text);
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingShareProvider, (_, next) {
      if (next != null) unawaited(_handle(next));
    });
    final shell = widget.shell;
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
