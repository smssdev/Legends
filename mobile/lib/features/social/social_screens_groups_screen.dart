part of 'social_screens.dart';

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
            final r = await _try(context, () => ref.read(apiProvider).post('/groups', {'name': name.text.trim(), 'usernames': usernames}));
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

/// A picture sent in a group: private to its members, so fetched with the account's token, once.
class _GroupImage extends ConsumerStatefulWidget {
  const _GroupImage({required this.path});

  final String path;

  @override
  ConsumerState<_GroupImage> createState() => _GroupImageState();
}

class _GroupImageState extends ConsumerState<_GroupImage> {
  late final Future<List<int>> _bytes = ref.read(apiProvider).bytes(widget.path);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
    future: _bytes,
    builder: (_, s) => s.hasData && s.data!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(Uint8List.fromList(s.data!), width: 240, fit: BoxFit.cover),
          )
        : const SizedBox(width: 240, height: 140, child: Center(child: CircularProgressIndicator())),
  );
}

/// A voice note sent in a group: fetched once with the account's token, then played from the phone.
class _GroupVoice extends ConsumerStatefulWidget {
  const _GroupVoice({required this.path, required this.seconds});

  final String path;
  final int seconds;

  @override
  ConsumerState<_GroupVoice> createState() => _GroupVoiceState();
}

class _GroupVoiceState extends ConsumerState<_GroupVoice> {
  final _player = AudioPlayer();
  bool _playing = false, _loading = false;
  String? _file;
  StreamSubscription<void>? _done;

  @override
  void initState() {
    super.initState();
    _done = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    unawaited(_done?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    if (_file == null) {
      setState(() => _loading = true);
      try {
        final bytes = await ref.read(apiProvider).bytes(widget.path);
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/voice-${widget.path.hashCode}.m4a');
        await f.writeAsBytes(bytes);
        _file = f.path;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
    }
    await _player.play(DeviceFileSource(_file!));
    if (mounted) {
      setState(() {
        _playing = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        onPressed: _loading ? null : _toggle,
        icon: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: context.palette.gold),
      ),
      Text(L.of(context).voiceNote(widget.seconds)),
    ],
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
