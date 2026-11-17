import { afterEach, describe, expect, it, vi } from 'vitest'
import { locale } from './i18n'
import { clubsNamed, cn, ln, loadNames, natn, nm, pn, setNamesLang, shownNames } from './names'

describe('names', () => {
  afterEach(() => {
    locale.value = 'ar'
    setNamesLang('ar')
  })

  it('gives the Arabic names from the dictionary, players always in Latin', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(
        async () =>
          new Response(
            JSON.stringify({
              leagues: { 'Premier League': 'الدوري الإنجليزي' },
              clubs: { Liverpool: 'ليفربول' },
              players: {},
              nations: { Belgium: 'بلجيكا' },
            }),
          ),
      ),
    )
    await loadNames()
    expect([cn('Liverpool'), ln('Premier League'), natn('Belgium'), pn('Mohamed Salah')]).toEqual([
      'ليفربول',
      'الدوري الإنجليزي',
      'بلجيكا',
      'Mohamed Salah',
    ])
    expect([nm('Liverpool'), nm('Premier League'), nm('Belgium'), nm('Unknown FC'), nm(null)]).toEqual([
      'ليفربول',
      'الدوري الإنجليزي',
      'بلجيكا',
      'Unknown FC',
      '',
    ])
  })

  it('keeps the Latin names by the coach’s choice, and always in the English game', () => {
    setNamesLang('en')
    expect(shownNames.value).toBe('en')
    expect(cn('Liverpool')).toBe('Liverpool')
    expect(localStorage.getItem('glm.names')).toBe('en')
    setNamesLang('ar')
    locale.value = 'en'
    expect(nm('Liverpool')).toBe('Liverpool')
  })

  // [X109] The server stores the Latin names only: an Arabic search is sent with the Latin names it matches.
  it('finds the Latin names of the clubs an Arabic search names', async () => {
    expect(await clubsNamed('ليفر')).toEqual(['Liverpool'])
    expect(await clubsNamed('ليفربول', 0)).toEqual([])
    expect(await clubsNamed('Liver')).toEqual([])
    expect(await clubsNamed('برشلونة')).toEqual([])
  })
})
