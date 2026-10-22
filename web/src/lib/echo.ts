// Live updates over Reverb [CLAUDE.md: Reverb, Echo in the web]. One connection for the whole app.
// Match channels are private to the league's members; "system" is public (the test ping).
import Echo from 'laravel-echo'
import Pusher from 'pusher-js'
import { ref } from 'vue'
import { ensureCsrf } from '../api/client'

const xsrf = () => decodeURIComponent(document.cookie.match(/(?:^|; )XSRF-TOKEN=([^;]*)/)?.[1] ?? '')

declare global {
  interface Window {
    Pusher: typeof Pusher
  }
}

export type LiveState = 'connecting' | 'connected' | 'unavailable' | 'failed' | 'disconnected'
export const liveState = ref<LiveState>('connecting')

let echo: Echo<'reverb'> | null = null

export function live(): Echo<'reverb'> {
  if (echo) return echo
  window.Pusher = Pusher
  const env = import.meta.env
  const scheme = env.VITE_REVERB_SCHEME ?? location.protocol.replace(':', '')
  echo = new Echo({
    broadcaster: 'reverb',
    key: env.VITE_REVERB_APP_KEY ?? 'legends-dev-key',
    wsHost: env.VITE_REVERB_HOST ?? location.hostname,
    wsPort: Number(env.VITE_REVERB_PORT ?? 8080),
    wssPort: Number(env.VITE_REVERB_PORT ?? 443),
    forceTLS: scheme === 'https',
    enabledTransports: ['ws', 'wss'],
    // Private channels (a match, a club, the account's inbox) are signed by the API with the session cookie
    // and the XSRF token, read fresh on every subscription.
    authorizer: (channel: { name: string }) => ({
      authorize: async (socketId: string, done: (error: Error | null, data: any) => void) => {
        try {
          await ensureCsrf()
          const res = await fetch('/broadcasting/auth', {
            method: 'POST',
            credentials: 'same-origin',
            headers: { Accept: 'application/json', 'Content-Type': 'application/json', 'X-XSRF-TOKEN': xsrf() },
            body: JSON.stringify({ socket_id: socketId, channel_name: channel.name }),
          })
          if (!res.ok) throw new Error(`auth ${res.status}`)
          done(null, await res.json())
        } catch (e) {
          done(e as Error, null)
        }
      },
    }),
  })
  const conn = (echo.connector as any).pusher.connection
  conn.bind('state_change', (s: { current: LiveState }) => (liveState.value = s.current))
  return echo
}
