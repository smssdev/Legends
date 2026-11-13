import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_error.dart';
import '../social/social_data.dart';

/// A chat on the screen: its messages (oldest first), a message on its way, the last refusal, and whether older
/// messages may wait on the server.
typedef ChatState = ({List<api.ChatMessage> messages, bool sending, String? error, bool more});

/// [Sprint 59 F5] A group's chat: the messages as the server lists them, and the coach's message sent once (a send
/// while one is on its way is ignored), the text kept when it is refused. The screen draws [state] and calls the actions.
class ChatController extends Notifier<ChatState> {
  ChatController(this.group);

  final int group;

  @override
  ChatState build() => (messages: const [], sending: false, error: null, more: true);

  bool _older = false;

  ChatState _with({List<api.ChatMessage>? messages, bool? sending, String? error, bool keepError = true, bool? more}) => (
    messages: messages ?? state.messages,
    sending: sending ?? state.sending,
    error: keepError ? (error ?? state.error) : error,
    more: more ?? state.more,
  );

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  /// The messages again (the channel says one came, or the poll); a failed read keeps what is shown.
  Future<void> load() async {
    try {
      final m = await _repo.messages(group);
      // The older pages already read stay above the latest one.
      final first = m.isEmpty ? null : m.first.id;
      state = _with(messages: [...state.messages.where((x) => first != null && x.id < first), ...m]);
      _repo.read(group).ignore();
    } on ApiError {
      // Asked again in a moment.
    }
  }

  /// [Sprint 61 F3] The page older than the first shown (the coach scrolled to the top); none left ends it.
  Future<void> loadOlder() async {
    if (_older || !state.more || state.messages.isEmpty) return;
    _older = true;
    try {
      final first = state.messages.first.id;
      final m = [...(await _repo.messages(group, before: first)).where((x) => x.id < first)];
      state = _with(messages: [...m, ...state.messages], more: m.isNotEmpty);
    } on ApiError {
      // Asked again at the next scroll.
    } finally {
      _older = false;
    }
  }

  /// True when the server took [body] (the screen clears its text then).
  Future<bool> send(String body, {int? replyTo}) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return false;
    state = _with(sending: true, keepError: false);
    try {
      await _repo.say(group, text, replyTo: replyTo);
      state = _with(sending: false, keepError: false);
      await load();
      return true;
    } on ApiError catch (e) {
      state = _with(sending: false, error: e.message, keepError: false);
      return false;
    }
  }

  /// Something else is being sent (a voice note, a picture): the composer waits.
  void busy(bool on) => state = _with(sending: on);
}

final chatControllerProvider = NotifierProvider.autoDispose.family<ChatController, ChatState, int>(ChatController.new);
