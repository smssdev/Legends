<script setup lang="ts">
// [Sprint 64 B2] The new coaches' first five minutes (GET /admin/funnel): of the accounts made in the chosen days, the
// share that reached each step, from the sign-up to the first match. Counts only, never a person.
import { onMounted, ref, watch } from 'vue'
import { api } from '../../api/client'
import type { paths } from '../../api/schema'
import UiCard from '../ui/UiCard.vue'

type Funnel = paths['/admin/funnel']['get']['responses']['200']['content']['application/json']
const days = ref(30)
const funnel = ref<Funnel | null>(null)
const LABEL: Record<string, string> = {
  signed_up: 'أنشأ حساباً',
  intro_started: 'بدأ المباراة التعريفية',
  intro_finished: 'أنهاها أو تخطاها',
  club_taken: 'أخذ نادياً',
  first_lineup: 'حفظ تشكيلة',
  first_match: 'لعب مباراة',
}
const load = async () => {
  funnel.value = (await api.GET('/admin/funnel', { params: { query: { days: days.value } } })).data ?? null
}
onMounted(load)
watch(days, load)
</script>

<template>
  <UiCard title="خطوات اللاعب الجديد">
    <div class="funnel-days" role="radiogroup" :aria-label="$t('المدة')">
      <button v-for="d in [7, 30, 90]" :key="d" type="button" role="radio" :aria-checked="days === d" class="ui-choice" @click="days = d">
        {{ $t('{v0} يوماً', { v0: d }) }}
      </button>
    </div>
    <ol v-if="funnel" class="funnel">
      <li v-for="s in funnel.steps" :key="s.step" class="funnel-step">
        <span class="funnel-label">{{ $t(LABEL[s.step] ?? s.step) }}</span>
        <span class="funnel-bar"><i :style="{ inlineSize: s.pct + '%' }" /></span>
        <b class="font-numbers" dir="ltr">{{ s.count }} · {{ s.pct }}%</b>
      </li>
    </ol>
  </UiCard>
</template>

<style scoped>
.funnel-days {
  display: flex;
  gap: var(--space-xs);
  margin-block-end: var(--space-md);
}
.funnel {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}
.funnel-step {
  display: grid;
  grid-template-columns: minmax(8rem, 1fr) 2fr auto;
  align-items: center;
  gap: var(--space-sm);
  font-size: var(--text-body);
}
.funnel-bar {
  display: block;
  block-size: 10px;
  overflow: hidden;
  border-radius: var(--radius-pill);
  background: var(--color-surface-sunk);
}
.funnel-bar i {
  display: block;
  block-size: 100%;
  background: var(--color-gold);
}
</style>
