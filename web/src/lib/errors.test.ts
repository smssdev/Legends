import { afterEach, describe as group, expect, it, vi } from 'vitest'
import { describe, ignored, report, resetErrors, shouldSend } from './errors'

group('errors', () => {
  afterEach(() => {
    resetErrors()
    vi.restoreAllMocks()
  })

  it('lets the same error through once a minute', () => {
    const seen = new Map<string, number>()
    expect(shouldSend('a', 0, seen)).toBe(true)
    expect(shouldSend('a', 59_000, seen)).toBe(false)
    expect(shouldSend('b', 59_000, seen)).toBe(true)
    expect(shouldSend('a', 60_000, seen)).toBe(true)
  })

  it('describes an error without the query of its path', () => {
    const d = describe(new TypeError('x is undefined'), '/leagues/4/match?tab=chat')
    expect(d).toMatchObject({ platform: 'web', version: 'web-test', path: '/leagues/4/match', message: 'TypeError: x is undefined' })
    expect(describe('boom', '/').message).toBe('boom')
    expect(describe({ code: 1 }, '/').message).toBe('{"code":1}')
  })

  it('sends with no cookie, and twenty a visit at most', () => {
    const fetch = vi.fn(() => Promise.resolve(new Response(null, { status: 204 })))
    vi.stubGlobal('fetch', fetch)
    for (let i = 0; i < 30; i++) report(new Error(`e${i}`), '/club')
    expect(fetch).toHaveBeenCalledTimes(20)
    const [url, init] = fetch.mock.calls[0] as unknown as [string, RequestInit]
    expect(url).toBe('/api/v1/client-errors')
    expect(init.credentials).toBe('omit')
    expect(JSON.parse(String(init.body))).toMatchObject({ platform: 'web', path: '/club', message: 'Error: e0' })
  })

  it('leaves out what is not our code', () => {
    expect(ignored(new Error('ResizeObserver loop limit exceeded'))).toBe(true)
    expect(ignored(new DOMException('aborted', 'AbortError'))).toBe(true)
    expect(ignored(new TypeError('Failed to fetch'))).toBe(true)
    expect(ignored(new TypeError('x is undefined'))).toBe(false)
  })
})
