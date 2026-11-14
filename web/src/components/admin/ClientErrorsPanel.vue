<script setup lang="ts">
// [Sprint 66 W2] The errors the players' devices met (GET /admin/client-errors): each distinct error once, with how
// often it came, in which version and on which screen, when first and last seen, and the first lines of its trace.
// Nothing names a player (App\Support\ClientErrors).
import { computed, onMounted, ref, watch } from 'vue'
import { api } from '../../api/client'
import type { paths } from '../../api/schema'
import { t } from '../../lib/i18n'
import UiCard from '../ui/UiCard.vue'

type Row = paths['/admin/client-errors']['get']['responses']['200']['content']['application/json']['errors'][number]
const days = ref(7)
const platform = ref<'all' | 'web' | 'android' | 'ios'>('all')
const rows = ref<Row[] | null>(null)
const open = ref<number | null>(null)
const PLATFORMS = [['all', 'الكل'], ['web', 'الموقع'], ['android', 'أندرويد'], ['ios', 'آيفون']] as const
const load = async () => {
  const query = platform.value === 'all' ? { days: days.value } : { days: days.value, platform: platform.value }
  rows.value = (await api.GET('/admin/client-errors', { params: { query } })).data?.errors ?? []
}
const total = computed(() => (rows.value ?? []).reduce((n, r) => n + r.count, 0))
const when = (iso: string) => new Date(iso).toLocaleString(undefined, { dateStyle: 'short', timeStyle: 'short' })
onMounted(load)
watch([days, platform], load)
</script>

<template>
  <UiCard title="أعطال الأجهزة">
    <div class="errs-filters">
      <div role="radiogroup" :aria-label="$t('المدة')" class="errs-group">
        <button v-for="d in [1, 7, 30]" :key="d" type="button" role="radio" :aria-checked="days === d" class="ui-choice" @click="days = d">{{ d === 1 ? $t('اليوم') : $t('{v0} يوماً', { v0: d }) }}</button>
      </div>
      <div role="radiogroup" :aria-label="$t('المنصة')" class="errs-group">
        <button v-for="[k, label] in PLATFORMS" :key="k" type="button" role="radio" :aria-checked="platform === k" class="ui-choice" @click="platform = k">{{ $t(label) }}</button>
      </div>
    </div>
    <p v-if="rows && !rows.length" class="text-body text-text-muted">{{ $t('لا أعطال في هذه المدة.') }}</p>
    <p v-else-if="rows" class="text-caption text-text-muted">{{ t('{v0} عطلاً مختلفاً، ظهرت {v1} مرة', { v0: rows.length, v1: total }) }}</p>
    <ul v-if="rows?.length" class="errs">
      <li v-for="r in rows" :key="r.id" class="err">
        <button type="button" class="err-head" :aria-expanded="open === r.id" @click="open = open === r.id ? null : r.id">
          <b class="err-count font-numbers" dir="ltr">×{{ r.count }}</b>
          <span class="err-msg" dir="ltr">{{ r.message }}</span>
          <span class="err-meta" dir="ltr">{{ r.platform }} · {{ r.version }} · {{ r.path }}</span>
        </button>
        <div v-if="open === r.id" class="err-body">
          <p class="text-caption text-text-muted">{{ $t('أول مرة {v0}، وآخر مرة {v1}', { v0: when(r.first_seen_at), v1: when(r.last_seen_at) }) }}</p>
          <pre v-if="r.stack" class="err-stack" dir="ltr">{{ r.stack }}</pre>
        </div>
      </li>
    </ul>
  </UiCard>
</template>

<style scoped>
.errs-filters { display: flex; flex-wrap: wrap; gap: var(--space-md); margin-block-end: var(--space-md); }
.errs-group { display: flex; flex-wrap: wrap; gap: var(--space-xs); }
.errs { display: flex; flex-direction: column; gap: var(--space-xs); margin-block-start: var(--space-sm); }
.err { border-radius: var(--radius-lg); background: var(--color-surface-sunk); }
.err-head { display: grid; grid-template-columns: auto 1fr; gap: 2px var(--space-sm); inline-size: 100%; min-block-size: var(--spacing-touch); padding: var(--space-sm); text-align: start; }
.err-count { grid-row: span 2; align-self: center; color: var(--color-danger); font-size: var(--text-title); }
.err-msg { overflow-wrap: anywhere; font-size: var(--text-body); font-weight: 700; }
.err-meta { overflow-wrap: anywhere; color: var(--color-text-muted); font-size: var(--text-caption); }
.err-body { padding: 0 var(--space-sm) var(--space-sm); }
.err-stack { margin-block-start: var(--space-xs); overflow-x: auto; white-space: pre; font-size: var(--text-caption); color: var(--color-text-soft); }
</style>
