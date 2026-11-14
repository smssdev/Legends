// [Sprint 65 W7] The match to a screen reader: the broadcast is a picture, so what matters in it (a goal with the score,
// a card, a penalty, the break and the end, the coach's window opening) is said in a live region, once, as it lands.
// The rest of the picture is not described (the sprint's risk: the score and the events in words are enough).
import { ref, watch, type Ref } from 'vue'

type Entry = { minute: string; text: string; important: boolean }

/** What to say for the entries new since the last time (newest first, as the feed keeps them): the newest important
 * one only, so a skip ahead or a catch-up says one line, not forty. A goal carries the score. */
export function announcement(added: Entry[], score: { home: number; away: number }, scoreWord: (h: number, a: number) => string): string {
  const e = added.find((x) => x.important)
  if (!e) return ''
  const minute = e.minute ? `${e.minute} ` : ''
  return `${minute}${e.text} ${scoreWord(score.home, score.away)}`.trim()
}

export function useMatchAnnouncer(d: {
  feed: Ref<Entry[]>
  score: Ref<{ home: number; away: number }>
  windowOn: Ref<boolean>
  skipping: Ref<boolean>
  scoreWord: (h: number, a: number) => string
  windowWord: () => string
}) {
  const said = ref('')
  let seen = d.feed.value.length
  watch(() => d.feed.value.length, (n) => {
    if (n < seen) { seen = n; return }          // a fresh feed (the match again): nothing to say
    const added = d.feed.value.slice(0, n - seen)
    seen = n
    if (d.skipping.value) return
    const line = announcement(added, d.score.value, d.scoreWord)
    if (line) said.value = line
  })
  // At the end of a skip ahead: the score where it landed.
  watch(d.skipping, (on, was) => { if (was && !on) said.value = d.scoreWord(d.score.value.home, d.score.value.away) })
  watch(d.windowOn, (on) => { if (on) said.value = d.windowWord() })
  return { said }
}
