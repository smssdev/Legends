<script setup lang="ts">
// [Sprint 43 W3, Hamza 2026-11-05] The match is watched sideways on a phone (Sprint43Drafts.html): held upright, this
// covers it and asks to turn the phone. On Android one tap opens the match full screen and locks it sideways (the
// browser allows the lock only full screen, after a tap); Safari on the iPhone never locks, so the message stays until
// the phone is turned. Leaving the match lets the phone turn freely again.
import { storage } from '../../lib/storage'
import { onBeforeUnmount, onDeactivated, onMounted, ref } from 'vue'
import UiButton from '../ui/UiButton.vue'

// [Sprint 48 L1] On every game screen too (App.vue), with the game's own words.
const props = withDefaults(defineProps<{ game?: boolean }>(), { game: false })

const query = '(orientation: portrait) and (pointer: coarse) and (max-width: 820px)'
// [Sprint 55 W4, the plan's decision 3] Sideways is the game's way, but on the site whoever wants carries on upright:
// the frame then lays its dock along the bottom (AppShell). Remembered on this device; the match asks again (it is
// watched sideways).
const UPRIGHT = 'upright'
const chose = ref((() => { try { return storage.get(UPRIGHT) === '1' } catch { return false } })())
function stayUpright() {
  chose.value = true
  try { storage.set(UPRIGHT, '1') } catch {}
}
const upright = ref(false)
const lockable = ref(typeof screen !== 'undefined' && 'orientation' in screen && typeof (screen.orientation as any)?.lock === 'function'
  && typeof document.documentElement.requestFullscreen === 'function')
let media: MediaQueryList | null = null
let locked = false
const update = () => (upright.value = !!media?.matches)

async function turn() {
  try {
    if (!document.fullscreenElement) await document.documentElement.requestFullscreen({ navigationUI: 'hide' })
    await (screen.orientation as any).lock('landscape')
    locked = true
  } catch {
    // Not allowed here (the iPhone, or a browser that refuses): the message asks to turn it by hand.
    lockable.value = false
  }
}
function release() {
  if (!locked) return
  locked = false
  try { (screen.orientation as any).unlock?.() } catch {}
  if (document.fullscreenElement) document.exitFullscreen().catch(() => {})
}

onMounted(() => {
  media = typeof matchMedia === 'function' ? matchMedia(query) : null
  update()
  media?.addEventListener('change', update)
})
onDeactivated(release)
onBeforeUnmount(() => { media?.removeEventListener('change', update); release() })
</script>

<template>
  <div v-if="upright && !(props.game && chose)" class="turn fixed inset-0 z-[60] grid place-items-center p-6 text-center" role="dialog" aria-modal="true" :aria-label="$t('لفّ جوالك')">
    <div class="flex max-w-xs flex-col items-center gap-4">
      <div class="device" aria-hidden="true" />
      <b class="font-display text-2xl">{{ $t('لفّ جوالك') }} 🔄</b>
      <span class="text-sm leading-relaxed text-text-muted">{{ props.game ? $t('اللعبة تُلعب بالعرض. أدر الجوال وتكمل فوراً.') : $t('المباراة تُلعب بالعرض. أدر الجوال وتبدأ فوراً.') }}</span>
      <UiButton v-if="lockable" @click="turn">{{ props.game ? $t('العب بالعرض وملء الشاشة') : $t('شاهد بالعرض وملء الشاشة') }}</UiButton>
      <UiButton v-if="props.game" variant="quiet" size="sm" @click="stayUpright">{{ $t('تابع عمودياً') }}</UiButton>
    </div>
  </div>
</template>

<style scoped>
.turn { background: radial-gradient(circle at 50% 40%, color-mix(in srgb, var(--color-brand-dark) 45%, var(--color-bg-deep)) 0%, var(--color-bg-deep) 70%); color: var(--color-text) }
.device { width: 70px; height: 120px; border: 5px solid var(--color-gold); border-radius: 14px; position: relative }
.device::after { content: ''; position: absolute; bottom: 6px; left: 50%; width: 16px; height: 3px; margin-left: -8px; border-radius: 3px; background: var(--color-gold) }
@media (prefers-reduced-motion: no-preference) {
  .device { animation: turn 2.4s ease-in-out infinite }
  @keyframes turn { 0%, 25% { transform: rotate(0) } 55%, 100% { transform: rotate(-90deg) } }
}
</style>
