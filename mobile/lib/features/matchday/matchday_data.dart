import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../club/squad_screen.dart' show money;

/// [Sprint 18 I] The club's match-day panels in the app (the web's NextMatch, Contracts and Tickets panels): moving
/// the next match by hours with the other coach's yes (Sprint 27 B2), the press conference (UP12), what goes on behind
/// the scenes (X28: the referee, a security check, the spies), the contracts (X61 E1) and the cheer tickets (X25).
/// [Sprint 59 F1] My next match through the generated model (`NextMatch`).
final nextMatchProvider = FutureProvider.autoDispose.family<api.NextMatch?, int>(
  (ref, l) async => JsonReader(
    await ref.read(apiProvider).get('/leagues/$l/team/next-match'),
    'NextMatchAnswer',
  ).objectOrNull('match', api.NextMatch.fromJson),
);

/// [Sprint 59 F1] The press conference through the generated model (`PressConference`).
final pressProvider = FutureProvider.autoDispose.family<api.PressConference?, (int, int)>(
  (ref, k) async => JsonReader(
    await ref.read(apiProvider).get('/leagues/${k.$1}/press/${k.$2}'),
    'PressAnswer',
  ).objectOrNull('press', api.PressConference.fromJson),
);

/// [Sprint 59 F1] The integrity system through the generated model (`IntegrityAnswer`).
final integrityProvider = FutureProvider.autoDispose.family<api.IntegrityAnswer, int>(
  (ref, l) async => api.IntegrityAnswer.fromJson(await ref.read(apiProvider).get('/leagues/$l/integrity')),
);

/// [Sprint 59 F1] The contracts through the generated model (`Contracts`).
final contractsProvider = FutureProvider.autoDispose.family<api.Contracts, int>(
  (ref, l) async => api.Contracts.fromJson(await ref.read(apiProvider).get('/leagues/$l/team/contracts')),
);

/// [Sprint 59 F1] The matches I missed through the generated model (`MissedMatch`).
final missedProvider = FutureProvider.autoDispose.family<List<api.MissedMatch>, int>(
  (ref, l) async =>
      JsonReader(await ref.read(apiProvider).get('/leagues/$l/team/missed'), 'Missed').list('matches', api.MissedMatch.fromJson),
);

/// [Sprint 59 F1] The cheer tickets through the generated model (`TicketsAnswer`).
final ticketsProvider = FutureProvider.autoDispose.family<api.TicketsAnswer, int>(
  (ref, l) async => api.TicketsAnswer.fromJson(await ref.read(apiProvider).get('/leagues/$l/tickets')),
);

/// A price as the server gives it (its currency and amount): coins or club money.
String price(BuildContext context, String currency, int amount) =>
    currency == 'coins' ? L.of(context).coinsWord(amount) : money(context, amount);

/// The referee's strictness in the coach's language.
String refereeName(L l, String strictness) => switch (strictness) {
  'very_lenient' => l.refereeVeryLenient,
  'lenient' => l.refereeLenient,
  'strict' => l.refereeStrict,
  'very_strict' => l.refereeVeryStrict,
  _ => l.refereeMedium,
};
