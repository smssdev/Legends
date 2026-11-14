// [Sprint 67] The game's bots on Telegram and WhatsApp, opened straight from the site. Signed in and not linked yet,
// the chat opens with a fresh link code written in it (one tap on send links the account); linked, or a visitor, it
// opens as it is. The tab opens at the tap itself (before any request), so no browser takes it for a pop-up.
import { api, ensureCsrf } from '../api/client'

export type BotPlatform = 'telegram' | 'whatsapp'

export async function openBot(platform: BotPlatform, plain: string, signedIn: boolean): Promise<void> {
  const tab = window.open('', '_blank')
  if (tab) tab.opener = null
  let url = plain
  if (signedIn) {
    try {
      const status = (await api.GET('/messenger')).data
      if (status && !status[platform].linked) {
        await ensureCsrf()
        url = (await api.POST('/messenger/link', { body: { platform } })).data?.url ?? plain
      }
    } catch {
      // The plain chat still opens: the bot tells him how to link.
    }
  }
  if (tab) tab.location.href = url
  else window.location.href = url
}
