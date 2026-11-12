import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_text_field.dart';
import '../auth_repository.dart';
import 'auth_layout.dart';

/// [Sprint 15 F3] The password link by email (the web's page opens it to choose a new one).
class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});

  @override
  ConsumerState<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends ConsumerState<ForgotScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = L.of(context);
    if (_email.text.trim().isEmpty) return setState(() => _error = l.required);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgot(_email.text);
      if (mounted) showGlmToast(context, l.linkSent);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.fields['email'] ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AuthLayout(
      title: l.forgotTitle,
      lead: l.forgotLead,
      children: [
        GlmTextField(
          label: l.email,
          controller: _email,
          ltr: true,
          keyboard: TextInputType.emailAddress,
          autofill: const [AutofillHints.email],
          action: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          error: _error,
        ),
        const SizedBox(height: 18),
        GlmButton(label: l.sendLink, block: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}
