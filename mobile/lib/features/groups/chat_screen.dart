import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/live/live_channels.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/glm_background.dart';
import '../auth/auth_controller.dart';
import '../console/console_data.dart';
import '../leagues/shell.dart';
import 'chat_controller.dart';
import 'group_media.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.groupId, required this.name});

  final int groupId;
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GameBar(title: Text(name)),
    body: GlmBackground(child: ChatRoom(groupId: groupId)),
  );
}

/// [Sprint 50 M7, M8] A chat's messages and its composer: my messages on the end side in the brand green, the others'
/// on the start side with their name; a swipe or a long press answers one (its quote over the composer), and a long
/// press gives the four quick reactions (the server counts them, one each).
class ChatRoom extends ConsumerStatefulWidget {
  const ChatRoom({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<ChatRoom> createState() => _ChatRoomState();
}

const _reactions = {'ball': '⚽', 'fire': '🔥', 'cup': '🏆', 'laugh': '😂'};

class _ChatRoomState extends ConsumerState<ChatRoom> {
  // [Sprint 59 F5] The messages and the send live in ChatController.
  ChatController get _chat => ref.read(chatControllerProvider(widget.groupId).notifier);
  late ChatState _state;
  List<api.ChatMessage> get _messages => _state.messages;
  bool get _sending => _state.sending;
  final _text = TextEditingController();
  Timer? _poll;
  api.ChatMessage? _replyTo;

  /// [Sprint 53 F2] The group's channel: a new message (or one changed) comes at once, and the 4-second poll runs only
  /// while the channel is down; with it, a check every 30 seconds as a safety net.
  LiveSubscription? _channel;
  DateTime _loadedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _load();
    _channel = ref.read(liveFeedProvider).join('chat.${widget.groupId}', {'chat': (_) => _load()});
    _channel!.subscribed.addListener(_load);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_channel?.subscribed.value != true || DateTime.now().difference(_loadedAt).inSeconds >= 30) _load();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _channel?.subscribed.removeListener(_load);
    _channel?.leave();
    _recorder.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _loadedAt = DateTime.now();
    await _chat.load();
  }

  /// A voice note: the first tap records (AAC, up to the server's two minutes), the second stops and sends it.
  final _recorder = AudioRecorder();
  DateTime? _recordingSince;

  Future<void> _voice() async {
    if (_recordingSince == null) {
      if (!await _recorder.hasPermission()) {
        if (mounted) showGlmToast(context, L.of(context).micDenied, error: true);
        return;
      }
      final dir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 48000, sampleRate: 22050, numChannels: 1),
        path: '${dir.path}/note-${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      setState(() => _recordingSince = DateTime.now());
      return;
    }
    final seconds = DateTime.now().difference(_recordingSince!).inSeconds.clamp(1, 120);
    final path = await _recorder.stop();
    setState(() => _recordingSince = null);
    _chat.busy(true);
    try {
      if (path != null) {
        await ref
            .read(apiProvider)
            .upload('/groups/${widget.groupId}/media', 'file', path, fields: {'kind': 'audio', 'seconds': seconds}, type: 'audio/mp4');
        await _load();
      }
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      _chat.busy(false);
    }
  }

  Future<void> _send() async {
    final sent = await _chat.send(_text.text, replyTo: _replyTo?.id);
    if (!mounted) return;
    if (sent) {
      _text.clear();
      setState(() => _replyTo = null);
    } else if (ref.read(chatControllerProvider(widget.groupId)).error case final error?) {
      showGlmToast(context, error, error: true);
    }
  }

  Future<void> _react(api.ChatMessage m, String key) async {
    try {
      await ref.read(consoleRepositoryProvider).react(widget.groupId, m.id, key);
      unawaited(HapticFeedback.selectionClick());
      await _load();
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    }
  }

  Future<void> _actions(api.ChatMessage m) async {
    final l = L.of(context);
    final pick = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final e in _reactions.entries)
                    Semantics(
                      button: true,
                      selected: m.myReaction == e.key,
                      label: {'ball': l.reactBall, 'fire': l.reactFire, 'cup': l.reactCup, 'laugh': l.reactLaugh}[e.key],
                      child: InkResponse(
                        onTap: () => Navigator.pop(ctx, e.key),
                        radius: 28,
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m.myReaction == e.key ? ctx.palette.brand : ctx.palette.surfaceRaised,
                          ),
                          child: Text(e.value, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(leading: const Icon(Icons.reply_rounded), title: Text(l.reply), onTap: () => Navigator.pop(ctx, 'reply')),
            ],
          ),
        ),
      ),
    );
    if (pick == null || !mounted) return;
    if (pick == 'reply') return setState(() => _replyTo = m);
    await _react(m, pick);
  }

  @override
  Widget build(BuildContext context) {
    _state = ref.watch(chatControllerProvider(widget.groupId));
    final l = L.of(context);
    final p = context.palette;
    final me = ref.watch(authProvider).value?.id;
    return Column(
      children: [
        Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.all(12),
            children: [
              for (final m in _messages.reversed)
                if (m.kind == 'note') const SizedBox.shrink() else _bubble(context, l, p, m, mine: m.user?.id == me),
            ],
          ),
        ),
        if (_replyTo != null)
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
              border: BorderDirectional(start: BorderSide(color: p.brandLight, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.replyingTo(_replyTo!.body),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textSoft, fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: l.cancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _replyTo = null),
                ),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: _recordingSince == null ? l.recordVoice : l.stopAndSend,
                  icon: Icon(
                    _recordingSince == null ? Icons.mic_rounded : Icons.stop_circle_rounded,
                    color: _recordingSince == null ? p.gold : context.glm.liveText,
                  ),
                  onPressed: _sending ? null : _voice,
                ),
                IconButton(
                  tooltip: l.sendPhoto,
                  icon: Icon(Icons.image_rounded, color: p.gold),
                  onPressed: _sending
                      ? null
                      : () async {
                          final f = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1600,
                            maxHeight: 1600,
                            imageQuality: 80,
                          );
                          if (f == null) return;
                          _chat.busy(true);
                          try {
                            await ref
                                .read(apiProvider)
                                .upload('/groups/${widget.groupId}/media', 'file', f.path, fields: {'kind': 'image'});
                            await _load();
                          } on ApiError catch (e) {
                            if (mounted) showGlmToast(this.context, e.message, error: true);
                          } finally {
                            _chat.busy(false);
                          }
                        },
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l.typeMessage,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  label: l.send,
                  child: InkResponse(
                    onTap: _sending ? null : _send,
                    radius: 24,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: p.gold, shape: BoxShape.circle),
                      child: Icon(Icons.send_rounded, color: p.onGold, size: 20, textDirection: Directionality.of(context)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(BuildContext context, L l, GlmPalette p, api.ChatMessage m, {required bool mine}) {
    final reactions = (m.reactions ?? const {}).entries.where((e) => e.value > 0).toList();
    final reply = m.replyTo;
    final bubble = Container(
      margin: EdgeInsets.only(bottom: reactions.isEmpty ? 6 : 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: mine ? p.brandDark : p.surface,
        borderRadius: BorderRadius.circular(14),
        border: mine ? null : Border.all(color: p.surfaceRaised),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine)
            Text(
              m.user?.name ?? '',
              style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          if (reply != null)
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 4),
              padding: const EdgeInsetsDirectional.only(start: 6),
              decoration: BoxDecoration(
                border: BorderDirectional(start: BorderSide(color: p.brandLight, width: 2)),
              ),
              child: Text(
                reply.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textSoft, fontSize: 11),
              ),
            ),
          if (!m.deleted && m.kind == 'image')
            GroupImage(path: '/groups/${widget.groupId}/media/${m.id}')
          else if (!m.deleted && m.kind == 'audio')
            GroupVoice(path: '/groups/${widget.groupId}/media/${m.id}', seconds: m.seconds ?? 0)
          else
            Text(
              m.deleted
                  ? l.messageDeleted
                  : m.kind == 'text'
                  ? m.body
                  : l.mediaOnWeb,
              style: TextStyle(fontStyle: m.deleted || m.kind != 'text' ? FontStyle.italic : null),
            ),
          if (!m.deleted && m.kind == 'image' && m.body != '') Text(m.body),
        ],
      ),
    );
    final withReactions = Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        if (reactions.isNotEmpty)
          PositionedDirectional(
            bottom: 2,
            end: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in reactions)
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: m.myReaction == e.key ? p.brand : p.surfaceRaised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${_reactions[e.key] ?? ''} ${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
      ],
    );
    // A swipe answers it (the bubble springs back), a long press opens the reactions and the reply.
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Dismissible(
        key: ValueKey('m${m.id}'),
        direction: m.deleted ? DismissDirection.none : DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          unawaited(HapticFeedback.selectionClick());
          setState(() => _replyTo = m);
          return false;
        },
        background: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Icon(Icons.reply_rounded, color: p.brandLight),
        ),
        child: GestureDetector(onLongPress: m.deleted ? null : () => _actions(m), child: withReactions),
      ),
    );
  }
}
