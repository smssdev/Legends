// RenderFrames from Keyframes [Sprint 21 E8.4]: one rule for the cartoon player and Unity, checked against the
// golden vectors in docs/api/frame-golden.json (scripts/frames.mjs, in every build).
//
// A MatchMinute's Keyframes are evenly spaced over its scene. The progress u (0..1) comes from the match's
// clock (the minute's start `at` on the server clock), never from when the message arrived. u is clamped, so a
// minute whose next one is late holds its last Keyframe: no extrapolation.

export type Keyframe = { b: [number, number, number?]; p: Record<string, [number, number]> }

/** Where progress u falls among `count` Keyframes: between i and i + 1, k of the way (0..1). */
export function segment(count: number, u: number): { i: number; k: number } {
  if (count < 2) return { i: 0, k: 0 }
  const x = Math.min(1, Math.max(0, u)) * (count - 1)
  const i = Math.min(count - 2, Math.floor(x))
  return { i, k: x - i }
}

const lerp = (a: number, b: number, k: number) => a + (b - a) * k

/** The RenderFrame at progress u: the ball (x, y, height) and every player's spot. Null with no Keyframes. */
export function sample(frames: Keyframe[], u: number): { ball: [number, number, number]; players: Record<string, [number, number]> } | null {
  if (!frames.length) return null
  const { i, k } = segment(frames.length, u)
  const A = frames[i], B = frames[Math.min(frames.length - 1, i + 1)]
  const players: Record<string, [number, number]> = {}
  // A player in the first Keyframe only (sent off, replaced) stays where he was.
  for (const id in A.p) { const a = A.p[id], b = B.p[id] ?? a; players[id] = [lerp(a[0], b[0], k), lerp(a[1], b[1], k)] }
  return { ball: [lerp(A.b[0], B.b[0], k), lerp(A.b[1], B.b[1], k), lerp(A.b[2] ?? 0, B.b[2] ?? 0, k)], players }
}
