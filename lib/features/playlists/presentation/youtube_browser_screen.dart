import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/languages.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/in_app_browser.dart';
import '../domain/video_metadata.dart';
import '../domain/youtube_browse_policy.dart';
import '../domain/youtube_url_parser.dart';
import 'import_playlist_sheet.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';
import 'widgets/language_picker.dart';

/// Parent-mode YouTube browser for finding videos. On any video page an
/// "Add to playlist" button adds it (after the usual oEmbed checks) without
/// leaving the browser. Never available in Kid mode.
class YouTubeBrowserScreen extends ConsumerStatefulWidget {
  const YouTubeBrowserScreen({required this.playlistId, super.key});

  final String playlistId;

  @override
  ConsumerState<YouTubeBrowserScreen> createState() =>
      _YouTubeBrowserScreenState();
}

enum _AddState { idle, adding }

class _YouTubeBrowserScreenState extends ConsumerState<YouTubeBrowserScreen> {
  late final ProviderSubscription<InAppBrowser> _browserSub;
  late final InAppBrowser _browser;
  var _addState = _AddState.idle;

  /// The language YouTube is set to (BCP 47), or `null` for the app's.
  String? _language;

  static const _languageKey = 'browser.language';

  @override
  void initState() {
    super.initState();
    // Holding the subscription keeps the auto-dispose browser alive.
    _browserSub = ref.listenManual(inAppBrowserProvider, (_, _) {});
    _browser = _browserSub.read();
    unawaited(_start());
  }

  /// Opens YouTube in the playlist's language, or the last one picked here.
  Future<void> _start() async {
    String? language;
    try {
      final detail = await ref.read(
        playlistDetailControllerProvider(widget.playlistId).future,
      );
      language = detail.playlist.languages.firstOrNull;
    } on Exception {
      // Browse anyway; adding will show the error.
    }
    language ??= ref.read(sharedPreferencesProvider).getString(_languageKey);
    if (!mounted) return;
    setState(() => _language = language);
    await _browser.load(_home());
  }

  Uri _home() => YouTubeBrowsePolicy.homeFor(
    _language,
    fallbackHl: Localizations.localeOf(context).languageCode,
  );

  Future<void> _pickLanguage() async {
    final language = _language;
    final pick = await showLanguageFilterPicker(
      context,
      current: language == null ? null : LanguageFilter(language),
    );
    if (pick == null || !mounted) return;
    final tag = pick.filter?.tag;
    final prefs = ref.read(sharedPreferencesProvider);
    await (tag == null
        ? prefs.remove(_languageKey)
        : prefs.setString(_languageKey, tag));
    if (!mounted) return;
    setState(() => _language = tag);
    await _browser.load(_home());
  }

  @override
  void dispose() {
    _browserSub.close();
    super.dispose();
  }

  Future<void> _back() async {
    if (await _browser.canGoBack()) {
      await _browser.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _add(Uri pageUrl) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    void show(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    setState(() => _addState = _AddState.adding);
    try {
      final meta = await ref
          .read(videoLookupRepositoryProvider)
          .lookup(pageUrl.toString());
      await ref
          .read(playlistDetailControllerProvider(widget.playlistId).notifier)
          .addVideo(meta);
      show(l10n.videoAddedNamed(meta.title));
    } on VideoLookupException catch (e) {
      show(l10n.videoLookupError(e.error));
    } on Exception catch (e) {
      show(l10n.playlistError(e));
    } finally {
      if (mounted) setState(() => _addState = _AddState.idle);
    }
  }

  Future<void> _importPlaylist(String listId) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final added = await showImportPlaylistSheet(
      context,
      playlistId: widget.playlistId,
      youtubePlaylistId: listId,
    );
    if (added > 0) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.videosAdded(added))));
    }
  }

  Widget _videoButton(String id, Uri url, String? playlistTitle) {
    final l10n = context.l10n;
    final added = ref
        .read(playlistDetailControllerProvider(widget.playlistId).notifier)
        .contains(id);
    if (added) {
      return FloatingActionButton.extended(
        key: const Key('browser-added'),
        heroTag: 'browser-video',
        onPressed: null,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        icon: const Icon(Icons.check_rounded),
        label: Text(l10n.inPlaylist),
      );
    }
    return FloatingActionButton.extended(
      key: const Key('browser-add'),
      heroTag: 'browser-video',
      onPressed: _addState == _AddState.adding
          ? null
          : () => unawaited(_add(url)),
      icon: _addState == _AddState.adding
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.playlist_add_rounded),
      label: Text(
        playlistTitle == null
            ? l10n.addToPlaylist
            : l10n.addToNamedPlaylist(playlistTitle),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Keep the playlist loaded so "already added" is known.
    final detail = ref.watch(
      playlistDetailControllerProvider(widget.playlistId),
    );
    final playlistTitle = detail.value?.playlist.title;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.close,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(l10n.browseYouTube),
          actions: [
            TextButton.icon(
              key: const Key('browser-language'),
              onPressed: () => unawaited(_pickLanguage()),
              icon: const Icon(Icons.translate_rounded, size: 20),
              label: Text(
                _language ?? l10n.languageAny,
                semanticsLabel: _language == null
                    ? '${l10n.languageFilter}: ${l10n.languageAny}'
                    : '${l10n.languageFilter}: '
                          '${Language.of(_language!).name}',
              ),
            ),
            IconButton(
              tooltip: l10n.back,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => unawaited(_back()),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: ValueListenableBuilder<int>(
              valueListenable: _browser.progress,
              builder: (context, p, _) => p >= 100
                  ? const SizedBox(height: 3)
                  : LinearProgressIndicator(value: p / 100, minHeight: 3),
            ),
          ),
        ),
        body: _browser.buildView(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: ValueListenableBuilder<Uri?>(
          valueListenable: _browser.url,
          builder: (context, url, _) {
            if (url == null || detail.value == null) {
              return const SizedBox.shrink();
            }
            final text = url.toString();
            final videoId = YouTubeUrlParser.extractVideoId(text);
            final listId = YouTubeUrlParser.extractPlaylistId(text);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (listId != null &&
                    YouTubeUrlParser.isImportablePlaylist(listId)) ...[
                  FloatingActionButton.extended(
                    key: const Key('browser-add-playlist'),
                    heroTag: 'browser-add-playlist',
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                    onPressed: () => unawaited(_importPlaylist(listId)),
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: Text(l10n.addWholePlaylist),
                  ),
                  if (videoId != null) const SizedBox(height: 12),
                ],
                if (videoId != null) _videoButton(videoId, url, playlistTitle),
              ],
            );
          },
        ),
      ),
    );
  }
}
