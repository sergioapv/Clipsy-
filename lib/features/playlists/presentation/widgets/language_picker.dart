import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/languages.dart';

/// What the filter picker returns: [filter] is `null` for "any language".
/// The sheet itself resolves to `null` when dismissed.
class LanguagePick {
  const LanguagePick(this.filter);

  final LanguageFilter? filter;
}

/// Picks a language to filter by. With [available], only those tags (and
/// their languages, as "all variants") are offered; otherwise the whole
/// catalogue.
Future<LanguagePick?> showLanguageFilterPicker(
  BuildContext context, {
  LanguageFilter? current,
  Iterable<String>? available,
}) => showModalBottomSheet<LanguagePick>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _LanguageSheet(
    filtering: true,
    current: current?.tag,
    available: available?.toSet(),
  ),
);

/// Picks one language to add to a playlist (anything in the catalogue, or a
/// valid tag typed in). [exclude] are the ones it already has.
Future<String?> showLanguageChooser(
  BuildContext context, {
  Iterable<String> exclude = const [],
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _LanguageSheet(filtering: false, exclude: exclude.toSet()),
);

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({
    required this.filtering,
    this.current,
    this.available,
    this.exclude = const {},
  });

  final bool filtering;
  final String? current;
  final Set<String>? available;
  final Set<String> exclude;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The catalogue (or what's [available], plus each available tag's
  /// language so "all variants" can be picked), matching the search.
  List<Language> _options() {
    final available = widget.available;
    if (available == null) {
      return [
        for (final l in Language.search(_query))
          if (!widget.exclude.contains(l.tag)) l,
      ];
    }
    final tags = {...available, for (final t in available) Language.baseOf(t)};
    String order(Language l) =>
        '${Language.of(l.base).name}\u0000${l.isVariant ? 1 : 0}${l.name}';
    return [
      for (final t in tags)
        if (Language.of(t).matches(_query)) Language.of(t),
    ]..sort((a, b) => order(a).compareTo(order(b)));
  }

  /// Languages that have variants listed, so the bare entry means "any".
  bool _hasVariants(Language l) =>
      !l.isVariant &&
      (widget.available ?? Language.all.map((x) => x.tag)).any(
        (t) => t.startsWith('${l.tag}-'),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final options = _options();
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                widget.filtering ? l10n.languageFilter : l10n.addLanguage,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const Key('language-search'),
                controller: _search,
                autocorrect: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.languageSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                children: [
                  if (widget.filtering && _query.trim().isEmpty)
                    _tile(
                      key: 'language-any',
                      title: l10n.languageAny,
                      selected: widget.current == null,
                      onTap: () =>
                          Navigator.pop(context, const LanguagePick(null)),
                    ),
                  for (final l in options)
                    _tile(
                      key: 'language-${l.tag}',
                      title: l.name,
                      subtitle: widget.filtering && _hasVariants(l)
                          ? l10n.languageAllVariants
                          : l.tag,
                      indent: l.isVariant && _query.trim().isEmpty,
                      selected: widget.current == l.tag,
                      onTap: () => Navigator.pop(
                        context,
                        widget.filtering
                            ? LanguagePick(LanguageFilter(l.tag))
                            : l.tag,
                      ),
                    ),
                  if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.languageNoMatch,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required String key,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    bool indent = false,
    bool selected = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key(key),
      contentPadding: EdgeInsets.only(left: indent ? 36 : 16, right: 16),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check_rounded, color: scheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

/// "Português (Portugal)", or "Português (Portugal), English (UK)", or
/// "Português (Portugal) +2" for a compact line.
String languagesLabel(List<String> tags, {int show = 2}) {
  if (tags.isEmpty) return '';
  final names = [for (final t in tags) Language.of(t).name];
  if (names.length <= show) return names.join(', ');
  return '${names.take(show - 1).join(', ')} +${names.length - show + 1}';
}

/// "Language: any" or the chosen language, opening the picker.
class LanguageFilterChip extends StatelessWidget {
  const LanguageFilterChip({
    required this.filter,
    required this.onPressed,
    required this.onClear,
    super.key,
  });

  final LanguageFilter? filter;
  final VoidCallback onPressed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = filter;
    return InputChip(
      avatar: const Icon(Icons.translate_rounded, size: 18),
      label: Text(
        f == null
            ? '${l10n.languageFilter}: ${l10n.languageAny}'
            : Language.of(f.tag).name,
      ),
      selected: f != null,
      showCheckmark: false,
      onPressed: onPressed,
      onDeleted: f == null ? null : onClear,
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
    );
  }
}
