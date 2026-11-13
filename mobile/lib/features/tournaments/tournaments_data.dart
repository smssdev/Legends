import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';

/// [Sprint 18 G] Tournaments (Sprint 29) and the alliance tournament (X27) in the app: my tournaments, a new one from
/// a template, its page (code, entry, groups), and its draw replayed on the server's clock, one ball every reveal_ms
/// from drawn_at, so every screen shows the same ball at the same moment. Picking teams one by one stays on the site.
/// [Sprint 59 F1] The tournaments through the generated model (`Tournament`).
final tournamentsProvider = FutureProvider.autoDispose<List<api.Tournament>>(
  (ref) async => JsonReader(await ref.read(apiProvider).get('/tournaments'), 'Tournaments').list('tournaments', api.Tournament.fromJson),
);

/// [Sprint 59 F1] The tournament catalog through the generated model (`TournamentsCatalogAnswer`).
final catalogProvider = FutureProvider.autoDispose<api.TournamentsCatalogAnswer>(
  (ref) async => api.TournamentsCatalogAnswer.fromJson(await ref.read(apiProvider).get('/tournaments/catalog')),
);

/// [Sprint 59 F1] A tournament's page through the generated model (`TournamentPageAnswer`).
final tournamentProvider = FutureProvider.autoDispose.family<api.TournamentPageAnswerTournament, int>(
  (ref, id) async => api.TournamentPageAnswer.fromJson(await ref.read(apiProvider).get('/tournaments/$id')).tournament,
);

/// [Sprint 59 F1] A tournament's live draw through the generated model (`TournamentsDrawAnswer`).
final drawProvider = FutureProvider.autoDispose.family<api.TournamentsDrawAnswer, int>(
  (ref, id) async => api.TournamentsDrawAnswer.fromJson(await ref.read(apiProvider).get('/tournaments/$id/draw')),
);

/// [Sprint 59 F1] The alliance tournament through the generated model (`AllianceAnswer`).
final allianceProvider = FutureProvider.autoDispose.family<api.AllianceAnswer, int>(
  (ref, id) async => api.AllianceAnswer.fromJson(await ref.read(apiProvider).get('/leagues/$id/alliance')),
);

String templateName(L l, String key) => switch (key) {
  'world_cup' => l.tplWorldCup,
  'world_cup_48' => l.tplWorldCup48,
  'club_world_cup' => l.tplClubWorldCup,
  'afcon' => l.tplAfcon,
  'euro' => l.tplEuro,
  'asian_cup' => l.tplAsianCup,
  _ => key,
};

/// A date and then a time, from the device's pickers; null when either is dismissed.
Future<DateTime?> pickWhen(BuildContext context, DateTime from) async {
  final day = await showDatePicker(context: context, firstDate: from, lastDate: from.add(const Duration(days: 60)), initialDate: from);
  if (day == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 21, minute: 0));
  if (time == null) return null;
  return DateTime(day.year, day.month, day.day, time.hour, time.minute);
}
