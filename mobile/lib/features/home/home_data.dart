import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';

/// [Sprint 15] The coach's home (`/home`, X18): his card, his coins and rating, and his eight club slots.
class HomeData {
  const HomeData({
    required this.coach,
    required this.slots,
    required this.slotsOpen,
    this.starterCoins = 0,
    this.starterClaimed = true,
    this.firstSteps = const {},
  });

  /// [Sprint 59 F1] The coach's home (`HomeScreen`), read through its generated model.
  factory HomeData.fromJson(Object? json) {
    final h = api.HomeScreen.fromJson(json);
    return HomeData(
      coach: Coach.of(h.coach),
      slots: [for (final s in h.slots) Slot.of(s)],
      slotsOpen: h.slotsOpen,
      starterCoins: h.starterGift.coins,
      starterClaimed: h.starterGift.claimed,
      firstSteps: {'club': h.onboarding.club, 'lineup': h.onboarding.lineup, 'match': h.onboarding.match},
    );
  }

  final Coach coach;
  final List<Slot> slots;
  final int slotsOpen;

  /// [Sprint 30 P6] A new coach's first coins, claimed once.
  final int starterCoins;
  final bool starterClaimed;

  /// [Sprint 64 F2] The three first steps (a club, its lineup, a match), each done in the game.
  final Map<String, bool> firstSteps;
}

class Coach {
  const Coach({
    required this.name,
    required this.coins,
    required this.tierKey,
    this.division,
    this.points = 0,
    this.accountNo,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
  });

  factory Coach.of(api.HomeScreenCoach c) => Coach(
    name: c.name,
    coins: c.coins,
    accountNo: c.accountNo,
    tierKey: c.rating.tier.key,
    division: c.rating.tier.division,
    points: c.rating.points,
    won: c.record.won,
    drawn: c.record.drawn,
    lost: c.record.lost,
  );

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
  const Slot({
    required this.number,
    required this.state,
    this.leagueId,
    this.leagueName,
    this.clubName,
    this.crestUrl,
    this.position,
    this.teams,
    this.pending = 0,
    this.opponent,
    this.home = true,
    this.live = false,
    this.matchAt,
    this.opensAt,
    this.unlockCoins,
  });

  factory Slot.of(api.HomeScreenSlotsItem s) {
    DateTime? at(String? v) => v == null ? null : DateTime.tryParse(v)?.toLocal();
    return Slot(
      number: s.slot,
      state: SlotState.values.byName(s.state),
      leagueId: s.league?.id,
      leagueName: s.league?.name,
      clubName: s.club?.name,
      crestUrl: s.club?.crestUrl,
      position: s.position,
      teams: s.teams,
      pending: s.pending,
      opponent: s.nextMatch?.opponent,
      home: s.nextMatch?.venue != 'away',
      live: s.nextMatch?.live ?? false,
      matchAt: at(s.nextMatch?.scheduledAt),
      opensAt: at(s.opensAt),
      unlockCoins: s.unlockCoins,
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

final homeProvider = FutureProvider.autoDispose<HomeData>((ref) async => HomeData.fromJson(await ref.saved('/home')));
