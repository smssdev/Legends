import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';

/// [Sprint 18 F] The account and the community in the app: my account (name, look, password, invites, badges), a
/// league's stats, the ideas and polls (Sprint 28), support, the developers' announcements and the guide (X59).
/// [Sprint 59 F1] My account and my badges through their generated models (`Account`).
final meProvider = FutureProvider.autoDispose<api.Account>(
  (ref) async => JsonReader(await ref.read(apiProvider).get('/auth/me'), 'Me').object('user', api.Account.fromJson),
);

final achievementsProvider = FutureProvider.autoDispose<List<api.HomeAchievementsAnswerAchievementsItem>>(
  (ref) async => api.HomeAchievementsAnswer.fromJson(await ref.read(apiProvider).get('/home/achievements')).achievements,
);

/// [Sprint 59 F1] A league's numbers, support, announcements and the guide through their generated models.
final statsProvider = FutureProvider.autoDispose.family<api.LeagueStats, int>(
  (ref, l) async => api.LeagueStats.fromJson(await ref.read(apiProvider).get('/leagues/$l/stats')),
);

/// [Sprint 59 F1] The ideas page through the generated model (`IdeasAnswer`).
final ideasProvider = FutureProvider.autoDispose<api.IdeasAnswer>(
  (ref) async => api.IdeasAnswer.fromJson(await ref.read(apiProvider).get('/ideas')),
);

final supportProvider = FutureProvider.autoDispose<List<api.SupportMessage>>(
  (ref) async => api.SupportAnswer.fromJson(await ref.read(apiProvider).get('/support')).messages,
);

final announcementsProvider = FutureProvider.autoDispose<List<api.AnnouncementCard>>(
  (ref) async => api.AnnouncementsAnswer.fromJson(await ref.read(apiProvider).get('/announcements')).announcements,
);

/// [Sprint 59 F1] The coaches' ranking through the generated model (`RankedCoach`).
final rankingProvider = FutureProvider.autoDispose<List<api.RankedCoach>>(
  (ref) async => api.RankingsCoachesAnswer.fromJson(await ref.read(apiProvider).get('/rankings/coaches')).coaches,
);

final guideProvider = FutureProvider.autoDispose<List<api.GuideSection>>(
  (ref) async => api.GuideAnswer.fromJson(await ref.read(apiProvider).get('/guide')).sections,
);
