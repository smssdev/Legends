import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const patch = vi.hoisted(() => vi.fn())
vi.mock('../api/client', () => ({ api: { PATCH: patch } }))

import { useAuth } from '../stores/auth'
import { useViewing } from './viewing'

describe('viewing', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    patch.mockReset()
  })

  it('plays the cartoon until Unity is ready, whatever was chosen', async () => {
    const v = useViewing()
    expect([v.chosenView.value, v.playing.value, v.coachLook.value]).toEqual(['cartoon', 'cartoon', 'C1'])
    await v.save({ match_view: 'unity' })
    expect(v.chosenView.value).toBe('unity')
    expect(v.playing.value).toBe('cartoon')
    expect(localStorage.getItem('glm.matchView')).toBe('unity')
    expect(patch).not.toHaveBeenCalled()
  })

  it('follows the account once signed in, and saves there', async () => {
    const auth = useAuth()
    auth.set({ id: 1, name: 'x', viewing: { match_view: 'unity', unity_ready: true, coach_look: 'C3' } } as never)
    const v = useViewing()
    expect([v.playing.value, v.coachLook.value]).toEqual(['unity', 'C3'])
    patch.mockResolvedValue({
      data: { user: { id: 1, name: 'x', viewing: { match_view: 'cartoon', unity_ready: true, coach_look: 'C2' } } },
    })
    await v.save({ coach_look: 'C2' })
    expect(patch).toHaveBeenCalledWith('/auth/me', { body: { coach_look: 'C2' } })
    expect([v.playing.value, v.coachLook.value]).toEqual(['cartoon', 'C2'])
  })
})
