import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/console.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_card.dart';
import '../auth_controller.dart';

/// [Sprint 50 M5] A guest's card on the home screen: the account goes after 30 days unless it is kept. Keeping it opens
/// the console's floating sheet (the fields with their labels beside them, above the keyboard).
class KeepAccountCard extends ConsumerWidget {
  const KeepAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    return GlmCard(
      gold: true,
      accent: p.gold,
      child: Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: p.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.guestBanner, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          GlmButton(
            label: l.keepAccount,
            onPressed: () => showCompactInputSheet<void>(context, title: l.keepAccount, builder: (_) => const _KeepForm()),
          ),
        ],
      ),
    );
  }
}

class _KeepForm extends ConsumerStatefulWidget {
  const _KeepForm();

  @override
  ConsumerState<_KeepForm> createState() => _KeepFormState();
}

class _KeepFormState extends ConsumerState<_KeepForm> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
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
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      await ref
          .read(authProvider.notifier)
          .keepGuest(name: _name.text, username: _username.text, email: _email.text, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showGlmToast(context, l.accountKept);
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
    Widget field(String label, TextEditingController c, String key, {bool ltr = false, bool secret = false, TextInputType? keyboard}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlmCompactField(
            label: label,
            child: TextField(
              controller: c,
              obscureText: secret,
              keyboardType: keyboard,
              textDirection: ltr ? TextDirection.ltr : null,
              decoration: InputDecoration(isDense: true, errorText: _errors[key]),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(l.displayName, _name, 'name'),
        field(l.username, _username, 'username', ltr: true),
        field(l.email, _email, 'email', ltr: true, keyboard: TextInputType.emailAddress),
        field(l.password, _password, 'password', ltr: true, secret: true),
        const SizedBox(height: 4),
        GlmButton(label: l.keepAccount, block: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}
