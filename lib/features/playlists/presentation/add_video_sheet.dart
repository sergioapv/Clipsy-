import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../domain/video_metadata.dart';
import '../domain/youtube_url_parser.dart';
import 'import_playlist_sheet.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';
import 'widgets/video_thumbnail.dart';

/// [initialLink] (e.g. shared from the YouTube app) is checked right away.
Future<void> showAddVideoSheet(
  BuildContext context,
  String playlistId, {
  String? initialLink,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) =>
      AddVideoSheet(playlistId: playlistId, initialLink: initialLink),
);

/// Paste a YouTube link → validate with oEmbed → preview → add.
class AddVideoSheet extends ConsumerStatefulWidget {
  const AddVideoSheet({required this.playlistId, this.initialLink, super.key});

  final String playlistId;
  final String? initialLink;

  @override
  ConsumerState<AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends ConsumerState<AddVideoSheet> {
  final _input = TextEditingController();
  bool _busy = false;
  String? _error;
  VideoMetadata? _preview;
  int _added = 0;

  /// Playlist (`list=`) of the checked link, offered as "add whole playlist".
  String? _playlistId;

  @override
  void initState() {
    super.initState();
    final link = widget.initialLink;
    if (link != null) {
      _input.text = link;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_check());
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _input.text = text;
    await _check();
  }

  Future<void> _check() async {
    final l10n = context.l10n;
    final text = _input.text;
    setState(() {
      _error = null;
      _preview = null;
    });
    if (text.trim().isEmpty) return;

    // Opened from outside the playlist's screen (a shared link), the
    // playlist may not be loaded yet.
    try {
      await ref.read(
        playlistDetailControllerProvider(widget.playlistId).future,
      );
    } on Exception catch (e) {
      if (mounted) setState(() => _error = l10n.playlistError(e));
      return;
    }
    if (!mounted) return;
    final controller = ref.read(
      playlistDetailControllerProvider(widget.playlistId).notifier,
    );
    final id = YouTubeUrlParser.extractVideoId(text);
    final listId = YouTubeUrlParser.extractPlaylistId(text);
    setState(() => _playlistId = listId);
    // A playlist link without a video: go straight to the import preview.
    if (id == null && listId != null) {
      await _importPlaylist(listId);
      return;
    }
    if (id != null && controller.contains(id)) {
      setState(() => _error = l10n.videoErrorDuplicate);
      return;
    }

    setState(() => _busy = true);
    try {
      final meta = await ref.read(videoLookupRepositoryProvider).lookup(text);
      if (mounted) setState(() => _preview = meta);
    } on VideoLookupException catch (e) {
      if (mounted) setState(() => _error = l10n.videoLookupError(e.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importPlaylist(String listId) async {
    if (!YouTubeUrlParser.isImportablePlaylist(listId)) {
      setState(() => _error = context.l10n.importErrorUnsupported);
      return;
    }
    final added = await showImportPlaylistSheet(
      context,
      playlistId: widget.playlistId,
      youtubePlaylistId: listId,
    );
    if (!mounted || added == 0) return;
    setState(() {
      _added += added;
      _preview = null;
      _playlistId = null;
      _input.clear();
    });
  }

  Future<void> _add() async {
    final meta = _preview;
    if (meta == null) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref
          .read(playlistDetailControllerProvider(widget.playlistId).notifier)
          .addVideo(meta);
      if (!mounted) return;
      // Stay open so several videos can be added in a row.
      setState(() {
        _added++;
        _preview = null;
        _input.clear();
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = l10n.playlistError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preview = _preview;
    // Keep the playlist loaded while the sheet is open.
    ref.watch(playlistDetailControllerProvider(widget.playlistId));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addVideo, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          const SizedBox(height: 4),
          Text(
            l10n.addVideoHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('browse-youtube'),
            onPressed: _busy
                ? null
                : () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    unawaited(
                      router.push(Routes.browseYouTube(widget.playlistId)),
                    );
                  },
            icon: const Icon(Icons.travel_explore_rounded),
            label: Text(l10n.browseYouTube),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l10n.orPasteLink, style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('video-url-field'),
            controller: _input,
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => unawaited(_check()),
            decoration: InputDecoration(
              labelText: l10n.youtubeLink,
              hintText: 'https://youtu.be/…',
              errorText: _error,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                tooltip: l10n.paste,
                onPressed: _busy ? null : _paste,
                icon: const Icon(Icons.content_paste_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (preview != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    VideoThumbnail(
                      url: preview.thumbnailUrl,
                      width: 120,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (preview.channelName != null)
                            Text(
                              preview.channelName!,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addToPlaylist),
            ),
            if (_playlistId != null)
              TextButton.icon(
                key: const Key('sheet-add-playlist'),
                onPressed: () => unawaited(_importPlaylist(_playlistId!)),
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: Text(l10n.addWholePlaylistInstead),
              ),
          ] else
            FilledButton.tonal(onPressed: _check, child: Text(l10n.checkVideo)),
          if (_added > 0) ...[
            const SizedBox(height: 12),
            Text(
              l10n.videosAdded(_added),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
