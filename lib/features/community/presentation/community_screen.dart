import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';

/// Community library. Built in Milestone 4.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCommunity)),
      body: EmptyState(
        icon: Icons.public_rounded,
        title: l10n.communityComingTitle,
        message: l10n.communityComingBody,
      ),
    );
  }
}
