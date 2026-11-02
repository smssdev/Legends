// The game's notification tone [Sprint 21 E3.6] (tools/web/notify_tone.py, public/sounds/notify.ogg and .mp3): short and
// calm, played on the game's events while it is open: a message, a code, an offer, a player sold, a match report
// (stores/inbox.ts), and a match kicking off (layouts/AppShell.vue). On this device, kept in its storage.
// [Sprint 39 N1] Browsers play no sound before the coach's first tap on the page (their autoplay policy): the first tap
// anywhere, or «فعّلها» in the activation card (components/shell/SoundPrompt.vue), unlocks it; until then it stays silent
// and nothing fails. The card asks once; the top bar's speaker (SoundToggle.vue) mutes or unmutes it at any time.
import { ref } from 'vue'

const KEY = 'glm.tone'
const ASKED = 'glm.tone.asked'
const read = (k: string) => { try { return localStorage.getItem(k) } catch { return null } }
const write = (k: string, v: string) => { try { localStorage.setItem(k, v) } catch {} }

export const toneOn = ref(read(KEY) !== 'off')
/** The coach answered the activation card (or chose in the account page), so it is not shown again. */
export const toneAsked = ref(read(ASKED) !== null || read(KEY) !== null)
/** The browser let the page play sound (after a tap). */
export const unlocked = ref(false)

let audio: HTMLAudioElement | null = null
const file = () => (new Audio().canPlayType('audio/ogg; codecs="vorbis"') ? '/sounds/notify.ogg' : '/sounds/notify.mp3')

/** Inside a tap: a silent play, so the browser counts the page as allowed to play sound from now on. */
export function unlock() {
  if (unlocked.value) return
  try {
    audio ??= new Audio(file())
    audio.muted = true
    void audio.play().then(() => { audio!.pause(); audio!.currentTime = 0; audio!.muted = false; unlocked.value = true }).catch(() => { if (audio) audio.muted = false })
  } catch {}
}
if (typeof document !== 'undefined') {
  const first = () => { unlock(); document.removeEventListener('pointerdown', first); document.removeEventListener('keydown', first) }
  document.addEventListener('pointerdown', first, { passive: true })
  document.addEventListener('keydown', first)
}

export function setTone(on: boolean) {
  toneOn.value = on
  toneAsked.value = true
  write(KEY, on ? 'on' : 'off')
  write(ASKED, '1')
  if (on) {
    unlock()
    playTone(true)
  }
}

/** The activation card answered «later»: not shown again on this device, the tone left as it is. */
export function askLater() {
  toneAsked.value = true
  write(ASKED, '1')
}

let last = 0
/** The tone, once for events close together (several messages at once ring once); `force` for the preview. */
export function playTone(force = false) {
  if (!toneOn.value || (!force && Date.now() - last < 2000)) return
  last = Date.now()
  try {
    audio ??= new Audio(file())
    audio.volume = 0.6
    audio.currentTime = 0
    void audio.play().catch(() => {})
  } catch {}
}
