import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'models.dart';

/// [Sprint 16 F1] The leagues on the API: mine, making the free one, joining with a code, a club taken, the table,
/// the matches, the join requests and the holiday.
class LeaguesRepository {
  LeaguesRepository(this._api);

  final ApiClient _api;

  Future<List<League>> mine() async => [for (final l in (await _api.get('/leagues'))['leagues'] as List<dynamic>) League.fromJson(l as Map<String, dynamic>)];
  Future<League> show(int id) async => League.fromJson((await _api.get('/leagues/$id'))['league'] as Map<String, dynamic>);

  Future<List<({String name, int clubs})>> templates() async => [
        for (final t in (await _api.get('/data/templates'))['templates'] as List<dynamic>) (name: '${t['name']}', clubs: t['clubs'] as int? ?? 0),
      ];
  Future<List<ClubCardData>> templateClubs(String template) async =>
      [for (final c in (await _api.get('/data/clubs', query: {'league': template}))['clubs'] as List<dynamic>) ClubCardData.fromJson(c as Map<String, dynamic>)];

  /// The free league (UP9): every setting left to the game's own; the paid custom options stay on the site.
  Future<League> create({required String template, required int masterClubId, String? name, required DateTime startsAt}) async =>
      League.fromJson((await _api.post('/leagues', {
        'template': template, 'club_id': masterClubId, if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'starts_at': startsAt.toUtc().toIso8601String(),
      }))['league'] as Map<String, dynamic>);

  Future<({League league, String status})> join(String code) async {
    final d = await _api.post('/leagues/join', {'code': code});
    return (league: League.fromJson(d['league'] as Map<String, dynamic>), status: '${(d['request'] as Map<dynamic, dynamic>?)?['status'] ?? 'pending'}');
  }

  Future<void> cancelRequest(int league) => _api.delete('/leagues/$league/request');
  Future<List<ClubCardData>> clubs(int league) async =>
      [for (final c in (await _api.get('/leagues/$league/clubs'))['clubs'] as List<dynamic>) ClubCardData.fromJson(c as Map<String, dynamic>)];
  Future<void> claim(int league, int club) => _api.post('/leagues/$league/clubs/$club/claim');

  Future<List<StandingRow>> standings(int league) async =>
      [for (final r in (await _api.get('/leagues/$league/standings'))['table'] as List<dynamic>) StandingRow.fromJson(r as Map<String, dynamic>)];
  Future<List<Fixture>> fixtures(int league) async =>
      [for (final f in (await _api.get('/leagues/$league/fixtures'))['fixtures'] as List<dynamic>) Fixture.fromJson(f as Map<String, dynamic>)];

  Future<List<JoinRequest>> requests(int league) async =>
      [for (final r in (await _api.get('/leagues/$league/requests'))['requests'] as List<dynamic>? ?? const []) JoinRequest.fromJson(r as Map<String, dynamic>)];
  Future<void> decide(int league, int request, bool approve) => _api.post('/leagues/$league/requests/$request/${approve ? 'approve' : 'reject'}');

  Future<void> holiday(int league, int days, String reason) => _api.post('/leagues/$league/vacation', {'days': days, 'reason': reason});
  Future<void> signContract(int league) => _api.post('/leagues/$league/contract');
}

final leaguesRepositoryProvider = Provider<LeaguesRepository>((ref) => LeaguesRepository(ref.watch(apiProvider)));
final myLeaguesProvider = FutureProvider.autoDispose<List<League>>((ref) => ref.read(leaguesRepositoryProvider).mine());
final leagueProvider = FutureProvider.autoDispose.family<League, int>((ref, id) => ref.read(leaguesRepositoryProvider).show(id));
final standingsProvider = FutureProvider.autoDispose.family<List<StandingRow>, int>((ref, id) => ref.read(leaguesRepositoryProvider).standings(id));
final fixturesProvider = FutureProvider.autoDispose.family<List<Fixture>, int>((ref, id) => ref.read(leaguesRepositoryProvider).fixtures(id));
final requestsProvider = FutureProvider.autoDispose.family<List<JoinRequest>, int>((ref, id) => ref.read(leaguesRepositoryProvider).requests(id));
final leagueClubsProvider = FutureProvider.autoDispose.family<List<ClubCardData>, int>((ref, id) => ref.read(leaguesRepositoryProvider).clubs(id));
