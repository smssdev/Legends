<script setup lang="ts">
// [X61 E1] The squad's contracts this season: the wages a round against the cap, each player's wage, and ending a
// contract early for half the wages left (asked first: it cannot be undone).
// [X91] Through lib/action (only the pressed button waits, the result in a toast), and «جدّد للجميع»: every contract
// ending this season renewed for one more in one request (POST contracts/renew-ending), one total asked once.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import UiButton from '../../components/ui/UiButton.vue'
import UiDialog from '../../components/ui/UiDialog.vue'
import UiTabs from '../../components/ui/UiTabs.vue'
import { act, busy } from '../../lib/action'
import { money } from '../../lib/format'
import { nm } from '../../lib/names'
import { t } from '../../lib/i18n'
import { useConfirm } from '../../stores/confirm'
import { useToast } from '../../stores/toast'

type C = components['schemas']['Contracts']
type P = C['players'][number]
const props = defineProps<{ leagueId: number }>()
const emit = defineEmits<{ changed: [] }>()
const c = ref<C | null>(null)
const open = ref(false)
const toast = useToast()
const path = () => ({ params: { path: { league: props.leagueId } } })

async function load() {
  try { c.value = (await api.GET('/leagues/{league}/team/contracts', path())).data ?? null } catch (e) { toast.show(asApiError(e).message, 'error') }
}

// [X62] Renewing: the player stays into the next seasons, for a signing fee a season.
const renewing = ref<P | null>(null)
const seasons = ref(1)
const renewCall = (p: P, n: number) => api.POST('/leagues/{league}/team/contracts/{player}/renew', { params: { path: { league: props.leagueId, player: p.id } }, body: { seasons: n } })
async function renew() {
  const p = renewing.value
  if (!p) return
  const r = await act(`renew:${p.id}`, () => renewCall(p, seasons.value), { success: t('جدّدت عقد {v0}.', { v0: nm(p.name) }) })
  if (r?.data) { c.value = r.data; renewing.value = null; emit('changed') }
}

// [X91] The contracts ending this season, renewed for one season each, in one tap.
const ending = computed(() => (c.value ? c.value.players.filter((p) => p.until <= c.value!.season) : []))
const endingFee = computed(() => ending.value.reduce((s, p) => s + p.renew_one, 0))
const renewingAll = ref(false)
async function renewAll() {
  const list = [...ending.value]
  if (!list.length || !(await useConfirm().ask({
    title: t('تجديد {v0} عقداً لموسم آخر؟', { v0: list.length }),
    text: t('كل من ينتهي عقده هذا الموسم يبقى معك موسماً آخر، ورسوم التوقيع كلها {v0} من أموال النادي.', { v0: money(endingFee.value) }),
    action: t('جدّد للجميع'), tone: 'gold',
  }))) return
  renewingAll.value = true
  const r = await act('renew-ending', () => api.POST('/leagues/{league}/team/contracts/renew-ending', path()))
  renewingAll.value = false
  const n = r?.data?.renewed ?? 0
  if (r?.data) c.value = r.data
  if (n) { toast.show(t('جدّدت {v0} عقداً لموسم آخر.', { v0: n }), 'success'); emit('changed') }
}

const end = (p: P) => act(`release:${p.id}`, () => api.POST('/leagues/{league}/team/contracts/{player}/release', { params: { path: { league: props.leagueId, player: p.id } } }), {
  confirm: { title: t('إنهاء عقد {v0}؟', { v0: nm(p.name) }), text: t('يغادر {v0} إلى السوق، وتدفع تعويضاً {v1} (نصف رواتبه الباقية هذا الموسم).', { v0: nm(p.name), v1: money(p.release) }), action: t('أنهِ العقد') },
  success: t('أنهيت عقد {v0}.', { v0: nm(p.name) }),
}).then((r) => { if (r?.data) { c.value = r.data; emit('changed') } })
onMounted(load)
</script>

<template>
  <section :aria-label="$t('العقود والرواتب')" class="flex flex-col gap-2 rounded-xl ui-card p-4 text-sm">
    <h2 class="font-display text-lg font-bold">{{ $t('العقود والرواتب') }}</h2>
    <template v-if="c">
      <div class="flex justify-between"><span class="text-text-muted">{{ $t('الرواتب كل جولة') }}</span><b class="font-numbers" dir="ltr">{{ money(c.wages_per_round) }}</b></div>
      <div class="flex justify-between"><span class="text-text-muted">{{ $t('سقف الرواتب') }}</span><b class="font-numbers" dir="ltr">{{ money(c.cap_per_round) }}</b></div>
      <div class="h-2 overflow-hidden rounded-full bg-surface-sunk" role="progressbar" :aria-valuenow="Math.round((c.wages_per_round * 100) / Math.max(1, c.cap_per_round))" aria-valuemin="0" aria-valuemax="100">
        <div class="h-full rounded-full bg-gold transition-transform" :style="{ width: Math.min(100, (c.wages_per_round * 100) / Math.max(1, c.cap_per_round)) + '%' }" />
      </div>
      <p class="text-xs text-text-muted">{{ $t('تتسع لاعبين بقيمة {v0} قبل السقف، والعقود تنتهي بنهاية الموسم.', { v0: money(c.room) }) }}</p>
      <UiButton v-if="ending.length" variant="outline" :loading="renewingAll" @click="renewAll">{{ $t('جدّد لكل من ينتهي عقده ({v0}) بـ {v1}', { v0: ending.length, v1: money(endingFee) }) }}</UiButton>
      <button type="button" class="min-h-touch rounded-lg bg-surface-sunk font-bold" :aria-expanded="open" @click="open = !open">{{ open ? $t('إخفاء العقود') : $t('عقود اللاعبين') }}</button>
      <ul v-if="open" class="flex flex-col">
        <li v-for="p in c.players" :key="p.id" class="flex min-h-touch items-center gap-2 border-t border-text/5 py-1">
          <span class="min-w-0 flex-1 truncate"><bdi>{{ $nm(p.name) }}</bdi> <span class="text-xs text-text-muted" dir="ltr">{{ p.position }}</span></span>
          <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ money(p.wage) }}</span>
          <span class="text-xs" :class="p.until > c.season ? 'text-success' : 'text-text-muted'">{{ $t('حتى الموسم {v0}', { v0: p.until }) }}</span>
          <button type="button" class="h-9 rounded-md px-2 text-xs font-bold text-gold hover:bg-gold/10" @click="renewing = p; seasons = 1">{{ $t('جدّد') }}</button>
          <button type="button" class="h-9 rounded-md px-2 text-xs font-bold text-danger hover:bg-live/10" :disabled="busy(`release:${p.id}`)" @click="end(p)">{{ busy(`release:${p.id}`) ? '...' : $t('إنهاء') }}</button>
        </li>
      </ul>
    </template>
    <UiDialog :open="!!renewing" title="تجديد عقد" @close="renewing = null">
      <template v-if="renewing">
        <p class="mb-3 text-sm">{{ $t('يبقى {v0} مع ناديك في المواسم القادمة بتقييمه وتدريبه، بدل أن يعود إلى ناديه في البيانات.', { v0: renewing.name }) }}</p>
        <UiTabs :model-value="String(seasons)" :items="Array.from({ length: c?.max_seasons ?? 3 }, (_, i) => ({ key: String(i + 1), label: $t('{v0} موسم', { v0: i + 1 }) }))" @update:model-value="(v) => (seasons = Number(v))" label="المواسم" fill class="mb-3" />
        <p class="mb-3 text-sm">{{ $t('رسوم التوقيع: {v0}', { v0: money(renewing.renew_one * seasons) }) }}</p>
        <div class="flex gap-2"><UiButton block :loading="busy(`renew:${renewing.id}`)" @click="renew">{{ $t('جدّد العقد') }}</UiButton><UiButton variant="quiet" @click="renewing = null">{{ $t('إلغاء') }}</UiButton></div>
      </template>
    </UiDialog>
  </section>
</template>
