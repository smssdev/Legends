// RenderFrames from Keyframes [Sprint 21 E8.4, curved in Sprint 31 M1]: one rule for the cartoon player and Unity,
// checked against the golden vectors in docs/api/frame-golden.json (frames.test.ts, Vitest, in every build).
//
// A MatchMinute's Keyframes are evenly spaced over its scene. The progress u (0..1) comes from the match's
// clock (the minute's start `at` on the server clock), never from when the message arrived. u is clamped, so a
// minute whose next one is late holds its last Keyframe: no extrapolation.
//
// Between Keyframe i and i + 1 every coordinate follows a cubic Hermite curve (Catmull-Rom tangents from the
// Keyframes on both sides), limited so it never overshoots: each axis stays between its two Keyframes on every
// segment (a monotone curve, |tangent| <= 3 x the smaller neighbouring step, 0 at a turn). A long lofted ball
// (its next Keyframe in the air, 15 m or more away) rises on top of that in a parabola: the ball's arc.

export type Keyframe = { b: [number, number, number?]; p: Record<string, [number, number]>; r?: [number, number][] }

/** Where progress u falls among `count` Keyframes: between i and i + 1, k of the way (0..1). */
export function segment(count: number, u: number): { i: number; k: number } {
  if (count < 2) return { i: 0, k: 0 }
  const x = Math.min(1, Math.max(0, u)) * (count - 1)
  const i = Math.min(count - 2, Math.floor(x))
  return { i, k: x - i }
}

/** The tangent at `cur` from its neighbours (either may be missing): Catmull-Rom, limited so nothing overshoots. */
export function tangent(prev: number | undefined, cur: number, next: number | undefined): number {
  if (prev === undefined && next === undefined) return 0
  if (prev === undefined) return next! - cur
  if (next === undefined) return cur - prev
  const d0 = cur - prev,
    d1 = next - cur
  if (d0 * d1 <= 0) return 0
  const m = (d0 + d1) / 2,
    lim = 3 * Math.min(Math.abs(d0), Math.abs(d1))
  return Math.sign(m) * Math.min(Math.abs(m), lim)
}

/** One coordinate between a (at k 0) and b (at k 1), with the Keyframes before a and after b when there are any. */
export function curve(p: number | undefined, a: number, b: number, n: number | undefined, k: number): number {
  const ma = tangent(p, a, b),
    mb = tangent(a, b, n)
  const k2 = k * k,
    k3 = k2 * k
  return (2 * k3 - 3 * k2 + 1) * a + (k3 - 2 * k2 + k) * ma + (-2 * k3 + 3 * k2) * b + (k3 - k2) * mb
}

/** The ball's arc: a lofted ball (its next Keyframe in the air) over 15 m rises by its length / 10, at most 6 m. */
export const LOFT = { from: 150, per: 10, max: 60 }
export function loft(a: [number, number, number?], b: [number, number, number?]): number {
  if (!((b[2] ?? 0) > 0)) return 0
  const d = Math.hypot(b[0] - a[0], b[1] - a[1])
  return d < LOFT.from ? 0 : Math.min(LOFT.max, Math.floor(d / LOFT.per))
}

/** The RenderFrame at progress u: the ball (x, y, height) and every player's spot. Null with no Keyframes. */
export function sample(
  frames: Keyframe[],
  u: number,
): { ball: [number, number, number]; players: Record<string, [number, number]>; officials?: [number, number][] } | null {
  if (!frames.length) return null
  const { i, k } = segment(frames.length, u)
  const A = frames[i],
    B = frames[Math.min(frames.length - 1, i + 1)]
  const P = i > 0 ? frames[i - 1] : undefined,
    N = i + 2 < frames.length ? frames[i + 2] : undefined
  const players: Record<string, [number, number]> = {}
  for (const id in A.p) {
    const a = A.p[id],
      b = B.p[id]
    // A player in the first Keyframe only (sent off, replaced) stays where he was.
    if (!b || B === A) {
      players[id] = [a[0], a[1]]
      continue
    }
    const p = P?.p[id],
      n = N?.p[id]
    players[id] = [curve(p?.[0], a[0], b[0], n?.[0], k), curve(p?.[1], a[1], b[1], n?.[1], k)]
  }
  // [Sprint 31 D1] The referee and his assistants (r, when the server sends them) follow the same curve.
  const officials =
    A.r &&
    (B === A || !B.r
      ? A.r.map((o) => [o[0], o[1]] as [number, number])
      : A.r.map((a, n) => {
          const b = B.r![n],
            p = P?.r?.[n],
            q = N?.r?.[n]
          return [curve(p?.[0], a[0], b[0], q?.[0], k), curve(p?.[1], a[1], b[1], q?.[1], k)] as [number, number]
        }))
  if (B === A) return { ball: [A.b[0], A.b[1], A.b[2] ?? 0], players, ...(officials ? { officials } : {}) }
  const ball: [number, number, number] = [
    curve(P?.b[0], A.b[0], B.b[0], N?.b[0], k),
    curve(P?.b[1], A.b[1], B.b[1], N?.b[1], k),
    curve(P ? (P.b[2] ?? 0) : undefined, A.b[2] ?? 0, B.b[2] ?? 0, N ? (N.b[2] ?? 0) : undefined, k) + 4 * k * (1 - k) * loft(A.b, B.b),
  ]
  return { ball, players, ...(officials ? { officials } : {}) }
}
