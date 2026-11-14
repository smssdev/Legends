// [Sprint 64 W1] The new coach's first match: the three moments the server chose (App\Experience\Intro), each shown
// from its minute until the coach answers it, one at a time; the match's end (or a skip) said once to the server.
// The words are the guide's, as the server sent them: nothing to teach here but «now is the moment».
import { computed, ref, watch, type Ref } from 'vue'
import { storage } from '../lib/storage'
import type { IntroMoment } from '../api/sim'

const key = (id: string) => `intro.${id}`

/** The moments kept for this match when its page opened from /intro (none for any other match). */
export function introMoments(id: string): IntroMoment[] {
  try { return JSON.parse(storage.get(key(id)) ?? '[]') as IntroMoment[] } catch { return [] }
}
export function keepIntroMoments(id: string, moments: IntroMoment[]) {
  try { storage.set(key(id), JSON.stringify(moments)) } catch { /* private mode: the match plays without its moments */ }
}

export function useIntroMatch(o: { id: string; minute: Ref<number>; finished: Ref<boolean>; done: () => Promise<unknown> }) {
  const moments = ref<IntroMoment[]>(introMoments(o.id))
  const answered = ref<IntroMoment['kind'][]>([])
  const over = ref(false)
  const on = computed(() => moments.value.length > 0)
  const current = computed(() => (over.value ? null : moments.value.find((m) => m.minute <= o.minute.value && !answered.value.includes(m.kind)) ?? null))
  let told = false

  function answer() {
    if (current.value) answered.value = [...answered.value, current.value.kind]
  }
  async function end() {
    if (told || !on.value) return
    told = true
    over.value = true
    try { storage.remove(key(o.id)) } catch { /* nothing kept */ }
    await o.done().catch(() => undefined)
  }
  watch(o.finished, (f) => { if (f) void end() }, { immediate: true })

  return { on, current, over, answer, skip: end }
}
