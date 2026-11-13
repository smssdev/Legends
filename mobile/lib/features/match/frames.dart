import 'dart:math' as math;

import '../../api/gen/models.g.dart' as api;

/// [Sprint 17 F3] RenderFrames from Keyframes: the same rule as the web (`web/src/match/frames.ts`) and Unity
/// (`MatchScene.Sample`), checked against `docs/api/frame-golden.json` (test/frames_test.dart). A minute's Keyframes
/// are evenly spaced over its scene; between two of them each coordinate follows a cubic Hermite curve that never
/// overshoots, and a long lofted ball rises in a parabola on top. Drawing only: the server made every position.
typedef Point2 = (double, double);

class Keyframe {
  const Keyframe({required this.ball, required this.players, this.officials});

  /// [Sprint 59 F1] A live minute's Keyframe through its generated model (`Keyframe` in openapi.yaml).
  factory Keyframe.of(api.Keyframe k) {
    Point2 at(Object? v) => v is List<dynamic> && v.length > 1 ? ((v[0] as num).toDouble(), (v[1] as num).toDouble()) : (0, 0);
    double ball(int i) => i < k.b.length ? k.b[i].toDouble() : 0;
    return Keyframe(
      ball: (ball(0), ball(1), ball(2)),
      players: {for (final e in k.p.entries) e.key: at(e.value)},
      officials: k.r?.map(at).toList(),
    );
  }

  /// A recorded Keyframe (docs/api/frame-golden.json, without its place `t`).
  factory Keyframe.fromJson(Map<String, dynamic> j) {
    final b = (j['b'] as List<dynamic>).map((v) => (v as num).toDouble()).toList();
    return Keyframe(
      ball: (b[0], b[1], b.length > 2 ? b[2] : 0),
      players: {
        for (final e in (j['p'] as Map<dynamic, dynamic>).entries)
          '${e.key}': (((e.value as List<dynamic>)[0] as num).toDouble(), ((e.value as List<dynamic>)[1] as num).toDouble()),
      },
      officials: (j['r'] as List<dynamic>?)?.map((o) => (((o as List<dynamic>)[0] as num).toDouble(), (o[1] as num).toDouble())).toList(),
    );
  }

  final (double, double, double) ball;
  final Map<String, Point2> players;
  final List<Point2>? officials;
}

class RenderFrame {
  const RenderFrame(this.ball, this.players, [this.officials]);

  final (double, double, double) ball;
  final Map<String, Point2> players;
  final List<Point2>? officials;
}

/// Where progress u falls among `count` Keyframes: between i and i + 1, k of the way.
({int i, double k}) segment(int count, double u) {
  if (count < 2) return (i: 0, k: 0);
  final x = u.clamp(0.0, 1.0) * (count - 1);
  final i = math.min(count - 2, x.floor());
  return (i: i, k: x - i);
}

double tangent(double? prev, double cur, double? next) {
  if (prev == null && next == null) return 0;
  if (prev == null) return next! - cur;
  if (next == null) return cur - prev;
  final d0 = cur - prev, d1 = next - cur;
  if (d0 * d1 <= 0) return 0;
  final m = (d0 + d1) / 2, lim = 3 * math.min(d0.abs(), d1.abs());
  return m.sign * math.min(m.abs(), lim);
}

double curve(double? p, double a, double b, double? n, double k) {
  final ma = tangent(p, a, b), mb = tangent(a, b, n);
  final k2 = k * k, k3 = k2 * k;
  return (2 * k3 - 3 * k2 + 1) * a + (k3 - 2 * k2 + k) * ma + (-2 * k3 + 3 * k2) * b + (k3 - k2) * mb;
}

/// The ball's arc: a lofted ball over 15 m rises by its length / 10, at most 6 m.
double loft((double, double, double) a, (double, double, double) b) {
  if (!(b.$3 > 0)) return 0;
  final d = math.sqrt(math.pow(b.$1 - a.$1, 2) + math.pow(b.$2 - a.$2, 2));
  return d < 150 ? 0 : math.min(60, (d / 10).floorToDouble());
}

RenderFrame? sample(List<Keyframe> frames, double u) {
  if (frames.isEmpty) return null;
  final s = segment(frames.length, u);
  final i = s.i, k = s.k;
  final a = frames[i], b = frames[math.min(frames.length - 1, i + 1)];
  final p = i > 0 ? frames[i - 1] : null, n = i + 2 < frames.length ? frames[i + 2] : null;
  final players = <String, Point2>{};
  for (final e in a.players.entries) {
    final pa = e.value, pb = b.players[e.key];
    if (pb == null || identical(a, b)) {
      players[e.key] = pa;
      continue;
    }
    final pp = p?.players[e.key], pn = n?.players[e.key];
    players[e.key] = (curve(pp?.$1, pa.$1, pb.$1, pn?.$1, k), curve(pp?.$2, pa.$2, pb.$2, pn?.$2, k));
  }
  List<Point2>? officials;
  if (a.officials != null) {
    officials = identical(a, b) || b.officials == null
        ? [...a.officials!]
        : [
            for (var j = 0; j < a.officials!.length; j++)
              (
                curve(p?.officials?[j].$1, a.officials![j].$1, b.officials![j].$1, n?.officials?[j].$1, k),
                curve(p?.officials?[j].$2, a.officials![j].$2, b.officials![j].$2, n?.officials?[j].$2, k),
              ),
          ];
  }
  if (identical(a, b)) return RenderFrame(a.ball, players, officials);
  final ball = (
    curve(p?.ball.$1, a.ball.$1, b.ball.$1, n?.ball.$1, k),
    curve(p?.ball.$2, a.ball.$2, b.ball.$2, n?.ball.$2, k),
    curve(p?.ball.$3, a.ball.$3, b.ball.$3, n?.ball.$3, k) + 4 * k * (1 - k) * loft(a.ball, b.ball),
  );
  return RenderFrame(ball, players, officials);
}
