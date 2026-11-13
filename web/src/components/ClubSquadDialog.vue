<script setup lang="ts">
import Icon from './Icon.vue'
// Any club's squad in the league [X17; Sprint 21 E4.1]: what every member may see (the players, their age, rating,
// value and availability), never its tactics or its next lineup. Opened from a club's name in the table, the
// statistics, the fixtures and the news.
import UiDialog from './ui/UiDialog.vue'
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import { t } from '../lib/i18n'
import { useToast } from '../stores/toast'
import { useSlot } from '../stores/slot'
import { count, money } from '../lib/format'

const props = defineProps<{ leagueId: number; clubId: number }>()
const emit = defineEmits<{ close: [] }>()
const squad = ref<any | null>(null)
const error = ref('')
// [X61 E8] «أبلغ عن خطأ في البيانات»: a wrong rating, name or age goes to the developers' support conversation with the
// club's name; the data itself stays read-only (master tables), corrected in the next data version.
const reporting = ref(false)
const report = ref('')
async function sendReport() {
  if (!report.value.trim() || !squad.value) return
  try {
    await ensureCsrf()
    await api.POST('/support', { body: { body: `${t('بلاغ عن خطأ في بيانات {v0}:', { v0: squad.value.name })}\n${report.value.trim()}`.slice(0, 2000) } })
    useToast().show(t('وصل بلاغك إلى المطورين، شكراً.'))
    reporting.value = false
    report.value = ''
  } catch (e) {
    useToast().show(asApiError(e).message, 'error')
  }
}
// [X61 E2] Another coach's player asked on loan: the rounds and the fee, right here.
const slot = useSlot()
const lending = ref<number | null>(null)
const loan = ref({ rounds: 2, fee: 0 })
const canLoan = () => !!squad.value?.coach && squad.value.id !== slot.current?.club?.id
async function askLoan(playerId: number) {
  try {
    await ensureCsrf()
    await api.POST('/leagues/{league}/transfers/loans', { params: { path: { league: props.leagueId } }, body: { player_id: playerId, rounds: loan.value.rounds, fee: loan.value.fee } })
    useToast().show(t('أُرسل طلب الإعارة إلى مدربه.'))
    lending.value = null
  } catch (e) {
    useToast().show(asApiError(e).message, 'error')
  }
}
onMounted(async () => {
  try {
    squad.value = (await api.GET('/leagues/{league}/clubs/{club}', { params: { path: { league: props.leagueId, club: props.clubId } } })).data
  } catch (e) {
    error.value = asApiError(e).message
  }
})
</script>

<template>
  <UiDialog :open="true" bare @close="emit('close')">
    <div class="flex max-h-[85dvh] w-full max-w-xl flex-col gap-3 overflow-y-auto rounded-xl bg-surface p-4">
      <p v-if="error" class="text-sm text-danger" role="alert">{{ $t(error) }}</p>
      <p v-else-if="!squad" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
      <template v-else>
        <div class="flex items-center gap-3">
          <AppImage :src="squad.crest_url" alt="" class="size-10" :size="40" crest />
          <div class="min-w-0 flex-1"><h2 class="truncate font-display text-xl font-extrabold">{{ $nm(squad.name) }}</h2><p class="text-xs text-text-muted">{{ $t('{v0} · {v1} لاعباً', { v0: squad.coach?.name ?? $t('الحاسوب'), v1: count(squad.players.length) }) }}</p></div>
          <button type="button" class="size-touch rounded-md bg-surface-raised" :aria-label="$t('إغلاق')" @click="emit('close')"><Icon name="close" :size="18" /></button>
        </div>
        <button v-if="!reporting" type="button" class="self-start text-xs font-bold text-text-muted underline-offset-2 hover:text-gold hover:underline" @click="reporting = true">{{ $t('أبلغ عن خطأ في البيانات') }}</button>
        <form v-else class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-2" @submit.prevent="sendReport">
          <textarea v-model="report" rows="2" maxlength="1500" dir="auto" class="rounded-md bg-surface p-2 text-sm" :placeholder="$t('مثلاً: تقييم اللاعب أو عمره أو اسمه غير صحيح')" :aria-label="$t('أبلغ عن خطأ في البيانات')" />
          <div class="flex gap-2"><button type="submit" class="h-11 flex-1 rounded-md bg-gold font-bold text-on-gold disabled:opacity-40" :disabled="!report.trim()">{{ $t('أرسل') }}</button>
            <button type="button" class="h-11 rounded-md px-3 text-sm" @click="reporting = false">{{ $t('إلغاء') }}</button></div>
        </form>
        <template v-for="p in squad.players" :key="p.id">
        <div class="flex min-h-touch items-center gap-3 border-t border-text/5 text-sm">
          <span class="w-10 font-numbers text-xs text-text-muted" dir="ltr">{{ p.position }}</span>
          <span class="min-w-0 flex-1 truncate"><bdi>{{ $nm(p.name) }}</bdi> <span class="text-xs text-text-muted">{{ $t('· {v0} سنة', { v0: p.age }) }}</span><span v-if="p.injured_matches" class="text-xs text-danger"> {{ $t('· مصاب') }}</span><span v-if="p.suspended_matches" class="text-xs text-warning"> {{ $t('· موقوف') }}</span></span>
          <b class="font-numbers">{{ p.overall }}</b>
          <span class="w-16 text-end font-numbers text-xs text-text-muted" dir="ltr">{{ money(p.value) }}</span>
          <button v-if="canLoan()" type="button" class="h-9 shrink-0 rounded-md bg-surface-raised px-2 text-xs font-bold text-gold" @click="lending = lending === p.id ? null : p.id; loan = { rounds: 2, fee: Math.round(p.value / 20) }">{{ $t('إعارة') }}</button>
        </div>
        <form v-if="lending === p.id" class="flex flex-wrap items-end gap-2 rounded-lg bg-surface-sunk p-2 text-xs" @submit.prevent="askLoan(p.id)">
          <label class="flex flex-col gap-1">{{ $t('الجولات') }}<input v-model.number="loan.rounds" type="number" min="1" max="6" class="h-10 w-16 rounded-md bg-surface px-2 font-numbers" dir="ltr" /></label>
          <label class="flex flex-1 flex-col gap-1">{{ $t('المقابل') }}<input v-model.number="loan.fee" type="number" min="0" :step="10000" class="h-10 rounded-md bg-surface px-2 font-numbers" dir="ltr" /></label>
          <button type="submit" class="h-10 rounded-md bg-gold px-3 font-bold text-on-gold">{{ $t('اطلب الإعارة') }}</button>
        </form>
        </template>
      </template>
    </div>
  </UiDialog>
</template>
