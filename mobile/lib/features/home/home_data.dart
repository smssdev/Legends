import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

/// [Sprint 15] The coach's home (`/home`, X18): his card, his coins and rating, and his eight club slots.
class HomeData {
  const HomeData({required this.coach, required this.slots, required this.slotsOpen, this.starterCoins = 0, this.starterClaimed = true});

  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
        coach: Coach.fromJson(j['coach'] as Map<String, dynamic>),
        slots: [for (final s in j['slots'] as List<dynamic>) Slot.fromJson(s as Map<String, dynamic>)],
        slotsOpen: j['slots_open'] as int? ?? 0,
        starterCoins: (j['starter_gift'] as Map<dynamic, dynamic>?)?['coins'] as int? ?? 0, starterClaimed: (j['starter_gift'] as Map<dynamic, dynamic>?)?['claimed'] != false,
      );

  final Coach coach;
  final List<Slot> slots;
  final int slotsOpen;

  /// [Sprint 30 P6] A new coach's first coins, claimed once.
  final int starterCoins;
  final bool starterClaimed;
}

class Coach {
  const Coach({required this.name, required this.coins, required this.tierKey, this.division, this.points = 0, this.accountNo, this.won = 0, this.drawn = 0, this.lost = 0});

  factory Coach.fromJson(Map<String, dynamic> j) {
    final rating = j['rating'] as Map<String, dynamic>? ?? const {};
    final tier = rating['tier'] as Map<String, dynamic>? ?? const {};
    final record = j['record'] as Map<String, dynamic>? ?? const {};
    return Coach(
      name: '${j['name'] ?? ''}', coins: j['coins'] as int? ?? 0, accountNo: j['account_no'] as int?,
      tierKey: '${tier['key'] ?? 'prospect'}', division: tier['division'] as int?, points: rating['points'] as int? ?? 0,
      won: record['won'] as int? ?? 0, drawn: record['drawn'] as int? ?? 0, lost: record['lost'] as int? ?? 0,
    );
  }

  final String name;
  final int coins;
  final String tierKey;
  final int? division;
  final int points;
  final int? accountNo;
  final int won, drawn, lost;
}

enum SlotState { club, waiting, free, locked }

class Slot {
  const Slot({required this.number, required this.state, this.leagueId, this.leagueName, this.clubName, this.crestUrl, this.position, this.teams, this.pending = 0,
      this.opponent, this.home = true, this.live = false, this.matchAt, this.opensAt, this.unlockCoins});

  factory Slot.fromJson(Map<String, dynamic> j) {
    final league = j['league'] as Map<String, dynamic>?;
    final club = j['club'] as Map<String, dynamic>?;
    final next = j['next_match'] as Map<String, dynamic>?;
    DateTime? at(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return Slot(
      number: j['slot'] as int, state: SlotState.values.byName('${j['state']}'),
      leagueId: league?['id'] as int?, leagueName: league?['name'] as String?, clubName: club?['name'] as String?, crestUrl: club?['crest_url'] as String?,
      position: j['position'] as int?, teams: j['teams'] as int?, pending: j['pending'] as int? ?? 0,
      opponent: next?['opponent'] as String?, home: next?['venue'] != 'away', live: next?['live'] == true, matchAt: at(next?['scheduled_at']),
      opensAt: at(j['opens_at']), unlockCoins: j['unlock_coins'] as int?,
    );
  }

  final int number;
  final SlotState state;
  final int? leagueId;
  final String? leagueName, clubName, crestUrl, opponent;
  final int? position, teams, unlockCoins;
  final int pending;
  final bool home, live;
  final DateTime? matchAt, opensAt;
}

final homeProvider = FutureProvider.autoDispose<HomeData>((ref) async => HomeData.fromJson(await ref.read(apiProvider).get('/home')));
