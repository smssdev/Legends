// The game's notification tone [Sprint 21 E3.6] (tools/web/notify_tone.py): played when a message arrives while the
// game is open. On by default, off from the account page, kept on this device. A browser may refuse sound before the
// coach's first tap on the page; then it simply stays silent.
import { ref } from 'vue'

const KEY = 'glm.tone'
export const toneOn = ref((() => { try { return localStorage.getItem(KEY) !== 'off' } catch { return true } })())

export function setTone(on: boolean) {
  toneOn.value = on
  try { localStorage.setItem(KEY, on ? 'on' : 'off') } catch {}
  if (on) playTone()
}

let audio: HTMLAudioElement | null = null
let last = 0
export function playTone() {
  // Not twice within two seconds (several messages at once ring once).
  if (!toneOn.value || Date.now() - last < 2000) return
  last = Date.now()
  try {
    audio ??= new Audio(new Audio().canPlayType('audio/ogg; codecs="vorbis"') ? '/sounds/notify.ogg' : '/sounds/notify.mp3')
    audio.volume = 0.6
    audio.currentTime = 0
    void audio.play().catch(() => {})
  } catch {}
}
