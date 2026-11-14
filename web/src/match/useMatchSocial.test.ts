import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ref } from 'vue'

let next = 100
vi.mock('../api/sim', () => ({
  sim: { react: async (_id: string, key: string) => ({ id: ++next, key, side: 'home' }) },
  leagueMatch: {
    react: async (_id: string, key: string, target?: string) => ({ id: ++next, key, target, who: 'me' }),
    chat: async (_id: string, body: string) => ({ id: ++next, body, who: 'me' }),
  },
}))

import { useMatchSocial } from './useMatchSocial'

describe('useMatchSocial', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => vi.useRealTimers())

  function make(league: boolean) {
    const show = vi.fn(),
      pop = vi.fn()
    const s = useMatchSocial({ league, id: '9', mine: ref('home' as const), show, pop, sideName: (side) => side.toUpperCase() })
    return { s, show, pop }
  }

  it('shows each reaction once, mine without the pop', async () => {
    const { s, show, pop } = make(false)
    s.receive({ id: 1, key: 'fire', side: 'away' } as any)
    s.receive({ id: 1, key: 'fire', side: 'away' } as any)
    expect(show).toHaveBeenCalledTimes(1)
    expect(show).toHaveBeenCalledWith('away', '🔥', '', 'AWAY')
    expect(pop).toHaveBeenCalledTimes(1)
    await s.react('clap')
    expect(show).toHaveBeenLastCalledWith('home', '👏', '', 'أنت')
    expect(pop).toHaveBeenCalledTimes(1)
  })

  it('a cheer for one side, then half a minute before the next', async () => {
    const { s, show } = make(true)
    await s.react('cheer', 'away')
    expect(show).toHaveBeenLastCalledWith('away', '📣', 'تشجيع', 'أنت')
    expect(s.cheerLeft.value).toBe(30)
    vi.advanceTimersByTime(30_000)
    expect(s.cheerLeft.value).toBe(0)
  })

  it('the chat keeps each line once and the last fifty', async () => {
    const { s } = make(true)
    for (let i = 0; i < 60; i++) s.hear({ id: i, body: 'x', who: 'a' } as any)
    s.hear({ id: 59, body: 'x', who: 'a' } as any)
    expect(s.chat.value).toHaveLength(50)
    s.chatText.value = '  hello '
    await s.sendChat()
    expect(s.chat.value[s.chat.value.length - 1]?.body).toBe('hello')
    expect(s.chatText.value).toBe('')
  })
})
