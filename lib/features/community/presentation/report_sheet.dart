import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/community_playlist.dart';

/// Asks why the playlist is being reported. Resolves to the reason and
/// optional details, or `null` if cancelled.
Future<({ReportReason reason, String details})?> showReportSheet(
  BuildContext context,
) => showModalBottomSheet<({ReportReason reason, String details})>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => const _ReportSheet(),
);

extension ReportReasonL10n on AppLocalizations {
  String reportReason(ReportReason r) => switch (r) {
    ReportReason.inappropriate => reportReasonInappropriate,
    ReportReason.violentOrScary => reportReasonViolent,
    ReportReason.notForKids => reportReasonNotForKids,
    ReportReason.misleading => reportReasonMisleading,
    ReportReason.spam => reportReasonSpam,
    ReportReason.other => reportReasonOther,
  };
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SingleChildScrollView(
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
          Text(l10n.reportTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            l10n.reportBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          for (final r in ReportReason.values)
            ListTile(
              key: Key('report-reason-${r.name}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(l10n.reportReason(r)),
              selected: r == _reason,
              trailing: r == _reason
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () => setState(() => _reason = r),
            ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('report-details'),
            controller: _details,
            maxLength: 500,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.reportDetails),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('report-send'),
            onPressed: _reason == null
                ? null
                : () => Navigator.pop(context, (
                    reason: _reason!,
                    details: _details.text,
                  )),
            child: Text(l10n.reportSend),
          ),
        ],
      ),
    );
  }
}
