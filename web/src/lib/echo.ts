// Live updates over Reverb [CLAUDE.md: Reverb, Echo in the web]. One connection for the whole app.
// Match channels are private to the league's members; "system" is public (the test ping).
import Echo from 'laravel-echo'
import Pusher from 'pusher-js'
import { ref } from 'vue'

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
  })
  const conn = (echo.connector as any).pusher.connection
  conn.bind('state_change', (s: { current: LiveState }) => (liveState.value = s.current))
  return echo
}
