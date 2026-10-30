<script setup lang="ts">
// [X61 E2] Loans this season: the requests for my players (accept or turn down) and mine, and the loans running with
// the round each player goes home. A loan is asked from another coach's squad (its window, from a club's name).
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../../api/client'
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
async function answer(id: number, accept: boolean) {
  try {
    await ensureCsrf()
    v.value = (await api.POST('/leagues/{league}/transfers/loans/{loan}/answer', { params: { path: { league: props.leagueId, loan: id } }, body: { accept } })).data ?? null
    toast.show(accept ? t('قبلت الإعارة.') : t('رفضت الإعارة.'))
    emit('changed')
  } catch (e) {
    toast.show(asApiError(e).message, 'error')
  }
}
onMounted(load)
</script>

<template>
  <section class="flex flex-col gap-2" :aria-label="$t('الإعارات')">
    <p class="rounded-xl bg-surface p-3 text-sm text-text-muted">{{ $t('اطلب لاعباً معاراً من تشكيلة أي مدرب في دوريك (اضغط اسم ناديه)، حتى {v0} جولات.', { v0: v?.max_rounds ?? 6 }) }}</p>
    <p v-if="!v" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <EmptyState v-else-if="!v.loans.length" icon="market" title="لا إعارات الآن" />
    <ul v-else class="flex flex-col gap-2">
      <li v-for="l in v.loans" :key="l.id" class="flex flex-wrap items-center gap-3 rounded-xl bg-surface p-3">
        <span class="min-w-0 flex-1">
          <b class="block truncate"><bdi>{{ $nm(l.player.name) }}</bdi> <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ l.player.position }}</span></b>
          <span class="text-xs text-text-muted">{{ l.mine ? $t('يطلبه {v0}', { v0: $nm(l.borrower) }) : $t('من {v0}', { v0: $nm(l.owner) }) }} · {{ $t('{v0} جولات', { v0: l.rounds }) }} · <span class="font-numbers" dir="ltr">{{ money(l.fee) }}</span></span>
        </span>
        <span v-if="l.status === 'active'" class="rounded-pill bg-success/15 px-3 py-1 text-xs font-bold text-success">{{ $t('معار حتى الجولة {v0}', { v0: l.until_round ?? '' }) }}</span>
        <template v-else-if="l.mine">
          <button type="button" class="h-11 rounded-lg bg-gold px-4 text-sm font-bold text-on-gold" @click="answer(l.id, true)">{{ $t('اقبل') }}</button>
          <button type="button" class="h-11 rounded-lg bg-surface-raised px-4 text-sm font-bold" @click="answer(l.id, false)">{{ $t('ارفض') }}</button>
        </template>
        <span v-else class="rounded-pill bg-warning/15 px-3 py-1 text-xs font-bold text-warning">{{ $t('بانتظار رده') }}</span>
      </li>
    </ul>
  </section>
</template>
