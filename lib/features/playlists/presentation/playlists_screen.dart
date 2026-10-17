import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';

/// Parent home. Playlist CRUD arrives in Milestone 2.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navPlaylists)),
      body: EmptyState(
        icon: Icons.video_library_outlined,
        title: l10n.playlistsEmptyTitle,
        message: l10n.playlistsEmptyBody,
      ),
    );
  }
}
