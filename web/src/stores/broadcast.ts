// The broadcast that keeps going while the coach looks at another screen [X41]: the match page stays alive
// (KeepAlive in App.vue) with its sound and commentary, and the shell shows this bar to return to it or mute it.
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useBroadcast = defineStore('broadcast', () => {
  /** The match page's address while it plays, or null. */
  const path = ref<string | null>(null)
  /** True while the coach is on another screen and the match plays on behind it. */
  const away = ref(false)
  const title = ref('')
  const score = ref('')
  const minute = ref('')
  const live = ref(false)
  /** Bumped by the bar's mute button; the match page turns its sound off when it changes. */
  const muteAsk = ref(0)
  /**
   * [X74] Whether the match page may stay alive behind the other screens (KeepAlive in App.vue): a live match only. A
   * recorded one (a finished match watched again, a practice match) closes as soon as the coach leaves it, and «أغلق
   * البث» closes a live one: the page is let go, so its sound and commentary stop with it.
   */
  const keep = ref(false)

  function update(p: { path: string; title: string; score: string; minute: string; live: boolean }) {
    path.value = p.path
    title.value = p.title
    score.value = p.score
    minute.value = p.minute
    live.value = p.live
  }
  function end() {
    path.value = null
    away.value = false
  }
  /** [X74] «أغلق البث»: the page behind is let go (KeepAlive drops it), and the bar goes. */
  function close() {
    keep.value = false
    end()
  }

  return { path, away, title, score, minute, live, muteAsk, keep, update, end, close }
})
