// [Sprint 21 E8.4, Sprint 31 M1, Sprint 66 T4] The cartoon player's RenderFrame rule (frames.ts) against the golden
// vectors shared with Unity (docs/api/frame-golden.json; these checks were scripts/frames.mjs). A change to the rule is
// written in frames.ts, frame-golden.json and Unity's MatchScene.cs together.
import { describe, expect, it } from 'vitest'
import golden from '../../../docs/api/frame-golden.json'
import { curve, loft, sample, segment, tangent, type Keyframe } from './frames'

type Golden = {
  segments: { count: number; u: number; i: number; k: number }[]
  frames: Keyframe[]
  samples: { u: number; ball: number[]; players: Record<string, number[]> }[]
}
const g = golden as unknown as Golden

describe('RenderFrames', () => {
  it('finds the segment of every golden progress', () => {
    for (const c of g.segments) {
      const got = segment(c.count, c.u)
      expect(got.i, `segment(${c.count}, ${c.u})`).toBe(c.i)
      expect(got.k).toBeCloseTo(c.k, 6)
    }
    expect(segment(1, 0.5)).toEqual({ i: 0, k: 0 })
  })

  it('samples every golden vector', () => {
    for (const c of g.samples) {
      const got = sample(g.frames, c.u)!
      expect(Object.keys(got.players).sort(), `u ${c.u}`).toEqual(Object.keys(c.players).sort())
      got.ball.forEach((v, n) => expect(v, `ball at u ${c.u}`).toBeCloseTo(c.ball[n]!, 6))
      for (const [id, spot] of Object.entries(c.players)) spot.forEach((v, n) => expect(got.players[id]![n]).toBeCloseTo(v, 6))
    }
    expect(sample([], 0.5)).toBeNull()
  })

  it('never overshoots: on random paths every coordinate stays between its two Keyframes', () => {
    let seed = 7
    const rnd = (n: number) => (seed = (seed * 1103515245 + 12345) % 2147483648) % n
    for (let run = 0; run < 200; run++) {
      const fs: Keyframe[] = Array.from({ length: 6 }, () => ({
        b: [rnd(1050), rnd(680), rnd(3) ? 0 : rnd(30)],
        p: { 1: [rnd(1050), rnd(680)] },
      }))
      for (let s = 0; s <= 100; s++) {
        const u = s / 100
        const { i } = segment(6, u)
        const got = sample(fs, u)!
        const [A, B] = [fs[i]!, fs[i + 1]!]
        const inside = (v: number, a: number, b: number) => v >= Math.min(a, b) - 1e-6 && v <= Math.max(a, b) + 1e-6
        expect(inside(got.ball[0], A.b[0], B.b[0]) && inside(got.ball[1], A.b[1], B.b[1]), `run ${run} u ${u}`).toBe(true)
        expect(inside(got.players[1]![0], A.p[1]![0], B.p[1]![0]) && inside(got.players[1]![1], A.p[1]![1], B.p[1]![1])).toBe(true)
        expect(got.ball[2]).toBeGreaterThanOrEqual(0)
      }
    }
  })

  it('moves the officials on the very curve the players follow', () => {
    const fs = g.frames.map((f) => ({ ...f, r: f.p[7] ? [f.p[7], f.p[7], f.p[7]] : undefined }))
    for (const u of [0, 0.1, 0.33, 0.5, 0.75, 1]) {
      const got = sample(fs, u)!
      if (!got.officials || !got.players[7]) continue
      for (const o of got.officials) {
        expect(o[0]).toBeCloseTo(got.players[7][0], 6)
        expect(o[1]).toBeCloseTo(got.players[7][1], 6)
      }
    }
  })

  it('keeps its pieces: flat tangents at a turn, a lofted ball’s arc', () => {
    expect(tangent(undefined, 5, undefined)).toBe(0)
    expect(tangent(0, 10, 0)).toBe(0)
    expect(tangent(0, 10, 20)).toBe(10)
    expect(curve(undefined, 0, 10, undefined, 0)).toBe(0)
    expect(curve(undefined, 0, 10, undefined, 1)).toBe(10)
    expect(loft([0, 0, 0], [300, 0, 0])).toBe(0)
    expect(loft([0, 0, 0], [100, 0, 5])).toBe(0)
    expect(loft([0, 0, 0], [300, 0, 5])).toBe(30)
    expect(loft([0, 0, 0], [1000, 0, 5])).toBe(60)
  })
})
