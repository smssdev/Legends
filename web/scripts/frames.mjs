// Checks the cartoon player's RenderFrame rule (src/match/frames.ts) against the golden vectors shared with Unity
// [Sprint 21 E8.4, curved in Sprint 31 M1]. Runs before every build: a change to the rule that breaks a vector fails the build.
import { readFileSync } from 'node:fs'
import { sample, segment } from '../src/match/frames.ts'

const golden = JSON.parse(readFileSync(new URL('../../docs/api/frame-golden.json', import.meta.url), 'utf8'))
const near = (a, b) => Math.abs(a - b) < 1e-6
const bad = []
for (const c of golden.segments) {
  const got = segment(c.count, c.u)
  if (got.i !== c.i || !near(got.k, c.k)) bad.push(`segment(${c.count}, ${c.u}) = ${JSON.stringify(got)}, expected i ${c.i} k ${c.k}`)
}
for (const c of golden.samples) {
  const got = sample(golden.frames, c.u)
  const want = [...c.ball, ...Object.values(c.players).flat()]
  const have = [...got.ball, ...Object.keys(c.players).flatMap((id) => got.players[id])]
  if (Object.keys(got.players).length !== Object.keys(c.players).length || want.length !== have.length || want.some((v, n) => !near(v, have[n]))) bad.push(`sample(u ${c.u}) = ${JSON.stringify(got)}`)
}
// [Sprint 31 M1] The curve never overshoots: on random paths every coordinate stays between its two Keyframes.
let seed = 7
const rnd = (n) => ((seed = (seed * 1103515245 + 12345) % 2147483648) % n)
for (let run = 0; run < 200; run++) {
  const fs = Array.from({ length: 6 }, () => ({ b: [rnd(1050), rnd(680), rnd(3) ? 0 : rnd(30)], p: { 1: [rnd(1050), rnd(680)] } }))
  for (let s = 0; s <= 100; s++) {
    const u = s / 100, { i } = segment(6, u), got = sample(fs, u), A = fs[i], B = fs[i + 1]
    const out = (v, a, b) => v < Math.min(a, b) - 1e-6 || v > Math.max(a, b) + 1e-6
    if (out(got.ball[0], A.b[0], B.b[0]) || out(got.ball[1], A.b[1], B.b[1]) || out(got.players[1][0], A.p[1][0], B.p[1][0]) || out(got.players[1][1], A.p[1][1], B.p[1][1]) || got.ball[2] < 0) bad.push(`overshoot in run ${run} at u ${u}`)
  }
}
if (bad.length) {
  console.error('frame-golden.json: the RenderFrame rule changed\n' + bad.join('\n'))
  process.exit(1)
}
console.log(`frame-golden.json: ${golden.segments.length + golden.samples.length} vectors match, no overshoot on 200 random paths`)
