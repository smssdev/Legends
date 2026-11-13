import '../../api/gen/models.g.dart' as api;

/// [Sprint 16] The leagues as the API gives them (only what the app shows).
DateTime? date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

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

  /// Any answer with a league (a new one, a join, a change): the server sends them all through leagueData().
  factory League.fromJson(Object? json) => League.of(api.League.fromJson(json));

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

  /// [Sprint 59 F1] A league's club (`LeagueClub`): its coach and its board's goal.
  factory ClubCardData.of(api.LeagueClub c) => ClubCardData(
    id: c.id,
    name: c.name,
    code: c.code,
    crestUrl: c.crestUrl,
    strength: c.strengthCp,
    coach: c.coach?.name,
    bot: c.bot,
    goal: c.objectives == null ? null : (kind: c.objectives!.league.kind, target: c.objectives!.league.target),
  );

  /// A data club to start a league with (`DataClub`): no coach, no goal yet.
  factory ClubCardData.ofData(api.DataClub c) =>
      ClubCardData(id: c.id, name: c.name, code: c.code, crestUrl: c.crestUrl, strength: c.strengthCp);

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

  /// [Sprint 59 F1] A row of the table, from the generated model.
  factory StandingRow.fromJson(Object? json) {
    final r = api.LeaguesStandingsAnswerTableItem.fromJson(json);
    return StandingRow(
      position: r.position,
      id: r.id,
      name: r.name,
      code: r.code,
      crestUrl: r.crestUrl,
      coach: r.coach,
      played: r.played,
      won: r.won,
      drawn: r.drawn,
      lost: r.lost,
      gd: r.goalDifference,
      points: r.points,
    );
  }

  final int position, id, played, won, drawn, lost, gd, points;
  final String name, code;
  final String? crestUrl, coach;
}

class Side {
  const Side({required this.id, required this.name, required this.code, this.crestUrl});

  /// [Sprint 59 F1] From the generated model (a fixture's club; none for a rest).
  factory Side.of(api.FixtureClub? c) => Side(id: c?.id ?? 0, name: c?.name ?? '', code: c?.code ?? '', crestUrl: c?.crestUrl);

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

  /// [Sprint 59 F1] From the generated model (the server sends no username with a request).
  factory JoinRequest.of(api.JoinRequest r) => JoinRequest(id: r.id, name: r.user?.name ?? '', status: r.status);

  final int id;
  final String name, status;
  final String? username;
}
