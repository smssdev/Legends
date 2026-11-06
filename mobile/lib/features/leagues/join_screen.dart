import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/glm_text_field.dart';
import 'leagues_repository.dart';
import 'models.dart';
import 'shell.dart';

/// [Sprint 16 F1, F2] Join with a league's code (typed, or from an invite link that opened the app): the request, then
/// the creator's answer, then the team.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, this.code});

  final String? code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final _code = TextEditingController(text: widget.code ?? '');
  bool _busy = false;
  String? _error;
  ({League league, String status})? _sent;

  @override
  void initState() {
    super.initState();
    if ((widget.code ?? '').isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_code.text.trim().isEmpty) return setState(() => _error = L.of(context).required);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await ref.read(leaguesRepositoryProvider).join(_code.text);
      ref.invalidate(myLeaguesProvider);
      if (!mounted) return;
      if (sent.league.myClubId != null || sent.league.canPick || sent.status == 'approved') return context.pushReplacement('/leagues/${sent.league.id}');
      setState(() => _sent = sent);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.fields['code'] ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Scaffold(
      appBar: GameBar(title: Text(l.joinTitle)),
      body: GlmBackground(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (_sent == null) ...[
            Text(l.joinLead, style: TextStyle(color: p.textSoft, height: 1.6)),
            const SizedBox(height: 18),
            GlmTextField(label: l.code, controller: _code, ltr: true, hint: 'K7F2QX9M', action: TextInputAction.done, onSubmitted: (_) => _send(), error: _error),
            const SizedBox(height: 16),
            GlmButton(label: l.sendRequest, block: true, loading: _busy, onPressed: _send),
          ] else
            GlmCard(
              gold: true,
              child: Column(children: [
                Icon(_sent!.status == 'rejected' ? Icons.block_rounded : Icons.hourglass_top_rounded, size: 44, color: p.gold),
                const SizedBox(height: 10),
                Text(_sent!.league.name, style: context.text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(_sent!.status == 'rejected' ? l.requestRejected : l.requestPending, textAlign: TextAlign.center, style: TextStyle(color: p.textSoft)),
                const SizedBox(height: 16),
                if (_sent!.status == 'pending')
                  GlmButton(label: l.cancelRequest, variant: GlmButtonVariant.quiet, onPressed: () async {
                    await ref.read(leaguesRepositoryProvider).cancelRequest(_sent!.league.id);
                    ref.invalidate(myLeaguesProvider);
                    if (context.mounted) context.pop();
                  }),
              ]),
            ),
        ]),
      ),
    );
  }
}
