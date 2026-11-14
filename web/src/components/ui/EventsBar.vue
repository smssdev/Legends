<script setup lang="ts">
// [Sprint 23] The admin's timed events running now (from the API), each with what it does and a countdown to its end.
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { t } from '../../lib/i18n'
import type { components } from '../../api/schema'

type Ev = components['schemas']['TimedEventNow']
const props = defineProps<{ events?: Ev[] | null }>()
const emit = defineEmits<{ ended: [] }>()
const now = ref(Date.now())
let clock = 0
// Once per ended event: the page reloads, and a late server clock does not make it reload every second.
const told = new Set<string>()
onMounted(() => {
  clock = window.setInterval(() => {
    now.value = Date.now()
    const ended = (props.events ?? []).filter((e) => new Date(e.ends_at).getTime() <= now.value && !told.has(e.kind + e.ends_at))
    if (ended.length) {
      ended.forEach((e) => told.add(e.kind + e.ends_at))
      emit('ended')
    }
  }, 1000)
})
onBeforeUnmount(() => clearInterval(clock))

const label = (e: Ev) =>
  ({
    madness: t('جنون الانتقالات: البيع وتجديد السوق أسرع {v0} مرة', { v0: e.power / 10000 }),
    progression: t('التقدم الفائق: كل جلسة تدريب أكبر {v0} مرة', { v0: e.power / 10000 }),
    discount: t('خصم السوق: لاعبو العالم أرخص {v0}%', { v0: e.power / 100 }),
    offers: t('العروض الخاصة: لاعبون بخصم {v0}% حتى تجديد السوق', { v0: e.power / 100 }),
    in_form: t('نجوم الأسبوع: لاعبون في قمة مستواهم +{v0}', { v0: e.power }),
    legends: t('الأساطير: لاعبون أقوى من أفضل لاعبي دوريك'),
  })[e.kind]
const icon = (e: Ev) => ({ madness: '⚡', progression: '🚀', discount: '🏷️', offers: '🎁', in_form: '🔥', legends: '👑' })[e.kind]
const left = (iso: string) => {
  const s = Math.max(0, Math.floor((new Date(iso).getTime() - now.value) / 1000))
  const d = Math.floor(s / 86400)
  const hms = [Math.floor((s % 86400) / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
  return d ? `${d}d ${hms}` : hms
}
const running = computed(() => (props.events ?? []).filter((e) => new Date(e.ends_at).getTime() > now.value))
</script>

<template>
  <ul v-if="running.length" class="flex flex-col gap-1.5" :aria-label="t('الفعاليات الجارية')">
    <li
      v-for="e in running"
      :key="e.kind + e.ends_at"
      class="flex flex-wrap items-center gap-2 rounded-lg border border-gold/40 bg-gold/10 px-3 py-2 text-sm"
    >
      <span aria-hidden="true">{{ icon(e) }}</span>
      <b class="min-w-0 flex-1">{{ label(e) }}</b>
      <span class="text-xs text-text-muted">{{ t('تنتهي بعد') }}</span>
      <b class="font-numbers text-gold" dir="ltr">{{ left(e.ends_at) }}</b>
    </li>
  </ul>
</template>
