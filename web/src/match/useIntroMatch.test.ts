import { describe, expect, it, vi } from 'vitest'
import { nextTick, ref } from 'vue'
import { keepIntroMoments, useIntroMatch } from './useIntroMatch'

const moments = [
  { kind: 'style' as const, minute: 20, title: 'a', text: 'a' },
  { kind: 'effect' as const, minute: 28, title: 'b', text: 'b' },
  { kind: 'sub' as const, minute: 60, title: 'c', text: 'c' },
]

describe('useIntroMatch', () => {
  it('shows each moment from its minute until answered, one at a time, and tells the end once', async () => {
    keepIntroMoments('m1', moments)
    const minute = ref(0)
    const finished = ref(false)
    const done = vi.fn(() => Promise.resolve())
    const i = useIntroMatch({ id: 'm1', minute, finished, done })
    expect(i.on.value).toBe(true)
    expect(i.current.value).toBeNull()
    minute.value = 30
    expect(i.current.value?.kind).toBe('style')
    i.answer()
    expect(i.current.value?.kind).toBe('effect')
    i.answer()
    expect(i.current.value).toBeNull()
    minute.value = 61
    expect(i.current.value?.kind).toBe('sub')
    finished.value = true
    await nextTick()
    expect(done).toHaveBeenCalledTimes(1)
    expect(i.current.value).toBeNull()
    await i.skip()
    expect(done).toHaveBeenCalledTimes(1)
  })

  it('is off for any other match', () => {
    const i = useIntroMatch({ id: 'other', minute: ref(50), finished: ref(false), done: () => Promise.resolve() })
    expect(i.on.value).toBe(false)
    expect(i.current.value).toBeNull()
  })
})
