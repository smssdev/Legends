// [Sprint 53 W1] A live league match on its channel (Reverb, private `match.{id}`, its league's members only): every
// minute is pushed whole as the server makes it (App\Events\MatchMinute, field `live`), and the side chat and the
// reactions as they are posted (App\Events\MatchSocialPosted). The match page then asks GET /matches/{id}/live only to
// join, after a gap, during a break and as a slow safety net, instead of about once a second.
// `connected` is true while the channel is subscribed on a connected socket: the page polls as before whenever it is
// false (no live server, a network that blocks WebSockets, a reconnect), so a viewer never misses a minute.
import { computed, ref, watch, type Ref } from 'vue'
import { live, liveState } from '../lib/echo'
import type { ChatLine, Reaction, Tick } from '../api/sim'

export type PushedMinute = { match_id: number; live: Tick; next_at: number | null }

export function useLiveSync(
  matchId: Ref<number | null>,
  on: {
    minute: (e: PushedMinute) => void
    chat: (c: ChatLine) => void
    reaction: (r: Reaction) => void
    /** The channel came back (or for the first time): the page asks once for what it may have missed. */
    rejoined: () => void
  },
) {
  const subscribed = ref(false)
  let name: string | null = null

  function leave() {
    if (name) {
      try {
        live().leave(name)
      } catch {}
    }
    name = null
    subscribed.value = false
  }

  function join(id: number) {
    leave()
    name = `match.${id}`
    try {
      live()
        .private(name)
        .subscribed(() => {
          subscribed.value = true
          on.rejoined()
        })
        .error(() => {
          subscribed.value = false
        })
        .listen('.minute', (e: PushedMinute) => e?.live && on.minute(e))
        .listen('.chat', (e: { item: ChatLine }) => e?.item && on.chat(e.item))
        .listen('.reaction', (e: { item: Reaction }) => e?.item && on.reaction(e.item))
    } catch {
      // No live connection at all: the page polls.
      subscribed.value = false
    }
  }

  watch(matchId, (id) => (id ? join(id) : leave()), { immediate: true })
  // A dropped socket drops the subscription with it; Pusher subscribes again on its own when it reconnects.
  watch(liveState, (s) => {
    if (s !== 'connected') subscribed.value = false
  })

  const connected = computed(() => subscribed.value && liveState.value === 'connected')
  return { connected, leave }
}
