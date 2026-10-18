import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/clipsy_logo.dart';
import 'auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _sentTo;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Exception catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      final message = switch (e) {
        SocketException() => l10n.errorNetwork,
        AuthException(statusCode: '429') => l10n.signInRateLimited,
        _ => l10n.signInFailed,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    await _run(() async {
      await ref.read(authRepositoryProvider).sendMagicLink(email);
      if (mounted) setState(() => _sentTo = email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ClipsyLogo(size: 56, showWordmark: false),
                  ),
                  const SizedBox(height: 28),
                  Text(l10n.tagline, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(
                    l10n.signInParentsOnly,
                    style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 36),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _sentTo != null
                        ? _LinkSent(
                            email: _sentTo!,
                            onUseDifferent: () =>
                                setState(() => _sentTo = null),
                          )
                        : _form(l10n, muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AppLocalizations l10n, Color muted) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Form(
        key: _formKey,
        child: TextFormField(
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (_) => unawaited(_sendLink()),
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
          validator: (v) => _emailPattern.hasMatch(v?.trim() ?? '')
              ? null
              : l10n.emailInvalid,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _busy ? null : _sendLink,
        child: _busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(l10n.sendMagicLink),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(l10n.or, style: TextStyle(color: muted)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => _run(ref.read(authRepositoryProvider).signInWithGoogle),
        icon: const Icon(Icons.account_circle_rounded),
        label: Text(l10n.continueWithGoogle),
      ),
    ],
  );
}

class _LinkSent extends StatelessWidget {
  const _LinkSent({required this.email, required this.onUseDifferent});

  final String email;
  final VoidCallback onUseDifferent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(l10n.checkYourEmail, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.magicLinkSent(email), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: onUseDifferent,
            child: Text(l10n.useDifferentEmail),
          ),
        ],
      ),
    );
  }
}
