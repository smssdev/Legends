import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../match/sim_source.dart';

/// [Sprint 64 F1] A new account plays its first match before anything else: set as the sign-up is sent, so the router
/// sends the new coach to /first-match instead of the home screen (and only once).
final firstMatchWantedProvider = NotifierProvider<FirstMatchWanted, bool>(FirstMatchWanted.new);

class FirstMatchWanted extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

/// The intro match's three moments, by the live screen's number for it (SimMatches.handle); none for any other match.
final introMomentsProvider = NotifierProvider<IntroMoments, Map<int, List<api.IntroMoment>>>(IntroMoments.new);

class IntroMoments extends Notifier<Map<int, List<api.IntroMoment>>> {
  @override
  Map<int, List<api.IntroMoment>> build() => const {};

  /// Asks the server for the intro match (B1) and keeps its moments; returns its screen number.
  Future<int> start() async {
    final intro = api.SimIntro.fromJson(await ref.read(apiProvider).post('/sim/intro'));
    final handle = SimMatches.handle(intro.id, null);
    state = {...state, handle: intro.intro.moments};
    return handle;
  }
}

/// The coach's answers in the intro match: the moments answered, and whether it is over (played to its end or skipped,
/// said once to the server).
typedef IntroCoachState = ({Set<String> answered, bool over});

final introCoachProvider = NotifierProvider.autoDispose.family<IntroCoach, IntroCoachState, int>(IntroCoach.new);

class IntroCoach extends Notifier<IntroCoachState> {
  IntroCoach(this.handle);

  final int handle;
  bool _told = false;

  @override
  IntroCoachState build() => (answered: const <String>{}, over: false);

  List<api.IntroMoment> get moments => ref.read(introMomentsProvider)[handle] ?? const [];

  /// The moment to show at this minute: the first one reached and not answered, one at a time.
  static api.IntroMoment? current(List<api.IntroMoment> moments, IntroCoachState s, int minute) {
    if (s.over) return null;
    for (final m in moments) {
      if (m.minute <= minute && !s.answered.contains(m.kind)) return m;
    }
    return null;
  }

  void answer(String kind) => state = (answered: {...state.answered, kind}, over: state.over);

  /// The match ended or was skipped: said once.
  Future<void> end() async {
    if (_told) return;
    _told = true;
    state = (answered: state.answered, over: true);
    try {
      await ref.read(apiProvider).post('/sim/intro/finished');
    } catch (_) {
      // The funnel misses one step; the coach goes on.
    }
  }

  /// «Take a club»: the starter gift given here (already taken or not offered, the way on is the same).
  Future<void> takeGift() async {
    try {
      await ref.read(apiProvider).post('/home/starter-gift');
    } catch (_) {
      // It waits on the home screen.
    }
  }
}
