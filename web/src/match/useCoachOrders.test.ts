import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ref } from 'vue'

const order = vi.fn(async () => ({ target_tick: 12 }))
vi.mock('../api/sim', () => ({
  sim: { order: (...a: unknown[]) => order(...(a as [])) },
  leagueMatch: { order: (...a: unknown[]) => order(...(a as [])), mine: async () => [] },
}))
vi.mock('../api/client', () => ({
  api: {
    GET: async () => ({
      data: {
        orders: [
          { label: 'هجوم', hint: 'h', tactics: { style: 80 } },
          { label: 'عودة للخطة', hint: 'h', tactics: null },
        ],
      },
    }),
  },
}))

import { useCoachOrders } from './useCoachOrders'

const team = (tactics: Record<string, unknown>) =>
  ({ tactics, players: [], formation: '4-4-2', subs_used: 0, subs_max: 5, stats: {} }) as any

describe('useCoachOrders', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    order.mockClear()
  })
  afterEach(() => vi.useRealTimers())

  function make() {
    const teams = ref({ home: team({ plan: 'passing', style: 50, pressing: 50 }), away: team({}) })
    return useCoachOrders({ league: false, id: '7', mine: ref('home' as const), teams, finished: ref(false), error: ref('') })
  }

  it("sends only what changed in the tactics, and the plan to come back to is the coach's own", async () => {
    const o = make()
    o.adopt(true)
    await o.loadQuick()
    expect(o.quickOrders.value[1].tactics).toEqual({ plan: 'passing', style: 50, pressing: 50 })
    o.draft.style = 70
    o.applyDraft()
    expect(order).toHaveBeenCalledWith('7', { team: 'home', type: 'tactics', tactics: { style: 70 } })
  })

  it('an order waits for its minute, shows applied for 4 s, and refusals show as they come', async () => {
    const o = make()
    await o.sendFormation('custom:3-5-2')
    expect(o.pending.value.map((p) => [p.label, p.target])).toEqual([['الطريقة خاصة 3-5-2', 12]])
    o.settle({ tick: 11, rejected: [] } as any, "11'")
    expect(o.pending.value).toHaveLength(1)
    o.settle({ tick: 12, rejected: [{ reason: 'no_subs_left' }, { reason: 'odd' }] } as any, "12'")
    expect(o.pending.value).toHaveLength(0)
    expect(o.applied.value.map((a) => a.minute)).toEqual(["12'"])
    expect(o.rejected.value).toEqual(['رُفض الأمر: لا تبديلات متبقية', 'رُفض الأمر: odd'])
    vi.advanceTimersByTime(4000)
    expect(o.applied.value).toHaveLength(0)
  })
})
