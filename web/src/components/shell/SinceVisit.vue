<script setup lang="ts">
// [Sprint 64 W3] «Since your last visit», from the server (ClubBoard.since): three cards to flip on entering, the
// newest result, the position before the unseen matches and now, and the offers waiting. They live in the after-round
// window, so they come once for each absence and go with it.
import { computed, ref } from 'vue'
import type { components } from '../../api/schema'
import { scoreText } from '../../lib/format'

const props = defineProps<{ since: NonNullable<components['schemas']['ClubBoard']['since']> }>()
const at = ref(0)
const RESULT = { 1: 'فوز', 0: 'تعادل', [-1]: 'خسارة' } as Record<number, string>
const moved = computed(() => {
  const { before, now } = props.since.position
  return before && now ? before - now : 0
})
const faces = computed(() => [
  'result',
  ...(props.since.position.now ? ['position'] : []),
  ...(props.since.offers ? ['offers'] : []),
])
const face = computed(() => faces.value[at.value % faces.value.length])
</script>

<template>
  <button type="button" class="since" :aria-label="$t('منذ آخر زيارة')" @click="at++">
    <Transition name="flip" mode="out-in">
      <span :key="face" class="since-face">
        <small class="since-kicker">{{ $t('منذ آخر زيارة') }} · <span class="font-numbers" dir="ltr">{{ (at % faces.length) + 1 }}/{{ faces.length }}</span></small>
        <template v-if="face === 'result'">
          <b class="since-big font-numbers" dir="ltr">{{ scoreText(since.last.home_goals, since.last.away_goals) }}</b>
          <span>{{ $t(RESULT[since.last.result] ?? 'تعادل') }} · {{ $nm(since.last.home.name) }} - {{ $nm(since.last.away.name) }}</span>
          <span v-if="since.matches > 1" class="since-note">{{ $t('وفاتتك {v0} مباريات', { v0: since.matches }) }}</span>
        </template>
        <template v-else-if="face === 'position'">
          <b class="since-big font-numbers" dir="ltr">{{ since.position.before ?? '-' }} → {{ since.position.now }}</b>
          <span>{{ moved > 0 ? $t('تقدمت {v0} مراكز', { v0: moved }) : moved < 0 ? $t('تراجعت {v0} مراكز', { v0: -moved }) : $t('ترتيبك كما هو') }}</span>
        </template>
        <template v-else>
          <b class="since-big font-numbers" dir="ltr">{{ since.offers }}</b>
          <span>{{ $t('عروض تنتظر ردك') }}</span>
        </template>
        <span v-if="faces.length > 1" class="since-note">{{ $t('المس لتقلب') }}</span>
      </span>
    </Transition>
  </button>
</template>

<style scoped>
.since { display: block; inline-size: 100%; min-block-size: 44px; perspective: 600px; text-align: center; }
.since-face {
  display: flex; flex-direction: column; align-items: center; gap: var(--space-xs); padding: var(--space-md);
  border-radius: var(--radius-lg); background: var(--color-surface-sunk);
}
.since-kicker { font-size: var(--text-caption); color: var(--color-text-muted); }
.since-big { font-size: 32px; line-height: 1.1; color: var(--color-gold); }
.since-note { font-size: var(--text-caption); color: var(--color-text-muted); }
.flip-enter-active, .flip-leave-active { transition: transform 0.18s ease, opacity 0.18s ease; }
.flip-enter-from { transform: rotateY(-90deg); opacity: 0; }
.flip-leave-to { transform: rotateY(90deg); opacity: 0; }
@media (prefers-reduced-motion: reduce) { .flip-enter-active, .flip-leave-active { transition: none; } }
</style>
