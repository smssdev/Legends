// [Sprint 57 W1] The match's sound: the stadium (MatchSound) and the English commentator (Commentator), each turned on
// from the view's settings. The crowd steps back under the commentator's voice [Sprint 35].
import { storage } from '../lib/storage'
import { ref } from 'vue'
import { MatchSound } from './sound'
import { Commentator, type Lang } from './voice'

const PREF = 'commentary'

/** English unless the coach turned it off on this device. */
function readPref(): Lang | 'off' {
  try {
    return storage.get(PREF) === 'off' ? 'off' : 'en'
  } catch {
    return 'en'
  }
}

export function useMatchAudio() {
  const sound = new MatchSound()
  const voice = new Commentator()
  voice.onTalk = (talking) => sound.duck(talking)
  const soundOn = ref(false)
  const commentary = ref<Lang | 'off'>(readPref())

  function toggleSound() {
    sound.start()
    soundOn.value = !soundOn.value
    sound.setMuted(!soundOn.value)
    voice.setOn(soundOn.value && commentary.value !== 'off')
    if (soundOn.value) sound.whistle()
  }

  /** The commentator speaks when the sound is on: English, or not at all. */
  function toggleCommentary() {
    commentary.value = commentary.value === 'off' ? 'en' : 'off'
    voice.setOn(soundOn.value && commentary.value !== 'off')
    try {
      storage.set(PREF, commentary.value)
    } catch {}
  }

  /** A sound the scene asks for (MatchFeed's cues). */
  function onSound(name: string) {
    if (name === 'kick') sound.kick(true)
    else if (name === 'thud') sound.kick(false)
    else if (name === 'whistle' || name === 'whistle-long') sound.whistle(1)
    else if (name === 'roar') sound.roar()
    // [Sprint 32 A2] The live pitch: a touch, a header, the net.
    else if (name === 'net') sound.net()
    else if (name === 'touch') sound.touch(false)
    else if (name === 'head') sound.touch(true)
    else if (name === 'groan' || name === 'murmur') sound.groan()
    else if (name === 'heart') sound.heart()
    else if (name === 'post') sound.post()
  }

  function dispose() {
    sound.stop()
    voice.dispose()
  }

  return { sound, voice, soundOn, commentary, toggleSound, toggleCommentary, onSound, dispose }
}
