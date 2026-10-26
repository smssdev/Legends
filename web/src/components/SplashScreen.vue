<script setup lang="ts">
// The splash screen [UP4]: GLM's emblem (its ball spins in the SVG itself) breathes while the server is reached (/health); then the game fades in. If the
// server does not answer, the message and a retry, and the game stays behind until it does.
import { onMounted, ref } from 'vue'

const emit = defineEmits<{ done: [] }>()
const state = ref<'checking' | 'failed' | 'leaving'>('checking')
const MIN_MS = 900   // long enough to see the emblem, short enough not to wait for it

async function check() {
  state.value = 'checking'
  const started = performance.now()
  let ok = false
  try {
    const r = await fetch('/api/v1/health', { headers: { Accept: 'application/json' }, signal: AbortSignal.timeout(12000) })
    ok = r.ok
  } catch {
    ok = false
  }
  const rest = MIN_MS - (performance.now() - started)
  if (rest > 0) await new Promise((r) => setTimeout(r, rest))
  if (!ok) {
    state.value = 'failed'
    return
  }
  state.value = 'leaving'
  setTimeout(() => emit('done'), 350)
}
onMounted(check)
</script>

<template>
  <div class="splash" :class="state === 'leaving' ? 'is-leaving' : ''" role="status" aria-live="polite">
    <img src="/brand/emblem-loader.svg" alt="لعبة المدرب الأسطورة" class="splash-mark" :class="state === 'checking' ? 'is-turning' : ''" />
    <template v-if="state === 'failed'">
      <p class="max-w-xs text-center text-sm leading-relaxed text-text-soft">تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت</p>
      <button type="button" class="h-touch rounded-lg bg-gold px-6 font-bold text-on-gold" @click="check">إعادة المحاولة</button>
    </template>
    <span v-else class="sr-only">جارٍ الاتصال بالخادم...</span>
  </div>
</template>

<style scoped>
.splash {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1.25rem;
  padding: 1rem;
  background: radial-gradient(circle at 50% 40%, color-mix(in srgb, var(--color-brand) 30%, var(--color-bg-deep)), var(--color-bg-deep) 70%);
  transition: opacity 0.35s ease, transform 0.35s ease;
}
.splash.is-leaving { opacity: 0; transform: scale(1.06); pointer-events: none; }
.splash-mark { width: min(11rem, 45vw); height: auto; }
.splash-mark.is-turning { animation: splash-turn 1.6s ease-in-out infinite; }
@keyframes splash-turn {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.04); }
}
</style>
