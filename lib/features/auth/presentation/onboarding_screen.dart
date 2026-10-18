import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/clipsy_logo.dart';
import 'auth_providers.dart';

/// Explains Kid mode and how to lock the device on this platform.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _pages(AppLocalizations l10n) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return [
      _OnboardingPage(
        hero: const ClipsyMark(size: 80),
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
      ),
      _OnboardingPage(
        hero: const _HeroIcon(Icons.child_care_rounded),
        title: l10n.onboardingKidModeTitle,
        body: l10n.onboardingKidModeBody,
        bullets: [
          l10n.onboardingKidModeStep1,
          l10n.onboardingKidModeStep2,
          l10n.onboardingKidModeStep3,
        ],
      ),
      if (isIOS)
        _OnboardingPage(
          hero: const _HeroIcon(Icons.accessibility_new_rounded),
          title: l10n.onboardingGuidedAccessTitle,
          body: l10n.onboardingGuidedAccessBody,
          bullets: [
            l10n.onboardingGuidedAccessStep1,
            l10n.onboardingGuidedAccessStep2,
            l10n.onboardingGuidedAccessStep3,
          ],
        )
      else
        _OnboardingPage(
          hero: const _HeroIcon(Icons.push_pin_rounded),
          title: l10n.onboardingPinningTitle,
          body: l10n.onboardingPinningBody,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _pages(l10n);
    final isLast = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Visibility.maintain(
                visible: !isLast,
                child: TextButton(onPressed: _finish, child: Text(l10n.skip)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            Semantics(
              label: l10n.onboardingPageOf(_page + 1, pages.length),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLast
                      ? _finish
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                  child: Text(isLast ? l10n.getStarted : l10n.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() =>
      ref.read(onboardingStatusProvider.notifier).complete();
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      child: SizedBox.square(
        dimension: 80,
        child: Icon(icon, size: 38, color: scheme.onSurface),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.hero,
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final Widget hero;
  final String title;
  final String body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hero,
          const SizedBox(height: 36),
          Text(title, style: theme.textTheme.headlineLarge),
          const SizedBox(height: 14),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 24),
            for (final (i, b) in bullets.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${i + 1}',
                        style: AppFonts.heading(
                          26,
                          theme.colorScheme.primary,
                        ).copyWith(height: 1),
                      ),
                    ),
                    Expanded(child: Text(b, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
