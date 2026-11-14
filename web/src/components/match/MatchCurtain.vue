<script setup lang="ts">
// [Sprint 63 G2] The passage between the two worlds (the quiet management and the bright pitch): a curtain in the two
// clubs' shirts, the home side's from the start, the away side's from the end, meeting in the middle and parting in
// 420ms. It opens when the match is shown, and the page closes it before leaving (`close()`). The app's is the same
// (mobile/lib/ui/widgets/motion.dart, MatchCurtain). Not drawn with the motion reduced.
import { onMounted, ref } from 'vue'

const props = defineProps<{ home: string; away: string }>()
const MS = 420
const reduced = typeof matchMedia !== 'undefined' && matchMedia('(prefers-reduced-motion: reduce)').matches
const state = ref<'shut' | 'open' | 'closing'>(reduced ? 'open' : 'shut')

onMounted(() => {
  if (!reduced) requestAnimationFrame(() => requestAnimationFrame(() => (state.value = 'open')))
})

/** Draws the curtain shut, and resolves once it is (at once with the motion reduced). */
function close(): Promise<void> {
  if (reduced) return Promise.resolve()
  state.value = 'closing'
  return new Promise((done) => setTimeout(done, MS))
}
defineExpose({ close })
</script>

<template>
  <div
    v-if="!reduced"
    class="curtain"
    :class="state"
    aria-hidden="true"
    :style="{ '--home': props.home, '--away': props.away, '--ms': MS + 'ms' }"
  >
    <span class="half start" />
    <span class="half end" />
  </div>
</template>

<style scoped>
.curtain {
  position: fixed;
  inset: 0;
  z-index: 60;
  pointer-events: none;
  display: flex;
}
.half {
  flex: 1;
  transition: transform var(--ms) cubic-bezier(0.65, 0, 0.35, 1);
  box-shadow: 0 0 40px rgb(0 0 0 / 0.45);
}
.start {
  background: var(--home);
}
.end {
  background: var(--away);
}
.curtain.open .start {
  transform: translateX(-101%);
}
.curtain.open .end {
  transform: translateX(101%);
}
[dir='rtl'] .curtain.open .start {
  transform: translateX(101%);
}
[dir='rtl'] .curtain.open .end {
  transform: translateX(-101%);
}
.curtain.shut .half,
.curtain.closing .half {
  transform: none;
}
</style>
