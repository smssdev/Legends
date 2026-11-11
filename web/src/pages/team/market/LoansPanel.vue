<script setup lang="ts">
// [X61 E2] Loans this season: the requests for my players (accept or turn down) and mine, and the loans running with
// the round each player goes home. A loan is asked from another coach's squad (its window, from a club's name).
import UiButton from '../../../components/ui/UiButton.vue'
import { onMounted, ref } from 'vue'
import { api, asApiError } from '../../../api/client'
import { act, busy } from '../../../lib/action'
import type { components } from '../../../api/schema'
import EmptyState from '../../../components/ui/EmptyState.vue'
import { money } from '../../../lib/format'
import { t } from '../../../lib/i18n'
import { useToast } from '../../../stores/toast'

const props = defineProps<{ leagueId: number }>()
const emit = defineEmits<{ changed: [] }>()
const v = ref<components['schemas']['Loans'] | null>(null)
const toast = useToast()
const path = () => ({ params: { path: { league: props.leagueId } } })

async function load() {
  try { v.value = (await api.GET('/leagues/{league}/transfers/loans', path())).data ?? null } catch (e) { toast.show(asApiError(e).message, 'error') }
}
// [X92] Through lib/action: its two buttons wait together, the result in a toast.
async function answer(id: number, accept: boolean) {
  const r = await act(`loan:${id}`, () => api.POST('/leagues/{league}/transfers/loans/{loan}/answer', { params: { path: { league: props.leagueId, loan: id } }, body: { accept } }), {
    success: accept ? t('قبلت الإعارة.') : t('رفضت الإعارة.'),
  })
  if (r?.data) { v.value = r.data; emit('changed') }
}
onMounted(load)
</script>

<template>
  <section class="flex flex-col gap-2" :aria-label="$t('الإعارات')">
    <p class="rounded-xl ui-card p-3 text-sm text-text-muted">{{ $t('اطلب لاعباً معاراً من تشكيلة أي مدرب في دوريك (اضغط اسم ناديه)، حتى {v0} جولات.', { v0: v?.max_rounds ?? 6 }) }}</p>
    <p v-if="!v" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <EmptyState v-else-if="!v.loans.length" icon="market" title="لا إعارات الآن" />
    <ul v-else class="flex flex-col gap-2">
      <li v-for="l in v.loans" :key="l.id" class="flex flex-wrap items-center gap-3 rounded-xl ui-card p-3">
        <span class="min-w-0 flex-1">
          <b class="block truncate"><bdi>{{ $nm(l.player.name) }}</bdi> <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ l.player.position }}</span></b>
          <span class="text-xs text-text-muted">{{ l.mine ? $t('يطلبه {v0}', { v0: $nm(l.borrower) }) : $t('من {v0}', { v0: $nm(l.owner) }) }} · {{ $t('{v0} جولات', { v0: l.rounds }) }} · <span class="font-numbers" dir="ltr">{{ money(l.fee) }}</span></span>
        </span>
        <span v-if="l.status === 'active'" class="rounded-pill bg-success/15 px-3 py-1 text-xs font-bold text-success">{{ $t('معار حتى الجولة {v0}', { v0: l.until_round ?? '' }) }}</span>
        <template v-else-if="l.mine">
          <UiButton size="sm" :disabled="busy(`loan:${l.id}`)" @click="answer(l.id, true)">{{ $t('اقبل') }}</UiButton>
          <button type="button" class="h-11 rounded-lg bg-surface-raised px-4 text-sm font-bold disabled:opacity-40" :disabled="busy(`loan:${l.id}`)" @click="answer(l.id, false)">{{ $t('ارفض') }}</button>
        </template>
        <span v-else class="rounded-pill bg-warning/15 px-3 py-1 text-xs font-bold text-warning">{{ $t('بانتظار رده') }}</span>
      </li>
    </ul>
  </section>
</template>
