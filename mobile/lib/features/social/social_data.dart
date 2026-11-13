import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';

/// [Sprint 18 E] The league's social screens in the app: the friendlies (Sprint 24, a quick match played back fast),
/// the predictions and the newspaper (UP12), and the chat groups (Sprint 29). The server decides and writes all of it.
class SocialRepository {
  SocialRepository(this._api);

  final ApiClient _api;

  /// [Sprint 59 F1] The friendlies (`Friendlies`) and a friendly played (`Friendly`) through their generated models.
  Future<api.Friendlies> friendlies(int league) async => api.Friendlies.fromJson(await _api.get('/leagues/$league/friendlies'));
  Future<api.Friendly> playFriendly(int league, int opponent) => Intents.run(
    'friendly:$league:$opponent',
    (key) async => JsonReader(
      await _api.post('/leagues/$league/friendlies', {'opponent_id': opponent, 'idempotency_key': key}),
      'PlayFriendly',
    ).object('friendly', api.Friendly.fromJson),
  );

  /// [Sprint 59 F1] The round to predict, and the round after a pick, through the generated model (`Predictions`).
  Future<api.Predictions> predictions(int league) async => api.Predictions.fromJson(await _api.get('/leagues/$league/predictions'));
  Future<api.Predictions> predict(int league, int fixture, String pick) async =>
      api.Predictions.fromJson(await _api.post('/leagues/$league/predictions', {'fixture_id': fixture, 'pick': pick}));

  /// [Sprint 59 F1] The newspaper through the generated model (`Newspaper`).
  Future<api.Newspaper> newspaper(int league) async => api.Newspaper.fromJson(await _api.get('/leagues/$league/newspaper'));
  Future<Map<String, dynamic>> write(int league, String title, String body) =>
      _api.post('/leagues/$league/newspaper/articles', {'title': title, 'body': body});
  Future<Map<String, dynamic>> decide(int league, int article, bool publish) =>
      _api.post('/leagues/$league/newspaper/articles/$article/decide', {'publish': publish});
  Future<api.GroupsAnswer> groups() async => api.GroupsAnswer.fromJson(await _api.get('/groups'));

  /// [Sprint 59 F1] A group's messages through the generated model (`ChatMessage`).
  /// [Sprint 61 F3] The latest page, or the one older than [before] (scrolling up).
  Future<List<api.ChatMessage>> messages(int group, {int? before}) async => JsonReader(
    await _api.get('/groups/$group/messages', query: {'before': ?before}),
    'GroupMessages',
  ).list('messages', api.ChatMessage.fromJson);
  Future<void> say(int group, String body, {int? replyTo}) => _api.post('/groups/$group/messages', {'body': body, 'reply_to': ?replyTo});
  Future<void> read(int group) => _api.post('/groups/$group/read');
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) => SocialRepository(ref.watch(apiProvider)));

final friendliesProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).friendlies(l));

final predictionsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).predictions(l));

final newspaperProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).newspaper(l));

final groupsProvider = FutureProvider.autoDispose((ref) => ref.read(socialRepositoryProvider).groups());
