import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';

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
    return n == null || s.length != 6 ? null : Color(0xFF000000 | n);
  }
}

class SimRepository {
  SimRepository(this._api);

  final ApiClient _api;

  /// The clubs, strongest first, matching [q] (the server answers a list).
  Future<List<SimClub>> clubs(String q) async {
    try {
      final r = await _api.dio.get<dynamic>('/sim/clubs', queryParameters: {if (q.trim().isNotEmpty) 'q': q.trim()});
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
}

final simRepositoryProvider = Provider<SimRepository>((ref) => SimRepository(ref.watch(apiProvider)));

final simClubsProvider = FutureProvider.autoDispose.family<List<SimClub>, String>((ref, q) => ref.read(simRepositoryProvider).clubs(q));
