<script setup lang="ts">
// [Sprint 74 P2] How smoothly the app drew on the players' phones (GET /admin/client-frames): per version, phone tier
// and screen, the share of frames drawn late, the worst first. Counts only (App\Support\ClientFrames).
import { onMounted, ref, watch } from 'vue'
import { api } from '../../api/client'
import type { paths } from '../../api/schema'
import UiCard from '../ui/UiCard.vue'

type Row = paths['/admin/client-frames']['get']['responses']['200']['content']['application/json']['screens'][number]
const days = ref(7)
const rows = ref<Row[] | null>(null)
const load = async () => {
  rows.value = (await api.GET('/admin/client-frames', { params: { query: { days: days.value } } })).data?.screens ?? []
}
// Hundredths of a percent, as the server sends them: 1234 is 12.3%.
const pct = (bp: number) => `${(bp / 100).toFixed(1)}%`
// Over 5% of the frames past 33 ms is felt as stutter; under 2% is smooth.
const mark = (bp: number) => (bp > 500 ? 'bad' : bp > 200 ? 'fair' : 'good')
const TIERS: Record<string, string> = { low: 'ضعيف', mid: 'متوسط', high: 'قوي' }
onMounted(load)
watch(days, load)
</script>

<template>
  <UiCard title="سلاسة التطبيق على الأجهزة">
    <div role="radiogroup" :aria-label="$t('المدة')" class="frames-group">
      <button v-for="d in [1, 7, 30]" :key="d" type="button" role="radio" :aria-checked="days === d" class="ui-choice" @click="days = d">
        {{ d === 1 ? $t('اليوم') : $t('{v0} يوماً', { v0: d }) }}
      </button>
    </div>
    <p v-if="rows && !rows.length" class="text-body text-text-muted">
      {{ $t('لا قياس بعد في هذه المدة: يصل من نسخة التطبيق 2.5.3 وما بعدها.') }}
    </p>
    <p v-else-if="rows" class="text-caption text-text-muted">
      {{ $t('نسبة الإطارات التي تأخرت عن 33 جزءاً من الألف من الثانية (تُحَسّ تقطيعاً)، ثم عن 16. الأسوأ أولاً.') }}
    </p>
    <div v-if="rows?.length" class="frames-scroll">
      <table class="frames">
        <thead>
          <tr>
            <th scope="col">{{ $t('الشاشة') }}</th>
            <th scope="col">{{ $t('النسخة') }}</th>
            <th scope="col">{{ $t('الجوال') }}</th>
            <th scope="col">{{ $t('فوق 33') }}</th>
            <th scope="col">{{ $t('فوق 16') }}</th>
            <th scope="col">{{ $t('الجلسات') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in rows" :key="`${r.platform} ${r.version} ${r.tier} ${r.path}`">
            <td dir="ltr" class="frames-path">{{ r.path }}</td>
            <td dir="ltr">{{ r.version }}</td>
            <td>{{ $t(TIERS[r.tier] ?? r.tier) }}</td>
            <td dir="ltr" class="font-numbers" :class="`frames-${mark(r.late33_bp)}`">{{ pct(r.late33_bp) }}</td>
            <td dir="ltr" class="font-numbers">{{ pct(r.late16_bp) }}</td>
            <td dir="ltr" class="font-numbers">{{ r.sessions }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </UiCard>
</template>

<style scoped>
.frames-group {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-xs);
  margin-block-end: var(--space-md);
}
.frames-scroll {
  overflow-x: auto;
  margin-block-start: var(--space-sm);
}
.frames {
  inline-size: 100%;
  border-collapse: collapse;
  font-size: var(--text-body);
}
.frames th,
.frames td {
  padding: var(--space-xs) var(--space-sm);
  text-align: start;
  border-block-end: 1px solid var(--color-surface-raised);
}
.frames th {
  color: var(--color-text-muted);
  font-size: var(--text-caption);
}
.frames-path {
  word-break: break-all;
}
.frames-bad {
  color: var(--color-danger);
  font-weight: 700;
}
.frames-fair {
  color: var(--ink-gold);
  font-weight: 700;
}
.frames-good {
  color: var(--ink-success);
}
</style>
