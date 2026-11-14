import { afterEach, describe, expect, it } from 'vitest'
import { nextTick } from 'vue'
import { setThemePref, theme, themePref } from './theme'

describe('theme', () => {
  afterEach(() => setThemePref('auto'))

  it('puts the day on the page’s root and the bar’s colour, and keeps the choice', async () => {
    const meta = document.createElement('meta')
    meta.name = 'theme-color'
    document.head.append(meta)
    // The test's device may prefer light already: from the night first, so the change is seen.
    setThemePref('dark')
    await nextTick()
    setThemePref('light')
    await nextTick()
    expect(theme.value).toBe('light')
    expect(document.documentElement.classList.contains('light')).toBe(true)
    expect(meta.getAttribute('content')).toBe('#EFEADF')
    expect(localStorage.getItem('glm.theme')).toBe('light')
    setThemePref('dark')
    await nextTick()
    expect(document.documentElement.classList.contains('light')).toBe(false)
    expect(meta.getAttribute('content')).toBe('#0B1A2C')
    setThemePref('auto')
    expect(themePref.value).toBe('auto')
  })
})
