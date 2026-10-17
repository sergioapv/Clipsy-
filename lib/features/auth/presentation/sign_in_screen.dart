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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ClipsyLogo(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_sentTo != null)
                    _LinkSent(
                      email: _sentTo!,
                      onUseDifferent: () => setState(() => _sentTo = null),
                    )
                  else ...[
                    Text(
                      l10n.signInParentsOnly,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
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
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (v) =>
                            _emailPattern.hasMatch(v?.trim() ?? '')
                            ? null
                            : l10n.emailInvalid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _sendLink,
                      child: Text(l10n.sendMagicLink),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(l10n.or),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              ref.read(authRepositoryProvider).signInWithGoogle,
                            ),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: Text(l10n.continueWithGoogle),
                    ),
                  ],
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkSent extends StatelessWidget {
  const _LinkSent({required this.email, required this.onUseDifferent});

  final String email;
  final VoidCallback onUseDifferent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(l10n.checkYourEmail, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.magicLinkSent(email), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onUseDifferent,
              child: Text(l10n.useDifferentEmail),
            ),
          ],
        ),
      ),
    );
  }
}
