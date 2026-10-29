// Checks the cartoon player's RenderFrame rule (src/match/frames.ts) against the golden vectors shared with Unity
// [Sprint 21 E8.4]. Runs before every build: a change to the rule that breaks a vector fails the build.
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
if (bad.length) {
  console.error('frame-golden.json: the RenderFrame rule changed\n' + bad.join('\n'))
  process.exit(1)
}
console.log(`frame-golden.json: ${golden.segments.length + golden.samples.length} vectors match`)
