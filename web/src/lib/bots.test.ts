import { beforeEach, describe, expect, it, vi } from 'vitest'

const GET = vi.fn()
const POST = vi.fn()
vi.mock('../api/client', () => ({
  api: { GET: (...a: unknown[]) => GET(...a), POST: (...a: unknown[]) => POST(...a) },
  ensureCsrf: vi.fn(async () => {}),
}))

import { openBot } from './bots'

describe('openBot', () => {
  let tab: { opener: unknown; location: { href: string } }
  beforeEach(() => {
    GET.mockReset()
    POST.mockReset()
    tab = { opener: window, location: { href: '' } }
    vi.spyOn(window, 'open').mockReturnValue(tab as unknown as Window)
  })

  it('opens the chat with a link code for a signed-in coach not linked yet', async () => {
    GET.mockResolvedValue({ data: { telegram: { linked: false } } })
    POST.mockResolvedValue({ data: { url: 'https://t.me/GlmBot?start=AB3CDEFG' } })
    await openBot('telegram', 'https://t.me/GlmBot', true)
    expect(POST).toHaveBeenCalledWith('/messenger/link', { body: { platform: 'telegram' } })
    expect(tab.location.href).toBe('https://t.me/GlmBot?start=AB3CDEFG')
    expect(tab.opener).toBeNull()
  })

  it('opens the plain chat when linked, for a visitor, or when the request fails', async () => {
    GET.mockResolvedValue({ data: { whatsapp: { linked: true } } })
    await openBot('whatsapp', 'https://wa.me/1?text=hi', true)
    expect(POST).not.toHaveBeenCalled()
    expect(tab.location.href).toBe('https://wa.me/1?text=hi')

    await openBot('telegram', 'https://t.me/GlmBot', false)
    expect(GET).toHaveBeenCalledTimes(1)
    expect(tab.location.href).toBe('https://t.me/GlmBot')

    GET.mockRejectedValue(new Error('offline'))
    await openBot('telegram', 'https://t.me/GlmBot', true)
    expect(tab.location.href).toBe('https://t.me/GlmBot')
  })
})
