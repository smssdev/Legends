import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/console.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/shell.dart';
import '../social/social_data.dart';
import 'chat_screen.dart';

/// [Sprint 18 G] Open a group by its invite code (a link gamelegendmanager.online/groups/join/CODE, or typed).
Future<void> joinGroup(BuildContext context, WidgetRef ref, String code) async {
  final r = await tryAction(context, () => ref.read(apiProvider).post('/groups/join/${code.trim().toLowerCase()}'));
  ref.invalidate(groupsProvider);
  final g = r == null ? null : JsonReader(r, 'JoinGroup').objectOrNull('group', api.ChatGroup.fromJson);
  if (g != null && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(groupId: g.id, name: g.name),
      ),
    );
  }
}

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key, this.joinCode});

  /// A code from an invite link: joined as the screen opens.
  final String? joinCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    if (joinCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) joinGroup(context, ref, joinCode!);
      });
    }
    return Scaffold(
      appBar: GameBar(
        title: Text(l.groups),
        actions: [
          IconButton(
            tooltip: l.joinGroup,
            icon: const Icon(Icons.vpn_key_rounded),
            onPressed: () async {
              final code = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: Text(l.joinGroup),
                  content: TextField(
                    controller: code,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.groupCode),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.confirm)),
                  ],
                ),
              );
              if (ok == true && context.mounted) await joinGroup(context, ref, code.text);
              code.dispose();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.group_add_rounded),
        label: Text(l.newGroup),
        onPressed: () async {
          final name = TextEditingController(), members = TextEditingController();
          final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: name,
                    maxLength: 60,
                    decoration: InputDecoration(labelText: l.groupName),
                  ),
                  TextField(
                    controller: members,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.groupMembers),
                  ),
                  const SizedBox(height: 12),
                  GlmButton(label: l.create, block: true, onPressed: () => Navigator.pop(ctx, true)),
                ],
              ),
            ),
          );
          if (ok == true && context.mounted) {
            final usernames = [
              for (final u in members.text.split(RegExp('[,\u060C\\s]+')))
                if (u.trim().isNotEmpty) u.trim().replaceFirst('@', ''),
            ];
            final r = await tryAction(
              context,
              () => ref.read(apiProvider).post('/groups', {'name': name.text.trim(), 'usernames': usernames}),
            );
            ref.invalidate(groupsProvider);
            final g = r == null ? null : JsonReader(r, 'NewGroup').objectOrNull('group', api.ChatGroup.fromJson);
            if (g != null && context.mounted) {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatScreen(groupId: g.id, name: g.name),
                ),
              );
            }
          }
          name.dispose();
          members.dispose();
        },
      ),
      body: GlmBackground(
        child: _GroupsConsole(
          list: (onOpen, open) => _groupsBody(context, ref, l, onOpen: onOpen, open: open),
        ),
      ),
    );
  }

  Widget _groupsBody(BuildContext context, WidgetRef ref, L l, {void Function(int id, String name)? onOpen, int? open}) => AsyncView(
    value: ref.watch(groupsProvider),
    onRetry: () => ref.invalidate(groupsProvider),
    data: (d) {
      final groups = d.groups;
      if (groups.isEmpty) return Center(child: Text(l.noGroups));
      return RefreshIndicator(
        onRefresh: () => ref.refresh(groupsProvider.future),
        child: ListView(
          children: [
            for (final g in groups)
              ListTile(
                // [Sprint 50 M7] The open chat lit as the site's open page (the brand green).
                selected: open == g.id,
                selectedTileColor: context.palette.brand,
                selectedColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: CircleAvatar(
                  backgroundColor: open == g.id ? context.palette.brandDark : context.palette.brand,
                  child: Icon(g.leagueId != null ? Icons.emoji_events_rounded : Icons.groups_rounded, color: Colors.white),
                ),
                title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(g.last?.body ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: g.unread > 0
                    ? Badge(backgroundColor: context.palette.gold, textColor: context.palette.onGold, label: Text('${g.unread}'))
                    : null,
                onTap: () async {
                  if (onOpen != null) return onOpen(g.id, g.name);
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(groupId: g.id, name: g.name),
                    ),
                  );
                  ref.invalidate(groupsProvider);
                },
              ),
          ],
        ),
      );
    },
  );
}

/// A group's conversation: the latest page, asked again every few seconds while open, and a line to write.
/// [Sprint 50 M7] The chats as the tablet and computer messengers: the list at the start (30%) and the open chat beside
/// it (70%) on a wide screen; on a narrow one, the list, each chat opening on its own page.
class _GroupsConsole extends ConsumerStatefulWidget {
  const _GroupsConsole({required this.list});

  final Widget Function(void Function(int id, String name)? onOpen, int? open) list;

  @override
  ConsumerState<_GroupsConsole> createState() => _GroupsConsoleState();
}

class _GroupsConsoleState extends ConsumerState<_GroupsConsole> {
  (int, String)? _open;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 760) return widget.list(null, null);
      final l = L.of(context);
      return GlmSplitLayout(
        ratio: (30, 70),
        start: GlmCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(6, 4, 6, 6), child: GlmSectionTitle(l.channels)),
              Expanded(
                child: widget.list((id, name) {
                  setState(() => _open = (id, name));
                  ref.invalidate(groupsProvider);
                }, _open?.$1),
              ),
            ],
          ),
        ),
        end: _open == null
            ? Center(
                child: Text(l.pickChannel, style: TextStyle(color: context.palette.textMuted)),
              )
            : GlmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: GlmSectionTitle(_open!.$2)),
                    Expanded(
                      child: ChatRoom(key: ValueKey(_open!.$1), groupId: _open!.$1),
                    ),
                  ],
                ),
              ),
      );
    },
  );
}
