<script setup lang="ts">
// Buttons (design system: احفظ التشكيلة / تحسين تلقائي / إلغاء). At least 44px to touch. [X32] Gold is the page's one
// call to action, emerald (brand) the actions repeated down a list.
// [X61] Every state of a button: a press that gives, a ring for the keyboard, a ripple from the finger, a shine across
// gold on hover; `loading` keeps its size with a spinner (aria-busy), `success` draws a tick and buzzes the phone once.
// All of it stops with reduced motion.
import { ref, watch } from 'vue'

const props = withDefaults(defineProps<{ variant?: 'primary' | 'brand' | 'outline' | 'quiet' | 'danger'; type?: 'button' | 'submit'; block?: boolean; disabled?: boolean; loading?: boolean; success?: boolean }>(), {
  variant: 'primary',
  type: 'button',
})

const ripples = ref<{ id: number; x: number; y: number; size: number }[]>([])
let seq = 0
function ripple(e: PointerEvent) {
  const el = e.currentTarget as HTMLElement
  const r = el.getBoundingClientRect()
  const size = Math.max(r.width, r.height) * 2
  const id = ++seq
  ripples.value.push({ id, x: e.clientX - r.left - size / 2, y: e.clientY - r.top - size / 2, size })
  setTimeout(() => (ripples.value = ripples.value.filter((x) => x.id !== id)), 520)
}
watch(() => props.success, (ok) => ok && navigator.vibrate?.(10))
</script>

<template>
  <button
    :type="type"
    :disabled="disabled || loading"
    :aria-busy="loading || undefined"
    class="ui-btn group relative inline-flex h-12 min-w-touch items-center justify-center gap-2 overflow-hidden rounded-lg px-5 font-display text-base font-extrabold transition duration-150 ease-soft active:scale-[0.97] focus:outline-none focus-visible:ring-2 focus-visible:ring-gold/70 focus-visible:ring-offset-2 focus-visible:ring-offset-bg disabled:cursor-not-allowed disabled:opacity-40 motion-reduce:active:scale-100"
    :class="[
      block ? 'w-full' : '',
      {
        primary: 'bg-gold text-on-gold hover:bg-gold-light',
        brand: 'bg-brand text-white',
        outline: 'border border-gold/70 text-gold hover:bg-gold/10',
        quiet: 'bg-surface-raised text-text hover:bg-surface-raised/80',
        danger: 'bg-live text-white hover:bg-live/90',
      }[variant],
    ]"
    @pointerdown="ripple"
  >
    <span v-for="r in ripples" :key="r.id" aria-hidden="true" class="ui-ripple" :style="{ left: `${r.x}px`, top: `${r.y}px`, width: `${r.size}px`, height: `${r.size}px` }" />
    <span v-if="variant === 'primary'" aria-hidden="true" class="pointer-events-none absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/25 to-transparent transition-transform duration-700 ease-soft group-hover:translate-x-full motion-reduce:hidden" />
    <span v-if="loading" class="ui-spin absolute" aria-hidden="true" />
    <span class="relative z-10 inline-flex items-center gap-2" :class="loading ? 'invisible' : ''">
      <svg v-if="success" class="size-5 animate-pop-in" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M5 12.5l4.5 4.5L19 7.5" class="animate-draw" style="stroke-dasharray: 24; stroke-dashoffset: 24" />
      </svg>
      <slot />
    </span>
  </button>
</template>

<style scoped>
.ui-ripple {
  position: absolute;
  border-radius: 999px;
  background: currentColor;
  opacity: 0.18;
  transform: scale(0);
  animation: ui-ripple 500ms var(--ease-soft) forwards;
  pointer-events: none;
}
@keyframes ui-ripple { to { transform: scale(1); opacity: 0; } }
.ui-spin {
  width: 1.25rem;
  height: 1.25rem;
  border-radius: 999px;
  border: 2.5px solid currentColor;
  border-inline-end-color: transparent;
  animation: ui-spin 0.7s linear infinite;
}
@keyframes ui-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) { .ui-spin { animation-duration: 2s !important; } }
</style>
