import '../../api/gen/models.g.dart' as api;

/// [Sprint 16] The leagues as the API gives them (only what the app shows).
DateTime? date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// A coach as the API gives him: his name, or an object with it (the clubs list).
String? _name(Object? v) => v is Map<dynamic, dynamic> ? v['name'] as String? : v as String?;

class League {
  const League({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    required this.isOwner,
    this.myClubId,
    this.myRequest,
    this.freeClubs = 0,
    this.pendingRequests = 0,
    this.inviteUrl,
    this.startsAt,
    this.teamCount = 0,
    this.coaches = 0,
    this.members = const [],
    this.seasonNumber,
    this.roundsPlayed,
    this.rounds,
    this.contract,
    this.locked = true,
  });

  /// [Sprint 59 F1] A league from the generated model (`GET /leagues`, `GET /leagues/{id}`).
  factory League.of(api.League l) => League(
    id: l.id,
    name: l.name,
    code: l.code ?? '',
    status: l.status,
    isOwner: l.isOwner,
    myClubId: l.myClubId,
    myRequest: l.myRequest,
    freeClubs: l.freeClubs ?? 0,
    pendingRequests: l.pendingRequests ?? 0,
    inviteUrl: l.inviteUrl,
    startsAt: date(l.startsAt),
    teamCount: l.teamCount,
    coaches: l.coaches,
    members: [for (final m in l.members) Member.of(m)],
    seasonNumber: l.season?.number,
    roundsPlayed: l.season?.roundsPlayed,
    rounds: l.season?.rounds,
    contract: l.me?.contract,
    locked: l.locked,
  );

  /// A league in a smaller answer (a new league, a join), not yet in the contract's models.
  factory League.fromJson(Map<String, dynamic> j) {
    final season = j['season'] as Map<String, dynamic>?;
    final me = j['me'] as Map<String, dynamic>?;
    return League(
      id: j['id'] as int,
      name: '${j['name']}',
      code: '${j['code']}',
      status: '${j['status']}',
      isOwner: j['is_owner'] == true,
      myClubId: j['my_club_id'] as int?,
      myRequest: j['my_request'] as String?,
      freeClubs: j['free_clubs'] as int? ?? 0,
      pendingRequests: j['pending_requests'] as int? ?? 0,
      inviteUrl: j['invite_url'] as String?,
      startsAt: date(j['starts_at']),
      teamCount: j['team_count'] as int? ?? 0,
      coaches: j['coaches'] as int? ?? 0,
      members: [for (final m in (j['members'] as List<dynamic>? ?? const [])) Member.fromJson(m as Map<String, dynamic>)],
      seasonNumber: season?['number'] as int?,
      roundsPlayed: season?['rounds_played'] as int?,
      rounds: season?['rounds'] as int?,
      contract: me?['contract'] == null ? null : api.LeagueMeContract.fromJson(me!['contract']),
      locked: j['locked'] != false,
    );
  }

  final int id;
  final String name, code, status;
  final bool isOwner;

  /// Its settings are locked once it starts [PLAN 2.3].
  final bool locked;
  final int? myClubId;
  final String? myRequest, inviteUrl;
  final int freeClubs, pendingRequests, teamCount, coaches;
  final DateTime? startsAt;
  final List<Member> members;
  final int? seasonNumber, roundsPlayed, rounds;

  /// [Sprint 43 W1] The contract waiting for my signature this season.
  final api.LeagueMeContract? contract;

  bool get canPick => myClubId == null && (isOwner || myRequest == 'approved') && freeClubs > 0;
}

class Member {
  const Member({
    required this.id,
    required this.name,
    this.username,
    this.club,
    this.isOwner = false,
    this.onHoliday = false,
    this.userId,
    this.vacationRequest,
  });

  /// [Sprint 59 F1] From the generated model.
  factory Member.of(api.LeagueMembersItem m) => Member(
    id: m.id,
    name: m.user.name,
    username: m.user.username,
    club: m.club?.name,
    isOwner: m.isOwner,
    onHoliday: m.onHoliday,
    userId: m.user.id,
    vacationRequest: m.vacationRequest == null ? null : (days: m.vacationRequest!.days ?? 0, reason: m.vacationRequest!.reason ?? ''),
  );

  factory Member.fromJson(Map<String, dynamic> j) {
    final u = j['user'] as Map<String, dynamic>? ?? const {};
    final c = j['club'] as Map<String, dynamic>?;
    return Member(
      id: j['id'] as int,
      name: '${u['name'] ?? ''}',
      username: u['username'] as String?,
      club: c?['name'] as String?,
      isOwner: j['is_owner'] == true,
      onHoliday: j['on_holiday'] == true,
      userId: u['id'] as int?,
      vacationRequest: j['vacation_request'] is Map<dynamic, dynamic>
          ? (
              days: (j['vacation_request'] as Map<dynamic, dynamic>)['days'] as int? ?? 0,
              reason: '${(j['vacation_request'] as Map<dynamic, dynamic>)['reason'] ?? ''}',
            )
          : null,
    );
  }

  final int id;
  final String name;
  final String? username, club;
  final bool isOwner, onHoliday;

  /// The coach's account, for his profile.
  final int? userId;

  /// A holiday he asked for, for the league's creator to answer.
  final ({int days, String reason})? vacationRequest;
}

class ClubCardData {
  const ClubCardData({
    required this.id,
    required this.name,
    required this.code,
    this.crestUrl,
    this.strength = 0,
    this.coach,
    this.bot = true,
    this.goal,
  });

  factory ClubCardData.fromJson(Map<String, dynamic> j) {
    final league = (j['objectives'] as Map<String, dynamic>?)?['league'] as Map<String, dynamic>?;
    return ClubCardData(
      id: j['id'] as int,
      name: '${j['name']}',
      code: '${j['code'] ?? ''}',
      crestUrl: j['crest_url'] as String?,
      strength: j['strength_cp'] as int? ?? 0,
      coach: _name(j['coach']),
      bot: j['bot'] != false,
      goal: league == null ? null : (kind: '${league['kind']}', target: league['target'] as int? ?? 0),
    );
  }

  final int id;
  final String name, code;
  final String? crestUrl, coach;
  final int strength;
  final bool bot;
  final ({String kind, int target})? goal;
}

class StandingRow {
  const StandingRow({
    required this.position,
    required this.id,
    required this.name,
    required this.code,
    this.crestUrl,
    this.coach,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.gd,
    required this.points,
  });

  factory StandingRow.fromJson(Map<String, dynamic> j) => StandingRow(
    position: j['position'] as int,
    id: j['id'] as int,
    name: '${j['name']}',
    code: '${j['code'] ?? ''}',
    crestUrl: j['crest_url'] as String?,
    coach: _name(j['coach']),
    played: j['played'] as int? ?? 0,
    won: j['won'] as int? ?? 0,
    drawn: j['drawn'] as int? ?? 0,
    lost: j['lost'] as int? ?? 0,
    gd: j['goal_difference'] as int? ?? 0,
    points: j['points'] as int? ?? 0,
  );

  final int position, id, played, won, drawn, lost, gd, points;
  final String name, code;
  final String? crestUrl, coach;
}

class Side {
  const Side({required this.id, required this.name, required this.code, this.crestUrl});

  /// [Sprint 59 F1] From the generated model (a fixture's club; none for a rest).
  factory Side.of(api.FixtureClub? c) => Side(id: c?.id ?? 0, name: c?.name ?? '', code: c?.code ?? '', crestUrl: c?.crestUrl);

  factory Side.fromJson(Map<String, dynamic>? j) =>
      Side(id: j?['id'] as int? ?? 0, name: '${j?['name'] ?? ''}', code: '${j?['code'] ?? ''}', crestUrl: j?['crest_url'] as String?);

  final int id;
  final String name, code;
  final String? crestUrl;
}

class Fixture {
  const Fixture({
    required this.id,
    required this.competition,
    this.round,
    this.stage,
    this.at,
    required this.home,
    required this.away,
    required this.status,
    this.homeGoals,
    this.awayGoals,
    this.isBye = false,
    this.matchId,
  });

  /// [Sprint 59 F1] From the generated model.
  factory Fixture.of(api.Fixture f) => Fixture(
    id: f.id,
    competition: f.competition,
    round: f.round,
    stage: f.stage,
    at: date(f.scheduledAt),
    home: Side.of(f.home),
    away: Side.of(f.away),
    status: f.status,
    homeGoals: f.homeGoals,
    awayGoals: f.awayGoals,
    isBye: f.isBye,
    matchId: f.matchId?.toString(),
  );

  final int id;
  final String competition, status;
  final int? round, homeGoals, awayGoals;
  final String? stage, matchId;
  final DateTime? at;
  final Side home, away;
  final bool isBye;

  bool get finished => status == 'finished';
  bool get live => status == 'live';
}

class JoinRequest {
  const JoinRequest({required this.id, required this.name, this.username, required this.status});

  factory JoinRequest.fromJson(Map<String, dynamic> j) {
    final u = j['user'] as Map<String, dynamic>? ?? const {};
    return JoinRequest(id: j['id'] as int, name: '${u['name'] ?? ''}', username: u['username'] as String?, status: '${j['status']}');
  }

  final int id;
  final String name, status;
  final String? username;
}
