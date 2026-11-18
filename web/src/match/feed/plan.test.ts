// [Sprint 09 G1] The minute's timeline (plan.ts) and the director's golden vectors shared with Unity
// (docs/api/director-golden.json): the cartoon must still give every case, or the vectors are written again
// (node scripts/director-golden.mjs) with Unity's port (Shots/MinutePlan.cs) in the same PR.
import { describe, expect, it } from 'vitest'
import golden from '../../../../docs/api/director-golden.json'
import sample from '../../../../docs/api/samples/liverpool-arsenal-48213.json'
import { cases } from './golden'
import { planMinute } from './plan'

describe('planMinute', () => {
  const goal = { scene: 'goal', side: 'home' as const, goal: true, data: {} }

  it('gives a goal its scene, the director’s cutaways and a slow replay in a long minute', () => {
    const p = planMinute(goal, { tick: 20, moment: { ms: 20000 } }, { tier: 'high' })
    expect(p.sceneT).toBe(6)
    expect(p.cuts.map((c) => c.name)).toEqual(['crowd', 'coachReact', 'coachReact'])
    expect(p.replay).not.toBeNull()
    expect(p.replay!.rate).toBeGreaterThanOrEqual(0.4)
  })

  it('squeezes the scene into nine tenths of a live minute, with no room for a replay', () => {
    const p = planMinute(goal, { tick: 20, moment: { ms: 3300 } }, { tier: 'high' })
    expect(p.sceneT).toBeCloseTo(3.3 * 0.9)
    expect(p.rate).toBeCloseTo(6 / (3.3 * 0.9))
    expect(p.replay).toBeNull()
  })

  it('drops the replay in the smooth mode and has no scene for a quiet minute', () => {
    expect(planMinute(goal, { tick: 20, moment: { ms: 20000 } }, { tier: 'high', smooth: true }).replay).toBeNull()
    const quiet = planMinute({ scene: null, side: 'home', goal: false, data: {} }, { tick: 3 }, { tier: 'high' })
    expect(quiet).toMatchObject({ total: 3, sceneT: 0, cuts: [], rate: 1, replay: null })
  })
})

describe('the director’s golden vectors', () => {
  it('are still what the cartoon gives, case for case', () => {
    const now = cases(sample as never)
    const file = (golden as { cases: unknown[] }).cases
    expect(now.length).toBe(file.length)
    now.forEach((c, i) => expect(JSON.parse(JSON.stringify(c)), `case ${i}`).toEqual(file[i]))
  })
})
