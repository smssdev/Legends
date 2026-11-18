// How the coach watches his matches [X10]: the simulator, cartoon or Unity.
// Kept in the account so every device plays the same; a guest (the simulator) keeps it on this device only.
import { storage } from '../lib/storage'
import { computed, ref } from 'vue'
import { api } from '../api/client'
import { useAuth } from '../stores/auth'
import { siteConfig } from '../lib/session'

export type MatchView = 'cartoon' | 'unity'
/** [Sprint 26 W7] The coach on the touchline: the three approved looks (README section 0). */
export type CoachLook = 'C1' | 'C2' | 'C3'
export const COACH_LOOKS: { id: CoachLook; name: string }[] = [
  { id: 'C1', name: 'مدرب ببدلة' },
  { id: 'C2', name: 'مدرب بالتراك سوت' },
  { id: 'C3', name: 'مدربة بحجاب' },
]
export const MATCH_VIEWS: { id: MatchView; name: string; hint: string }[] = [
  { id: 'cartoon', name: 'الكرتوني', hint: 'الملعب المرسوم ثنائي الأبعاد: خفيف ويعمل على كل جهاز' },
  { id: 'unity', name: 'المطوّر', hint: 'المشهد ثلاثي الأبعاد في Unity: لاعبون وملاعب حقيقية' },
]

function local<T extends string>(key: string, allowed: readonly T[], fallback: T): T {
  try {
    const v = storage.get(key) as T | null
    return v && allowed.includes(v) ? v : fallback
  } catch {
    return fallback
  }
}
function keep(key: string, value: string) {
  try {
    storage.set(key, value)
  } catch {}
}

// This device's choice: a guest's only one, and a signed-in coach's until their account answers.
const guestView = ref<MatchView>(local<MatchView>('matchView', ['cartoon', 'unity'], 'cartoon'))

// [Sprint 11 X1] The Unity web build on the server (GET /bootstrap's config.unity_build), asked once a visit.
const unityBuild = ref<string | null>(null)
let askedBuild = false
function askBuild() {
  if (askedBuild) return
  askedBuild = true
  try {
    void siteConfig()
      .then((c) => (unityBuild.value = c?.unity_build ?? null))
      .catch(() => {})
  } catch {}
}

export function useViewing() {
  const auth = useAuth()
  const chosenView = computed<MatchView>(() => auth.user?.viewing?.match_view ?? guestView.value)
  askBuild()
  /** [Sprint 11 X1] Unity once its web build is deployed: the server names it (guests too), or the account says so. */
  const unityReady = computed(() => !!unityBuild.value || !!auth.user?.viewing?.unity_ready)
  /** What plays: Unity only once its web build is deployed; until then the cartoon one. */
  const playing = computed<MatchView>(() => (chosenView.value === 'unity' && unityReady.value ? 'unity' : 'cartoon'))

  const coachLook = computed<CoachLook>(() => (auth.user?.viewing as { coach_look?: CoachLook } | undefined)?.coach_look ?? 'C1')

  async function save(body: { match_view?: MatchView; coach_look?: CoachLook }) {
    if (body.match_view) keep('matchView', (guestView.value = body.match_view))
    if (!auth.user) return
    const { data } = await api.PATCH('/auth/me', { body })
    if (data?.user) auth.set(data.user)
  }

  return { chosenView, unityReady, unityBuild, playing, coachLook, save }
}
