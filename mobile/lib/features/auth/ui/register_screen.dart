import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_error.dart';
import '../../../core/config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_text_field.dart';
import '../auth_controller.dart';
import 'auth_layout.dart';

/// [Sprint 15 F3] Sign up as on the web (UP5): the name, the username and the password, the email optional, and the
/// terms accepted; the account is signed in on this phone at once.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _terms = false;
  bool _busy = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_name, _username, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = L.of(context);
    setState(() => _errors = {
          if (_name.text.trim().length < 2) 'name': l.required,
          if (_username.text.trim().isEmpty) 'username': l.required,
          if (_password.text.length < 8) 'password': l.passwordHint,
        });
    if (_errors.isNotEmpty) return;
    if (!_terms) {
      showGlmToast(context, l.mustAcceptTerms, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).register(name: _name.text, username: _username.text, email: _email.text, password: _password.text);
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
      title: l.registerTitle,
      lead: l.registerLead,
      tab: AuthTab.register,
      children: [
        GlmTextField(label: l.displayName, controller: _name, autofill: const [AutofillHints.nickname], error: _errors['name']),
        const SizedBox(height: 14),
        GlmTextField(label: l.username, controller: _username, ltr: true, hint: l.usernameHint, autofill: const [AutofillHints.newUsername], error: _errors['username']),
        const SizedBox(height: 14),
        GlmTextField(label: l.emailOptional, controller: _email, ltr: true, keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email], error: _errors['email']),
        const SizedBox(height: 14),
        GlmTextField(label: l.password, controller: _password, password: true, hint: l.passwordHint, autofill: const [AutofillHints.newPassword],
            action: TextInputAction.done, onSubmitted: (_) => _submit(), error: _errors['password']),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: p.brand,
          title: Text(l.acceptTerms, style: const TextStyle(fontSize: 14)),
          subtitle: GestureDetector(
            onTap: () => launchUrl(Uri.parse('${AppConfig.siteUrl}/terms'), mode: LaunchMode.externalApplication),
            child: Text(l.termsAndPrivacy, style: TextStyle(color: context.glm.goldText, decoration: TextDecoration.underline, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 8),
        GlmButton(label: l.register, block: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}
