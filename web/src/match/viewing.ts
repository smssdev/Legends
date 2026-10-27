// How the coach watches his matches [X9, X10]: the Arabic commentator and the simulator (cartoon or Unity).
// Kept in the account so every device plays the same; a guest (the simulator) keeps it on this device only.
import { computed, ref } from 'vue'
import { api } from '../api/client'
import { useAuth } from '../stores/auth'
import { AR_VOICES, DEFAULT_AR_VOICE, type ArVoice } from './voice'

// [UP18] The switch lives beside the voice (it also stops the Arabic recordings from downloading).
export { ARABIC_COMMENTARY } from './voice'

export type MatchView = 'cartoon' | 'unity'
export const MATCH_VIEWS: { id: MatchView; name: string; hint: string }[] = [
  { id: 'cartoon', name: 'الكرتوني', hint: 'الملعب المرسوم ثنائي الأبعاد: خفيف ويعمل على كل جهاز' },
  { id: 'unity', name: 'المطوّر', hint: 'المشهد ثلاثي الأبعاد في Unity: لاعبون وملاعب حقيقية' },
]

function local<T extends string>(key: string, allowed: readonly T[], fallback: T): T {
  try {
    const v = localStorage.getItem(key) as T | null
    return v && allowed.includes(v) ? v : fallback
  } catch {
    return fallback
  }
}
function keep(key: string, value: string) {
  try { localStorage.setItem(key, value) } catch {}
}

// This device's choice: a guest's only one, and a signed-in coach's until their account answers.
// [X41] «الشوالي حقيقي» (voice-7, phrases from another match's recording) became «عصام الشوالي» again: his lines of
// this match, with his real scream on a goal. A coach who chose it hears voice-2.
const asVoice = (v: string | null | undefined) => (v === 'voice-7' ? 'voice-2' : v) as ArVoice | undefined
const guestVoice = ref<ArVoice>(local('legends.arVoice', [...AR_VOICES, 'voice-7'], DEFAULT_AR_VOICE).replace('voice-7', 'voice-2') as ArVoice)
const guestView = ref<MatchView>(local<MatchView>('legends.matchView', ['cartoon', 'unity'], 'cartoon'))

export function useViewing() {
  const auth = useAuth()
  const commentator = computed<ArVoice>(() => asVoice(auth.user?.viewing?.commentator) ?? guestVoice.value)
  const chosenView = computed<MatchView>(() => auth.user?.viewing?.match_view ?? guestView.value)
  const unityReady = computed(() => !!auth.user?.viewing?.unity_ready)
  /** What plays: Unity only once its web build is deployed (Sprint 8); until then the cartoon one. */
  const playing = computed<MatchView>(() => (chosenView.value === 'unity' && unityReady.value ? 'unity' : 'cartoon'))

  async function save(body: { commentator?: ArVoice; match_view?: MatchView }) {
    if (body.commentator) keep('legends.arVoice', (guestVoice.value = body.commentator))
    if (body.match_view) keep('legends.matchView', (guestView.value = body.match_view))
    if (!auth.user) return
    const { data } = await api.PATCH('/auth/me', { body })
    if (data?.user) auth.set(data.user)
  }

  return { commentator, chosenView, unityReady, playing, save }
}
