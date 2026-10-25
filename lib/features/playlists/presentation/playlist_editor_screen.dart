import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/languages.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/playlist.dart';
import 'playlist_dialogs.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';
import 'widgets/age_range_picker.dart';
import 'widgets/label_chips.dart';
import 'widgets/language_picker.dart';

/// Create a playlist, or edit one's title, description, ages and labels.
class PlaylistEditorScreen extends ConsumerWidget {
  const PlaylistEditorScreen({this.playlistId, super.key});

  /// `null` to create a new playlist.
  final String? playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = playlistId;
    if (id == null) return const _EditorForm(initial: null);
    final detail = ref.watch(playlistDetailControllerProvider(id));
    return detail.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: context.l10n.playlistError(e),
          onRetry: () => ref.invalidate(playlistDetailControllerProvider(id)),
        ),
      ),
      data: (d) => _EditorForm(initial: d.playlist),
    );
  }
}

class _EditorForm extends ConsumerStatefulWidget {
  const _EditorForm({required this.initial});

  final Playlist? initial;

  @override
  ConsumerState<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends ConsumerState<_EditorForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late AgeRange _ageRange = widget.initial?.ageRange ?? AgeRange.fallback;
  late List<int> _labelIds = [...?widget.initial?.labelIds];
  late List<String> _languages = [...?widget.initial?.languages];
  late bool _public = widget.initial?.isPublic ?? false;
  bool _saving = false;

  bool get _isNew => widget.initial == null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addLanguage() async {
    final tag = await showLanguageChooser(context, exclude: _languages);
    if (tag == null || !mounted || _languages.contains(tag)) return;
    setState(() => _languages = [..._languages, tag]);
  }

  /// Only playlists with videos can be shared (new ones have none yet).
  bool get _canShare => (widget.initial?.videoCount ?? 0) > 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final missing = !_public
        ? null
        : _labelIds.isEmpty
        ? l10n.playlistErrorNeedsLabel
        : _languages.isEmpty
        ? l10n.playlistErrorNeedsLanguage
        : null;
    if (missing != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(missing)));
      return;
    }
    final draft = PlaylistDraft(
      title: _title.text,
      description: _description.text,
      ageRange: _ageRange,
      labelIds: _labelIds,
      languages: _languages,
      visibility: _public
          ? PlaylistVisibility.public
          : PlaylistVisibility.private,
    );
    setState(() => _saving = true);
    try {
      if (_isNew) {
        final id = await ref.read(myPlaylistsProvider.notifier).create(draft);
        // Straight into the new playlist so the parent can add videos.
        if (mounted) context.pushReplacement(Routes.playlist(id));
      } else {
        await ref
            .read(playlistDetailControllerProvider(widget.initial!.id).notifier)
            .updateDetails(draft);
        if (mounted) context.pop();
      }
    } on Exception catch (e) {
      if (mounted) showPlaylistError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newPlaylist : l10n.editDetails),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: Text(_isNew ? l10n.create : l10n.save),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              autofocus: _isNew,
              enabled: !_saving,
              maxLength: PlaylistDraft.maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.playlistTitleLabel,
                hintText: l10n.playlistTitleHint,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.playlistTitleRequired : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              enabled: !_saving,
              maxLength: PlaylistDraft.maxDescriptionLength,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.playlistDescriptionLabel,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.ageRangeTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            AgeRangePicker(
              value: _ageRange,
              onChanged: (r) => setState(() => _ageRange = r),
            ),
            const SizedBox(height: 24),
            Text(l10n.labelsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.labelsHint(PlaylistDraft.maxLabels),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            LabelPicker(
              selected: _labelIds,
              onChanged: (ids) => setState(() => _labelIds = ids),
            ),
            const SizedBox(height: 24),
            Text(l10n.languagesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.languagesHint(PlaylistDraft.maxLanguages),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _languages)
                  InputChip(
                    key: Key('language-chip-$tag'),
                    label: Text(Language.of(tag).name),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    deleteButtonTooltipMessage: l10n.removeLanguage(
                      Language.of(tag).name,
                    ),
                    onDeleted: _saving
                        ? null
                        : () => setState(
                            () => _languages = [
                              ..._languages.where((t) => t != tag),
                            ],
                          ),
                  ),
                if (_languages.length < PlaylistDraft.maxLanguages)
                  ActionChip(
                    key: const Key('add-language'),
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addLanguage),
                    onPressed: _saving ? null : _addLanguage,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Material(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                key: const Key('share-switch'),
                contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                value: _public,
                onChanged: _saving || (!_canShare && !_public)
                    ? null
                    : (v) => setState(() => _public = v),
                title: Text(l10n.shareWithCommunity),
                subtitle: Text(
                  _canShare || _public
                      ? l10n.shareWithCommunityHint
                      : l10n.shareNeedsVideos,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_isNew ? l10n.createPlaylist : l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}
