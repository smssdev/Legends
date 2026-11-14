import { beforeEach, describe, expect, it, vi } from 'vitest'

const leagues = vi.hoisted(() => ({ list: [] as { id: number; my_club_id: number | null }[] }))
vi.mock('../api/client', () => ({ api: { GET: vi.fn(async () => ({ data: { leagues: leagues.list } })) } }))

import { currentLeague, rememberLeague } from './currentLeague'

describe('currentLeague', () => {
  beforeEach(() => localStorage.clear())

  it('is the last league opened with a club, else the first with one, else none', async () => {
    leagues.list = [
      { id: 1, my_club_id: null },
      { id: 2, my_club_id: 20 },
      { id: 3, my_club_id: 30 },
    ]
    expect(await currentLeague()).toBe(2)
    rememberLeague(3)
    expect(await currentLeague()).toBe(3)
    rememberLeague(1)
    expect(await currentLeague()).toBe(2)
    leagues.list = []
    expect(await currentLeague()).toBeNull()
  })
})
