import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_text_field.dart';
import '../auth_controller.dart';
import 'auth_layout.dart';

/// [Sprint 15 F3] Sign in with the email or the username and the password (the API's `/auth/token`). Google comes
/// when the app's Google client is set (README section 11).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = L.of(context);
    setState(() => _errors = {
          if (_login.text.trim().isEmpty) 'email': l.required,
          if (_password.text.isEmpty) 'password': l.required,
        });
    if (_errors.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).signIn(_login.text, _password.text);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fields);
      if (e.fields.isEmpty) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return AuthLayout(
      title: l.signInTitle,
      lead: l.signInLead,
      tab: AuthTab.signIn,
      // [Sprint 47] The approved design: the form first, the gold button, then Google under «or».
      children: [
        GlmTextField(label: l.emailOrUsername, controller: _login, ltr: true, hint: 'you@example.com', keyboard: TextInputType.emailAddress,
            autofill: const [AutofillHints.username, AutofillHints.email], error: _errors['email']),
        const SizedBox(height: 14),
        GlmTextField(label: l.password, controller: _password, password: true, autofill: const [AutofillHints.password], action: TextInputAction.done,
            onSubmitted: (_) => _submit(), error: _errors['password']),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: () => context.push('/forgot'), child: Text(l.forgotPassword, style: TextStyle(color: context.glm.brandText, fontWeight: FontWeight.w700))),
        ),
        GlmButton(label: l.signIn, block: true, loading: _busy, onPressed: _submit),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            Expanded(child: Divider(color: p.surfaceRaised)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(l.orWord, style: TextStyle(color: p.textMuted, fontSize: 13))),
            Expanded(child: Divider(color: p.surfaceRaised)),
          ]),
        ),
        GlmButton(label: l.google, variant: GlmButtonVariant.outline, block: true, icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            onPressed: () => showGlmToast(context, l.googleSoon)),
      ],
    );
  }
}
