import '../../ui/tokens.g.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../leagues/widgets.dart' show when;
import 'inbox_data.dart';
import '../../router.dart' show knownRoute;
import '../leagues/shell.dart';

/// [Sprint 18 F1] The inbox: the newest first, unread marked; a tap reads it and opens its screen in the app.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  late final InboxRepository _repo = ref.read(inboxRepositoryProvider);
  final List<InboxMessage> _items = [];
  bool _more = false, _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool next = false}) async {
    setState(() => _loading = true);
    try {
      final page = await _repo.page(before: next && _items.isNotEmpty ? _items.last.id : null);
      if (!mounted) return;
      setState(() {
        if (!next) _items.clear();
        _items.addAll(page.messages);
        _more = page.more;
        _error = null;
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(int i) async {
    final m = _items[i];
    if (!m.read) {
      setState(() => _items[i] = m.asRead());
      try {
        await _repo.read(m.id);
      } on ApiError {
        // Read again next time.
      }
      ref.invalidate(unreadProvider);
    }
    final route = m.route;
    if (route != null && mounted && knownRoute(GoRouter.of(context), route)) unawaited(context.push(route));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Scaffold(
      appBar: GameBar(
        title: Text(l.inbox),
        actions: [
          if (_items.any((m) => !m.read))
            TextButton(
              onPressed: () async {
                setState(() => _items.setAll(0, _items.map((m) => m.asRead())));
                await _repo.readAll();
                ref.invalidate(unreadProvider);
              },
              child: Text(l.readAll),
            ),
        ],
      ),
      body: GlmBackground(
        child: RefreshIndicator(
          color: p.gold,
          onRefresh: _load,
          child: _error != null && _items.isEmpty
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  ],
                )
              : _items.isEmpty && !_loading
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Text(
                        l.noMessages,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textMuted),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length + (_more ? 1 : 0),
                  separatorBuilder: (_, _) => Divider(height: 1, color: p.surfaceRaised),
                  itemBuilder: (context, i) {
                    if (i == _items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: GlmButton(
                          label: l.more,
                          variant: GlmButtonVariant.quiet,
                          loading: _loading,
                          onPressed: () => _load(next: true),
                        ),
                      );
                    }
                    final m = _items[i];
                    return ListTile(
                      onTap: () => _open(i),
                      leading: Icon(
                        m.read ? Icons.mark_email_read_outlined : Icons.mark_email_unread_rounded,
                        color: m.read ? p.textMuted : p.gold,
                      ),
                      title: Text(m.title, style: TextStyle(fontWeight: m.read ? FontWeight.w600 : FontWeight.w800)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(m.body),
                          if (m.at != null) Text(when(context, m.at!.toLocal()), style: glmText(GlmType.caption, color: p.textMuted)),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
