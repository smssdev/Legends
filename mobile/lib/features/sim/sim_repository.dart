import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/config.dart';

/// A club the simulator can field (the data's clubs, the national teams left out by the server).
class SimClub {
  const SimClub({required this.id, required this.name, required this.code, this.league, this.strength, this.logo, this.color});

  /// [Sprint 59 F1] From the generated model (`ClubSummary` in openapi.yaml).
  factory SimClub.of(api.ClubSummary c) => SimClub(
    id: c.id ?? 0,
    name: c.name ?? '',
    code: c.code ?? '',
    league: c.leagueName,
    strength: c.strengthCp,
    logo: c.logo,
    color: _hex(c.colorPrimary),
  );

  final int id;
  final String name, code;
  final String? league, logo;
  final int? strength;
  final Color? color;

  static Color? _hex(Object? v) {
    final s = '${v ?? ''}'.replaceFirst('#', '');
    final n = int.tryParse(s, radix: 16);
    return n == null || s.length != 6 ? null : Color(n).withAlpha(255);
  }
}

class SimRepository {
  SimRepository(this._api);

  final ApiClient _api;

  /// The clubs' Arabic names by their Latin ones: the site's names dictionary, fetched once (null: not had yet).
  Future<Map<String, String>>? _arabic;

  /// The clubs, strongest first, matching [q] (the server answers a list).
  ///
  /// [X109] The server stores the Latin names only: an Arabic search also sends the Latin names whose Arabic, in the
  /// site's names dictionary (web/public/names/ar.json), holds it, as the site does (clubsNamed in lib/names.ts).
  Future<List<SimClub>> clubs(String q) async {
    try {
      final term = q.trim();
      final names = hasArabic(term) ? clubsNamed(await _arabicNames(), term) : const <String>[];
      final r = await _api.dio.get<dynamic>(
        '/sim/clubs',
        queryParameters: {if (term.isNotEmpty) 'q': term, if (names.isNotEmpty) 'names[]': names},
      );
      return [for (final c in (r.data as List<dynamic>? ?? const [])) SimClub.of(api.ClubSummary.fromJson(c))];
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// A match against the computer (solo: the coach holds home), or against a friend (live: two seats, home here and
  /// away in the friend's link).
  ///
  /// [Sprint 59 F1] The match's id is a ULID (a string): read as an int, as it was, creating a match always failed.
  Future<({String id, String? home, String? away})> create({required SimClub me, required SimClub them, required bool friend}) async {
    final j = await _api.post('/sim/matches', {
      'home_id': me.id,
      'away_id': them.id,
      'mode': friend ? 'live' : 'solo',
      'control': {'home': 'me', 'away': friend ? 'me' : 'cpu'},
    });
    // Only what the app needs of the match (MatchView): its id and the two seats.
    final r = JsonReader(j, 'SimCreated');
    final seats = r.objectOrNull('seats', api.MatchViewSeats.fromJson);
    return (id: r.string('id'), home: seats?.home, away: seats?.away);
  }

  /// The dictionary's clubs; without it (no network, an old server) the search is the Latin one alone.
  Future<Map<String, String>> _arabicNames() => _arabic ??= () async {
    try {
      final r = await _api.dio.get<dynamic>('${AppConfig.siteUrl}/names/ar.json');
      final data = r.data is String ? jsonDecode(r.data as String) : r.data;
      final clubs = data is Map ? data['clubs'] : null;
      return clubs is Map ? {for (final e in clubs.entries) '${e.key}': '${e.value}'} : <String, String>{};
    } catch (_) {
      _arabic = null; // tried again on the next search
      return <String, String>{};
    }
  }();
}

final simRepositoryProvider = Provider<SimRepository>((ref) => SimRepository(ref.watch(apiProvider)));

final simClubsProvider = FutureProvider.autoDispose.family<List<SimClub>, String>((ref, q) => ref.read(simRepositoryProvider).clubs(q));

/// [X109] Whether a search is written in Arabic letters.
bool hasArabic(String q) => RegExp('[\u0600-\u06FF]').hasMatch(q);

/// [X109] One spelling for a search: no diacritics or tatweel, the alefs, taa marbuta and alef maqsura as one.
String foldArabic(String s) => s
    .replaceAll(RegExp('[\u064B-\u0652\u0640]'), '')
    .replaceAll(RegExp('[\u0623\u0625\u0622]'), '\u0627')
    .replaceAll('\u0629', '\u0647')
    .replaceAll('\u0649', '\u064A')
    .toLowerCase()
    .trim();

/// [X109] The Latin names of the clubs whose Arabic name (in [arabic], by Latin name) holds [q], at most [max].
List<String> clubsNamed(Map<String, String> arabic, String q, {int max = 60}) {
  if (!hasArabic(q)) return const [];
  final want = foldArabic(q);
  final out = <String>[];
  for (final e in arabic.entries) {
    if (out.length >= max) break;
    if (foldArabic(e.value).contains(want)) out.add(e.key);
  }
  return out;
}
