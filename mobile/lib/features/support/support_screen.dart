import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../account/account_data.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return screenPage(
      l.support,
      Column(
        children: [
          Expanded(
            child: AsyncView(
              value: ref.watch(supportProvider),
              onRetry: () => ref.invalidate(supportProvider),
              data: (messages) => ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    l.supportLead,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted),
                  ),
                  const SizedBox(height: 10),
                  for (final m in messages)
                    Align(
                      alignment: m.fromTeam ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: m.fromTeam ? p.gold.withValues(alpha: .14) : p.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m.fromTeam)
                              Text(
                                l.fromTeam,
                                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            Text(m.body),
                            if (DateTime.tryParse(m.at) != null)
                              Text(when(context, DateTime.parse(m.at).toLocal()), style: TextStyle(color: p.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(hintText: l.typeMessage, counterText: ''),
                    ),
                  ),
                  IconButton(
                    tooltip: l.send,
                    icon: Icon(Icons.send_rounded, color: p.gold),
                    onPressed: () async {
                      final body = _text.text.trim();
                      if (body.isEmpty) return;
                      if (await tryAction(context, () => ref.read(apiProvider).post('/support', {'body': body})) != null) _text.clear();
                      ref.invalidate(supportProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
