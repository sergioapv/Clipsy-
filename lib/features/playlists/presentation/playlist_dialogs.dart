import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/playlist.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';

void showPlaylistError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.l10n.playlistError(error))));
}

/// Asks before deleting; returns whether the playlist was deleted.
Future<bool> confirmDeletePlaylist(
  BuildContext context,
  WidgetRef ref,
  Playlist playlist,
) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deletePlaylistTitle(playlist.title)),
      content: Text(l10n.deletePlaylistBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (!(ok ?? false)) return false;
  try {
    await ref.read(myPlaylistsProvider.notifier).delete(playlist.id);
    return true;
  } on Exception catch (e) {
    if (context.mounted) showPlaylistError(context, e);
    return false;
  }
}
