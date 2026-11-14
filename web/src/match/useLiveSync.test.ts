import { describe, expect, it, vi } from 'vitest'
import { nextTick, ref } from 'vue'

type Handler = (e: unknown) => void
const echo = vi.hoisted(() => {
  const channels: Record<string, { listeners: Record<string, Handler>; subscribed?: () => void; error?: () => void }> = {}
  const left: string[] = []
  return { channels, left }
})
vi.mock('../lib/echo', async () => {
  const { ref } = await import('vue')
  const liveState = ref('connected')
  return {
    liveState,
    live: () => ({
      leave: (n: string) => echo.left.push(n),
      private: (n: string) => {
        const c = (echo.channels[n] = { listeners: {} as Record<string, Handler> } as (typeof echo.channels)[string])
        const api = {
          subscribed: (f: () => void) => ((c.subscribed = f), api),
          error: (f: () => void) => ((c.error = f), api),
          listen: (ev: string, f: Handler) => ((c.listeners[ev] = f), api),
        }
        return api
      },
    }),
  }
})

import { liveState } from '../lib/echo'
import { useLiveSync } from './useLiveSync'

describe('useLiveSync', () => {
  it('joins the match’s channel, hands on its minutes, chat and reactions, and says when it is connected', async () => {
    const id = ref<number | null>(7)
    const on = { minute: vi.fn(), chat: vi.fn(), reaction: vi.fn(), rejoined: vi.fn() }
    const s = useLiveSync(id, on)
    const c = echo.channels['match.7']!
    expect(s.connected.value).toBe(false)
    c.subscribed!()
    expect(on.rejoined).toHaveBeenCalledOnce()
    expect(s.connected.value).toBe(true)
    c.listeners['.minute']!({ match_id: 7, live: { tick: 3 }, next_at: null })
    c.listeners['.minute']!({ match_id: 7 })
    c.listeners['.chat']!({ item: { id: 1 } })
    c.listeners['.reaction']!({ item: { id: 2 } })
    c.listeners['.chat']!({})
    expect([on.minute.mock.calls.length, on.chat.mock.calls.length, on.reaction.mock.calls.length]).toEqual([1, 1, 1])

    // The socket drops: the page polls until it is back.
    ;(liveState as { value: string }).value = 'disconnected'
    await nextTick()
    expect(s.connected.value).toBe(false)
    ;(liveState as { value: string }).value = 'connected'

    // Another match: the old channel is left.
    id.value = 8
    await nextTick()
    expect(echo.left).toContain('match.7')
    expect(echo.channels['match.8']).toBeDefined()
    echo.channels['match.8']!.error!()
    expect(s.connected.value).toBe(false)
    id.value = null
    await nextTick()
    expect(echo.left).toContain('match.8')
  })
})
