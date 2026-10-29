<script setup lang="ts">
// The club's money (Sprint 23 W1), after the drafts WebFinance and MobileFinance: the summary, income and
// expenses per round, the ledger (never edited: the balance is its sum), each sector's sponsor, and the debt
// rule. Every number comes from the API; the page only lays them out.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { count, money } from '../../lib/format'

type Finance = components['schemas']['ClubFinance']
const leagueId = ref<number | null>(null)
const f = ref<Finance | null>(null)
const loaded = ref(false)
const error = ref('')
const picking = ref<string | null>(null)
const busy = ref(false)

const signed = (v: number) => (v > 0 ? '+' : v < 0 ? '−' : '') + count(Math.abs(v))
const short = (v: number) => (v < 0 ? '−' : '') + money(Math.abs(v))
const kpis = computed(() => {
  if (!f.value) return []
  const x = f.value
  return [
    { label: 'الرصيد', v: short(x.balance), sub: x.can_spend ? 'متاح للصرف' : 'ممنوع الصرف حتى يعود موجباً', tone: x.balance < 0 ? 'text-warning' : 'text-gold' },
    { label: 'دخل الموسم', v: '+' + money(x.season_income), sub: 'الرعاة والتذاكر والمكافآت', tone: 'text-success' },
    { label: 'مصاريف الموسم', v: short(x.season_expenses), sub: 'الرواتب وما صُرف', tone: 'text-warning' },
    { label: 'الرواتب لكل جولة', v: '−' + money(x.wages_per_round), sub: 'من قيمة التشكيلة', tone: 'text-text' },
  ]
})
const bars = computed(() => {
  const rows = f.value?.rounds.slice(-12) ?? []
  const top = Math.max(1, ...rows.flatMap((r) => [r.in, r.out]))
  return rows.map((r) => ({ ...r, inH: Math.round((r.in / top) * 160), outH: Math.round((r.out / top) * 160) }))
})
const MARK: Record<string, string> = { main: 'ر', opposite: 'م', north: 'ش', south: 'ج' }

async function load() {
  try {
    leagueId.value = await currentLeague()
    if (leagueId.value) {
      const { data } = await api.GET('/leagues/{league}/team/finance', { params: { path: { league: leagueId.value } } })
      f.value = data!
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

async function sign(sector: string, offer: string) {
  if (!leagueId.value) return
  busy.value = true
  error.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.POST('/leagues/{league}/team/sponsors', { params: { path: { league: leagueId.value } }, body: { sector: sector as any, offer: offer as any } })
    f.value = data!
    picking.value = null
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-5">
    <header>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('المالية') }}</h1>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <p v-if="!loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">{{ $t('ليس لديك فريق بعد.') }} <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink></p>

    <template v-else-if="f">
      <div v-if="!f.can_spend" class="rounded-xl border border-warning/50 bg-warning/10 p-4 text-sm" role="alert">
        <b>{{ $t('رصيدك تحت الصفر.') }}</b> {{ $t('كل صرف ممنوع حتى يعود موجباً. مضى {v0} من {v1} جولات بالسالب، وعند {v2} يُباع أغلى لاعب تلقائياً للمجموعة.', { v0: f.debt_rounds, v1: f.debt_limit, v2: f.debt_limit }) }}
      </div>

      <section :aria-label="$t('الملخص')" class="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <div v-for="k in kpis" :key="k.label" class="flex flex-col gap-1.5 rounded-xl border border-text/10 bg-surface p-4">
          <span class="text-sm text-text-muted">{{ $t(k.label) }}</span>
          <span class="font-numbers text-3xl leading-none" :class="k.tone" dir="ltr">{{ k.v }}</span>
          <span class="text-xs text-text-muted">{{ $t(k.sub) }}</span>
        </div>
      </section>

      <div class="flex flex-wrap items-start gap-5">
        <div class="order-2 flex min-w-0 flex-[3_1_520px] flex-col gap-5 lg:order-none">
          <section v-if="bars.length" :aria-label="$t('الدخل والمصاريف لكل جولة')" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
            <div class="flex flex-wrap items-center justify-between gap-2">
              <h2 class="font-display text-lg font-bold">{{ $t('الدخل والمصاريف لكل جولة') }}</h2>
              <div class="flex gap-3 text-xs text-text-soft"><span class="flex items-center gap-1.5"><i class="size-2.5 rounded-sm bg-success" />{{ $t('دخل') }}</span><span class="flex items-center gap-1.5"><i class="size-2.5 rounded-sm bg-warning" />{{ $t('مصاريف') }}</span></div>
            </div>
            <div role="img" :aria-label="$t('أعمدة الدخل والمصاريف لآخر {v0} جولات', { v0: bars.length })" class="flex h-44 items-end gap-2 border-b border-text/10 px-1">
              <div v-for="b in bars" :key="b.round" class="flex h-full flex-1 items-end justify-center gap-0.5">
                <span class="w-2/5 max-w-4 rounded-t bg-success" :style="{ height: b.inH + 'px' }" />
                <span class="w-2/5 max-w-4 rounded-t bg-warning" :style="{ height: b.outH + 'px' }" />
              </div>
            </div>
            <div class="flex gap-2 px-1"><span v-for="b in bars" :key="b.round" class="flex-1 text-center font-numbers text-xs text-text-muted">{{ $t('ج{v0}', { v0: b.round }) }}</span></div>
          </section>

          <section :aria-label="$t('سجل الحركات')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <div class="flex items-center justify-between"><h2 class="font-display text-lg font-bold">{{ $t('سجل الحركات') }}</h2><span class="text-xs text-text-muted">{{ $t('لا يُعدَّل · الرصيد = مجموع الحركات') }}</span></div>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead><tr class="text-xs text-text-muted"><th class="p-2 text-start font-medium">{{ $t('الجولة') }}</th><th class="p-2 text-start font-medium">{{ $t('الحركة') }}</th><th class="p-2 text-end font-medium">{{ $t('المبلغ') }}</th><th class="p-2 text-end font-medium">{{ $t('الرصيد بعدها') }}</th></tr></thead>
                <tbody>
                  <tr v-for="t in f.transactions" :key="t.id" class="border-t border-text/5">
                    <td class="p-2 font-numbers text-text-muted">{{ t.round ? $t('ج') + t.round : t.cup ? $t('كأس') : '—' }}</td>
                    <td class="p-2"><span class="rounded-sm bg-text/5 px-2 py-0.5 text-xs text-text-soft">{{ $t(t.label) }}</span></td>
                    <td class="p-2 text-end font-numbers text-base" :class="t.amount < 0 ? 'text-warning' : 'text-success'" dir="ltr">{{ signed(t.amount) }}</td>
                    <td class="p-2 text-end font-numbers text-base" dir="ltr">{{ count(t.balance_after) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </div>

        <aside class="order-1 flex min-w-0 flex-[1_1_320px] flex-col gap-4 lg:order-none">
          <section :aria-label="$t('رعاة القطاعات')" class="flex flex-col gap-2.5 rounded-xl bg-surface p-4">
            <div class="flex items-center justify-between"><h2 class="font-display text-lg font-bold">{{ $t('رعاة القطاعات') }}</h2><span class="text-xs text-text-muted">{{ $t('لكل مباراة على أرضك') }}</span></div>
            <div v-for="s in f.sponsors" :key="s.sector" class="flex flex-col gap-2 rounded-lg border p-3" :class="s.chosen ? 'border-text/10 bg-surface-sunk' : 'border-dashed border-gold/50 bg-surface-sunk'">
              <div class="flex items-center gap-3">
                <span class="flex size-10 items-center justify-center rounded-md font-display text-base font-extrabold" :class="s.chosen ? 'bg-gold text-on-gold' : 'bg-text/10'">{{ $t(MARK[s.sector]) }}</span>
                <span class="min-w-0 flex-1">
                  <b class="block text-sm">{{ s.name }}</b>
                  <span v-if="s.chosen" class="text-xs text-text-muted">{{ s.offers.find((o) => o.offer === s.chosen)?.name }}</span>
                  <span v-else class="text-xs text-text-muted">{{ $t('بلا راعٍ · يُوقَّع الثابت عند أول مباراة على أرضك') }}</span>
                </span>
                <span v-if="s.chosen" class="font-numbers text-success" dir="ltr">+{{ money(s.offers.find((o) => o.offer === s.chosen)!.per_match) }}</span>
                <button v-else type="button" class="h-touch rounded-md border border-gold/60 px-3 text-sm font-bold text-gold" :aria-expanded="picking === s.sector" @click="picking = picking === s.sector ? null : s.sector">{{ $t('اختر عقداً') }}</button>
              </div>
              <div v-if="picking === s.sector" class="flex flex-col gap-2">
                <button v-for="o in s.offers" :key="o.offer" type="button" class="flex min-h-touch items-center justify-between gap-3 rounded-md bg-surface px-3 py-2 text-start hover:bg-surface-raised disabled:opacity-50" :disabled="busy" @click="sign(s.sector, o.offer)">
                  <span class="text-sm">{{ o.name }}</span>
                  <span class="text-end font-numbers text-sm" dir="ltr">+{{ money(o.per_match) }}<span v-if="o.per_win" class="block text-xs text-gold">{{ $t('+{v0} عند الفوز', { v0: money(o.per_win) }) }}</span></span>
                </button>
              </div>
            </div>
          </section>

          <section :aria-label="$t('التذاكر')" class="flex flex-col gap-2 rounded-xl bg-surface p-4 text-sm">
            <h2 class="font-display text-lg font-bold">{{ $t('التذاكر') }}</h2>
            <div class="flex justify-between"><span class="text-text-muted">{{ $t('المقاعد') }}</span><b class="font-numbers" dir="ltr">{{ count(f.stadium.capacity) }}</b></div>
            <div class="flex justify-between"><span class="text-text-muted">{{ $t('الحضور المتوقع') }}</span><b class="font-numbers" dir="ltr">{{ Math.round(f.stadium.attendance_bp / 100) }}%</b></div>
            <div class="flex justify-between"><span class="text-text-muted">{{ $t('لكل مباراة على أرضك') }}</span><b class="font-numbers text-success" dir="ltr">+{{ money(f.stadium.tickets_per_match) }}</b></div>
          </section>

        </aside>
      </div>
    </template>
  </div>
</template>
