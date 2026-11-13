import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_error.dart';
import '../social/social_data.dart';

/// A chat on the screen: its messages (oldest first), a message on its way, and the last refusal.
typedef ChatState = ({List<api.ChatMessage> messages, bool sending, String? error});

/// [Sprint 59 F5] A group's chat: the messages as the server lists them, and the coach's message sent once (a send
/// while one is on its way is ignored), the text kept when it is refused. The screen draws [state] and calls the actions.
class ChatController extends Notifier<ChatState> {
  ChatController(this.group);

  final int group;

  @override
  ChatState build() => (messages: const [], sending: false, error: null);

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  /// The messages again (the channel says one came, or the poll); a failed read keeps what is shown.
  Future<void> load() async {
    try {
      final m = await _repo.messages(group);
      state = (messages: m, sending: state.sending, error: state.error);
      _repo.read(group).ignore();
    } on ApiError {
      // Asked again in a moment.
    }
  }

  /// True when the server took [body] (the screen clears its text then).
  Future<bool> send(String body, {int? replyTo}) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return false;
    state = (messages: state.messages, sending: true, error: null);
    try {
      await _repo.say(group, text, replyTo: replyTo);
      state = (messages: state.messages, sending: false, error: null);
      await load();
      return true;
    } on ApiError catch (e) {
      state = (messages: state.messages, sending: false, error: e.message);
      return false;
    }
  }

  /// Something else is being sent (a voice note, a picture): the composer waits.
  void busy(bool on) => state = (messages: state.messages, sending: on, error: state.error);
}

final chatControllerProvider = NotifierProvider.autoDispose.family<ChatController, ChatState, int>(ChatController.new);
