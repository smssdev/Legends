// [Sprint 63 G12, G13] The game's sound in three levels, as the app has them (its settings): the interface (the
// notification tone, the taps and chimes), the stadium (the crowd and the ball in a match) and the commentator (the
// match's voice). Each from 0 to 100, kept on this device (lib/storage.ts). The interface's sounds are the app's own
// files (mobile/tool/sounds/make_sounds.py writes both), so a tap sounds the same on both.
import { reactive, watch } from 'vue'
import { storage } from './storage'

export type SoundLevel = 'ui' | 'stadium' | 'voice'
const read = (k: SoundLevel, fallback: number) => {
  try {
    const v = Number(storage.get('sound.' + k))
    return storage.get('sound.' + k) !== null && Number.isFinite(v) ? Math.max(0, Math.min(100, v)) : fallback
  } catch { return fallback }
}

export const levels = reactive<Record<SoundLevel, number>>({ ui: read('ui', 80), stadium: read('stadium', 80), voice: read('voice', 80) })
watch(levels, (l) => {
  try { for (const k of ['ui', 'stadium', 'voice'] as const) storage.set('sound.' + k, String(l[k])) } catch {}
})

/** A level as a gain, 0 to 1. */
export const gainOf = (k: SoundLevel) => levels[k] / 100

/** The app's interface sounds (web/public/sounds/ui). */
export type UiSound = 'tap' | 'confirm' | 'coin' | 'error' | 'whistle'
const ext = () => (typeof Audio !== 'undefined' && new Audio().canPlayType('audio/ogg; codecs="vorbis"') ? 'ogg' : 'mp3')
const players = new Map<UiSound, HTMLAudioElement>()

/** One of the interface's sounds at its level (or another's: the settings' sample of each); silent at 0, before the
 * coach's first tap, or where there is no audio. */
export function uiSound(name: UiSound, level: SoundLevel = 'ui') {
  const volume = gainOf(level)
  if (volume <= 0) return
  try {
    let a = players.get(name)
    if (!a) players.set(name, (a = new Audio(`/sounds/ui/${name}.${ext()}`)))
    a.volume = Math.min(1, volume)
    a.currentTime = 0
    void a.play().catch(() => {})
  } catch {}
}
