<script setup lang="ts">
// [Sprint 54 W3] The two currencies on the top bar, one shape: the coins (gold) and the club's money (emerald), each a
// link to where it is spent or counted. The number counts to its new value (CountUp).
import CountUp from './CountUp.vue'
import { money } from '../../lib/format'

// [Sprint 58 W7] value null: not known (the load failed): «?» and a warning dot, not a 0.
defineProps<{ kind: 'coins' | 'cash'; value: number | null; to: string; label: string; caption?: string }>()
</script>

<template>
  <RouterLink :to="to" class="ui-money-pill" :class="kind" :aria-label="value === null ? $t('{v0}: غير معروف الآن', { v0: label }) : label">
    <i v-if="value === null" class="ui-money-warn" aria-hidden="true" />
    <AppImage v-if="kind === 'coins'" src="/brand/coin.svg" alt="" class="size-5" :size="20" />
    <span class="flex flex-col leading-none">
      <span v-if="caption" class="hidden text-caption font-bold opacity-80 md:block">{{ $t(caption) }}</span>
      <b class="font-numbers text-body-lg" dir="ltr"
        ><CountUp v-if="value !== null" :value="value" :format="kind === 'cash' ? money : undefined" /><template v-else>?</template></b
      >
    </span>
  </RouterLink>
</template>

<style scoped>
.ui-money-warn {
  position: absolute;
  top: 2px;
  inset-inline-end: 2px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--color-warning);
}
.ui-money-pill {
  position: relative;
  display: flex;
  align-items: center;
  gap: var(--space-xs);
  min-height: var(--spacing-touch);
  padding: 0 0.7rem 0 0.4rem;
  border-radius: 999px;
}
.ui-money-pill.coins {
  color: var(--color-on-gold);
  background: linear-gradient(180deg, var(--color-gold-light), var(--color-gold) 60%, var(--color-gold-dark));
  box-shadow:
    0 1px 0 rgb(255 255 255 / 0.45) inset,
    var(--shadow-raised);
}
.ui-money-pill.cash {
  padding: 0 0.7rem;
  color: var(--ink-success);
  background: color-mix(in srgb, var(--color-success) 18%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-success) 35%, transparent);
}
@media (max-width: 380px) {
  .ui-money-pill.cash {
    padding: 0 0.45rem;
  }
}
</style>
