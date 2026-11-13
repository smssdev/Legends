<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// The league table and its statistics [X17; «جدول الدوري» since Sprint 21 E4.2, with the leaders on top]: the season's table in detail, the scorers and the assists, the cards, each club's
// buying and selling, the squads' value and the runs of results. A club's name opens its squad (what anyone in the
// league may see: no tactic). No draft of its own: the design system's cards and the league table's look.
import EmptyState from '../../components/ui/EmptyState.vue'
import { computed, onMounted, ref, watch } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { nm } from '../../lib/names'
import { t } from '../../lib/i18n'
import { useSlot } from '../../stores/slot'
import { money } from '../../lib/format'
import ClubSquadDialog from '../../components/ClubSquadDialog.vue'
import AdSlot from '../../components/ads/AdSlot.vue'
import UiTabs from '../../components/ui/UiTabs.vue'

type Stats = components['schemas']['LeagueStats']
type Club = components['schemas']['StatsClub']
const TABS = { table: 'الترتيب', scorers: 'الهدافون', assists: 'صناع اللعب', cards: 'الانضباط', money: 'المالية', value: 'القيمة السوقية', runs: 'السلاسل', split: 'أرض وخارج', awards: 'الأوسمة' } as const
type Tab = keyof typeof TABS

const leagueId = ref<number | null>(null)
const s = ref<Stats | null>(null)
const tab = ref<Tab>('table')
// [X61 E5] The season's awards, loaded when their tab opens.
const awards = ref<components['schemas']['Awards'] | null>(null)
watch(tab, async (t) => {
  if (t === 'awards' && !awards.value && leagueId.value) awards.value = (await api.GET('/leagues/{league}/awards', { params: { path: { league: leagueId.value } } })).data ?? null
})
const rating = (x10: number) => (x10 / 10).toFixed(1)
const error = ref('')
const loaded = ref(false)
const squadOf = ref<number | null>(null)

const avg = (x100: number) => (x100 / 100).toFixed(2)
const RUN: Record<string, string> = { W: 'فوز', D: 'تعادل', L: 'خسارة' }
const RUN_CLASS: Record<string, string> = { W: 'bg-success text-on-gold', D: 'bg-surface-raised', L: 'bg-live text-white' }
const empty = computed(() => !s.value || s.value.matches === 0)
const leaders = computed(() => {
  const v = s.value
  if (!v) return []
  const attack = [...v.table].sort((a, b) => b.goals_for - a.goals_for)[0]
  const defence = [...v.table].sort((a, b) => a.goals_against - b.goals_against)[0]
  return [
    { label: 'المتصدر', name: v.table[0] ? nm(v.table[0].club.name) : '-', value: v.table[0] ? t('{n} نقطة', { n: v.table[0].points }) : '' },
    { label: 'الهداف', name: v.scorers[0] ? nm(v.scorers[0].player.name) : '-', value: v.scorers[0] ? t('{n} هدف', { n: v.scorers[0].goals }) : '' },
    { label: 'أقوى هجوم', name: attack ? nm(attack.club.name) : '-', value: attack ? t('{n} هدف', { n: attack.goals_for }) : '' },
    { label: 'أقوى دفاع', name: defence ? nm(defence.club.name) : '-', value: defence ? t('{n} استقبل', { n: defence.goals_against }) : '' },
  ]
})

onMounted(async () => {
  try {
    leagueId.value = await currentLeague()
    if (leagueId.value) s.value = (await api.GET('/leagues/{league}/stats', { params: { path: { league: leagueId.value } } })).data!
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
})

const openSquad = (c: Club) => (squadOf.value = c.id)
// The coach's own club in gold in every table [X32].
const slot = useSlot()
const mine = (id: number) => (id === slot.current?.club?.id ? 'is-mine' : '')
// [X61] The table as a CSV file (opens in any spreadsheet), with a byte-order mark so Arabic names read right.
function exportCsv() {
  if (!s.value) return
  const head = ['#', t('النادي'), t('لعب'), t('فاز'), t('تعادل'), t('خسر'), t('له'), t('عليه'), t('الفارق'), t('النقاط')]
  const rows = s.value.table.map((r) => [r.position, nm(r.club.name), r.played, r.won, r.drawn, r.lost, r.goals_for, r.goals_against, r.goal_difference, r.points])
  const csv = [head, ...rows].map((row) => row.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n')
  const a = document.createElement('a')
  a.href = URL.createObjectURL(new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' }))
  a.download = 'standings.csv'
  a.click()
  URL.revokeObjectURL(a.href)
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <div>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('جدول الدوري') }}</h1>
    </div>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-danger">{{ $t(error) }}</p>
    <p v-else-if="loaded && !leagueId" class="rounded-xl ui-card p-4 text-text-muted">{{ $t('انضم إلى دوري واستلم فريقاً لترى إحصائياته.') }}</p>
    <p v-else-if="!loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>

    <template v-if="s">
      <UiTabs v-model="tab" :items="(Object.keys(TABS) as Tab[]).map((key) => ({ key, label: TABS[key] }))" label="أقسام الإحصائيات" />
      <EmptyState v-if="empty && tab !== 'value'" icon="league" title="لم تُلعب مباريات في هذا الموسم بعد." text="تمتلئ الأرقام بعد أول جولة." :cta="{ label: 'المباراة القادمة', to: '/match' }" />
      <!-- [Sprint 21 E4.2] The season's leaders at a glance. -->
      <section v-else-if="tab === 'table'" class="grid grid-cols-2 gap-2 lg:grid-cols-4" :aria-label="$t('المتصدرون')">
        <div v-for="card in leaders" :key="card.label" class="flex flex-col gap-0.5 rounded-xl ui-card p-3">
          <span class="text-xs text-text-muted">{{ $t(card.label) }}</span>
          <b class="truncate font-display text-base"><bdi>{{ card.name }}</bdi></b>
          <span class="font-numbers text-sm text-gold">{{ card.value }}</span>
        </div>
      </section>

      <!-- [X61] On the phone each club is a card (place, points, played, difference, for and against), no sideways scroll;
           the full table on a wider screen. A change of place slides the rows (FLIP). -->
      <div v-if="tab === 'table'" class="flex justify-end">
        <button type="button" class="flex min-h-touch items-center gap-1.5 rounded-lg px-3 text-sm font-bold text-brand-light hover:bg-surface" @click="exportCsv">{{ $t('تصدير CSV') }}</button>
      </div>
      <TransitionGroup v-if="tab === 'table'" tag="ol" name="flip" class="flex flex-col gap-1.5 md:hidden" :aria-label="$t('الترتيب المفصل')">
        <li v-for="r in s.table" :key="r.club.id" class="flex items-center gap-3 rounded-xl ui-card p-2.5" :class="mine(r.club.id)">
          <span class="w-6 text-center font-numbers text-lg text-text-muted">{{ r.position }}</span>
          <button type="button" class="flex min-h-touch min-w-0 flex-1 items-center gap-2 text-start font-bold" @click="openSquad(r.club)">
            <AppImage :src="r.club.crest_url" alt="" class="size-7 shrink-0" :size="28" crest />
            <span class="min-w-0"><span class="block truncate">{{ $nm(r.club.name) }}</span>
              <span class="block font-numbers text-xs font-normal text-text-muted">{{ $t('لعب {v0} · له {v1} · عليه {v2}', { v0: r.played, v1: r.goals_for, v2: r.goals_against }) }}</span></span>
          </button>
          <span class="font-numbers text-sm text-text-muted" dir="ltr">{{ r.goal_difference > 0 ? '+' : '' }}{{ r.goal_difference }}</span>
          <b class="w-9 text-center font-numbers text-xl text-gold">{{ r.points }}</b>
        </li>
      </TransitionGroup>
      <section v-if="tab === 'table'" class="hidden overflow-x-auto rounded-xl ui-card p-3 md:block" :aria-label="$t('الترتيب المفصل')">
        <table class="w-full min-w-[640px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2">#</th><th class="text-start">{{ $t('النادي') }}</th><th>{{ $t('لعب') }}</th><th>{{ $t('فاز') }}</th><th>{{ $t('تعادل') }}</th><th>{{ $t('خسر') }}</th><th>{{ $t('له') }}</th><th>{{ $t('عليه') }}</th><th>{{ $t('الفارق') }}</th><th>{{ $t('معدل التسجيل') }}</th><th>{{ $t('معدل الاستقبال') }}</th><th>{{ $t('النقاط') }}</th></tr></thead>
          <tbody class="font-numbers">
            <tr v-for="r in s.table" :key="r.club.id" class="border-t border-text/5 text-center" :class="mine(r.club.id)">
              <td class="py-2">{{ r.position }}</td>
              <td class="text-start font-sans"><button type="button" class="flex min-h-touch items-center gap-2 font-bold hover:text-gold" @click="openSquad(r.club)"><AppImage :src="r.club.crest_url" alt="" class="size-6" :size="24" crest />{{ $nm(r.club.name) }}</button></td>
              <td>{{ r.played }}</td><td>{{ r.won }}</td><td>{{ r.drawn }}</td><td>{{ r.lost }}</td><td>{{ r.goals_for }}</td><td>{{ r.goals_against }}</td>
              <td dir="ltr">{{ r.goal_difference > 0 ? '+' : '' }}{{ r.goal_difference }}</td><td>{{ avg(r.goals_per_match_x100) }}</td><td>{{ avg(r.conceded_per_match_x100) }}</td>
              <td class="font-bold text-gold">{{ r.points }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section v-for="list in (['scorers', 'assists'] as const)" v-show="tab === list" :key="list" class="flex flex-col gap-1 rounded-xl ui-card p-3" :aria-label="TABS[list]">
        <div v-for="(p, i) in s[list]" :key="p.player.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
          <span class="w-6 text-center font-numbers text-text-muted">{{ i + 1 }}</span>
          <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ $nm(p.player.name) }}</bdi></b><button type="button" class="text-xs text-text-muted hover:text-gold" @click="openSquad(p.club)">{{ $nm(p.club.name) }}</button></span>
          <b class="font-numbers text-xl text-gold">{{ list === 'scorers' ? p.goals : p.assists }}</b>
          <span class="w-20 text-xs text-text-muted">{{ list === 'scorers' ? $t('{v0} صناعة', { v0: p.assists }) : $t('{v0} هدف', { v0: p.goals }) }}</span>
        </div>
        <p v-if="!s[list].length" class="text-text-muted">{{ $t('لا أحد بعد.') }}</p>
      </section>

      <template v-if="tab === 'cards'">
        <section class="overflow-x-auto rounded-xl ui-card p-3" :aria-label="$t('بطاقات الأندية')">
          <h2 class="mb-2 font-display text-lg font-bold">{{ $t('الأندية') }}</h2>
          <table class="w-full text-sm">
            <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('النادي') }}</th><th>{{ $t('صفراء') }}</th><th>{{ $t('حمراء') }}</th></tr></thead>
            <tbody class="font-numbers"><tr v-for="c in s.discipline.clubs" :key="c.club.id" class="border-t border-text/5 text-center" :class="mine(c.club.id)">
              <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(c.club)">{{ $nm(c.club.name) }}</button></td>
              <td><span class="inline-block h-4 w-3 rounded-sm bg-warning align-middle" aria-hidden="true" /> {{ c.yellow }}</td><td><span class="inline-block h-4 w-3 rounded-sm bg-live align-middle" aria-hidden="true" /> {{ c.red }}</td>
            </tr></tbody>
          </table>
        </section>
        <section v-for="[key, title] in ([['players', 'أكثر اللاعبين طرداً'], ['bookings', 'أكثر اللاعبين إنذاراً']] as const)" :key="key" class="flex flex-col gap-1 rounded-xl ui-card p-3" :aria-label="title">
          <h2 class="mb-1 font-display text-lg font-bold">{{ $t(title) }}</h2>
          <div v-for="p in s.discipline[key]" :key="p.player.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
            <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ $nm(p.player.name) }}</bdi></b><span class="text-xs text-text-muted">{{ $nm(p.club.name) }}</span></span>
            <span class="font-numbers"><Icon name="card" :size="16" class="inline-block align-[-3px] text-card-yellow" /> {{ p.yellow }} · <Icon name="card" :size="16" class="inline-block align-[-3px] text-live" /> {{ p.red }}</span>
          </div>
          <p v-if="!s.discipline[key].length" class="text-text-muted">{{ $t('لا أحد بعد.') }}</p>
        </section>
      </template>

      <section v-if="tab === 'money'" class="overflow-x-auto rounded-xl ui-card p-3" :aria-label="$t('التقرير المالي')">
        <table class="w-full min-w-[520px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('النادي') }}</th><th>{{ $t('اشترى') }}</th><th>{{ $t('صفقات') }}</th><th>{{ $t('باع') }}</th><th>{{ $t('صفقات') }}</th><th>{{ $t('الصافي') }}</th></tr></thead>
          <tbody class="font-numbers"><tr v-for="f in s.finance" :key="f.club.id" class="border-t border-text/5 text-center" :class="mine(f.club.id)">
            <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(f.club)">{{ $nm(f.club.name) }}</button></td>
            <td dir="ltr">{{ money(f.bought) }}</td><td>{{ f.bought_count }}</td><td dir="ltr">{{ money(f.sold) }}</td><td>{{ f.sold_count }}</td>
            <td dir="ltr" :class="f.net >= 0 ? 'text-success' : 'text-danger'">{{ f.net >= 0 ? '+' : '' }}{{ money(f.net) }}</td>
          </tr></tbody>
        </table>
      </section>

      <section v-if="tab === 'value'" class="flex flex-col gap-1 rounded-xl ui-card p-3" :aria-label="$t('القيمة السوقية')">
        <div v-for="r in s.value" :key="r.club.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
          <span class="w-6 text-center font-numbers text-text-muted">{{ r.position }}</span>
          <AppImage :src="r.club.crest_url" alt="" class="size-7" :size="28" crest />
          <button type="button" class="min-w-0 flex-1 truncate text-start font-bold hover:text-gold" @click="openSquad(r.club)">{{ $nm(r.club.name) }}</button>
          <span class="text-xs text-text-muted">{{ $t('{v0} لاعباً', { v0: r.players }) }}</span>
          <b class="font-numbers text-gold" dir="ltr">{{ money(r.value) }}</b>
        </div>
      </section>

      <!-- [X61 E12] Each club at home and away. -->
      <section v-if="tab === 'split'" class="overflow-x-auto rounded-xl ui-card p-3" :aria-label="$t('أرض وخارج')">
        <table class="w-full min-w-[520px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('النادي') }}</th><th colspan="3">{{ $t('على أرضه') }}</th><th colspan="3">{{ $t('خارج أرضه') }}</th></tr>
            <tr class="text-xs"><th /><th>{{ $t('لعب') }}</th><th>{{ $t('الفارق') }}</th><th>{{ $t('النقاط') }}</th><th>{{ $t('لعب') }}</th><th>{{ $t('الفارق') }}</th><th>{{ $t('النقاط') }}</th></tr></thead>
          <tbody class="font-numbers">
            <tr v-for="r in s.split" :key="r.club.id" class="border-t border-text/5 text-center" :class="mine(r.club.id)">
              <td class="py-2 text-start font-sans font-bold"><span class="flex items-center gap-2"><AppImage :src="r.club.crest_url" alt="" class="size-5" :size="20" crest />{{ $nm(r.club.name) }}</span></td>
              <td>{{ r.home.played }}</td><td dir="ltr">{{ r.home.goals_for - r.home.goals_against }}</td><td class="font-bold text-gold">{{ r.home.points }}</td>
              <td>{{ r.away.played }}</td><td dir="ltr">{{ r.away.goals_for - r.away.goals_against }}</td><td class="font-bold text-gold">{{ r.away.points }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- [X61 E5] The season's awards so far. -->
      <section v-if="tab === 'awards'" class="grid gap-2 sm:grid-cols-2 lg:grid-cols-3" :aria-label="$t('الأوسمة')">
        <p v-if="!awards" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
        <template v-else>
          <article v-for="[key, title, icon] in ([['mvp', 'أفضل لاعب', '🏆'], ['young', 'أفضل لاعب شاب', '🌱'], ['of_the_round', 'نجم الجولة', '⭐'], ['scorer', 'الهداف', '⚽'], ['assister', 'صانع الألعاب', '🎯']] as const)" :key="key"
            class="flex animate-pop-in items-center gap-3 rounded-xl border border-gold/25 ui-card p-3">
            <span class="grid size-12 shrink-0 place-items-center rounded-full bg-gold/15 text-2xl" aria-hidden="true">{{ icon }}</span>
            <span class="min-w-0 flex-1">
              <span class="block text-xs text-text-muted">{{ $t(title) }}<template v-if="key === 'of_the_round' && awards.of_the_round"> · {{ $t('الجولة {v0}', { v0: awards.of_the_round.round }) }}</template></span>
              <template v-if="awards[key]">
                <b class="block truncate"><bdi>{{ $nm(awards[key]!.player.name) }}</bdi></b>
                <span class="block truncate text-xs text-text-muted">{{ $nm(awards[key]!.club?.name) }}</span>
              </template>
              <span v-else class="text-sm text-text-muted">{{ $t('لم يُحسم بعد') }}</span>
            </span>
            <b v-if="awards[key]" class="font-numbers text-xl text-gold" dir="ltr">{{ key === 'scorer' ? awards.scorer!.goals : key === 'assister' ? awards.assister!.assists : key === 'of_the_round' ? rating(awards.of_the_round!.rating_x10 ?? 0) : rating(awards[key]!.average_x10) }}</b>
          </article>
          <article class="flex items-center gap-3 rounded-xl border border-gold/25 ui-card p-3">
            <span class="grid size-12 shrink-0 place-items-center rounded-full bg-gold/15 text-2xl" aria-hidden="true"><Icon name="fire" :size="18" class="inline-block align-[-3px]" /></span>
            <span class="min-w-0 flex-1"><span class="block text-xs text-text-muted">{{ $t('أطول سلسلة انتصارات') }}</span>
              <b v-if="awards.run" class="block truncate">{{ $nm(awards.run.club.name) }}</b><span v-else class="text-sm text-text-muted">{{ $t('لم يُحسم بعد') }}</span></span>
            <b v-if="awards.run" class="font-numbers text-xl text-gold">{{ awards.run.wins }}</b>
          </article>
        </template>
      </section>

      <section v-if="tab === 'runs'" class="overflow-x-auto rounded-xl ui-card p-3" :aria-label="$t('سلاسل النتائج')">
        <table class="w-full min-w-[560px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('النادي') }}</th><th>{{ $t('آخر 5') }}</th><th>{{ $t('الحالية') }}</th><th>{{ $t('أطول فوز') }}</th><th>{{ $t('أطول تعادل') }}</th><th>{{ $t('أطول خسارة') }}</th></tr></thead>
          <tbody class="font-numbers"><tr v-for="r in s.streaks" :key="r.club.id" class="border-t border-text/5 text-center" :class="mine(r.club.id)">
            <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(r.club)">{{ $nm(r.club.name) }}</button></td>
            <td><span class="inline-flex gap-1" dir="ltr"><span v-for="(k, i) in r.form" :key="i" class="grid size-6 place-items-center rounded-sm text-xs font-bold" :class="RUN_CLASS[k]" :title="RUN[k]">{{ k === 'W' ? $t('ف') : k === 'D' ? $t('ت') : $t('خ') }}</span></span></td>
            <td class="font-sans">{{ r.current ? `${r.current.length} ${RUN[r.current.kind]}` : '-' }}</td>
            <td>{{ r.best.W }}</td><td>{{ r.best.D }}</td><td>{{ r.best.L }}</td>
          </tr></tbody>
        </table>
      </section>
    </template>

    <!-- A rival's squad: what anyone in the league may see. -->
    <ClubSquadDialog v-if="squadOf && leagueId" :league-id="leagueId" :club-id="squadOf" @close="squadOf = null" />
    <!-- [X57] One Google ad at the page's foot. -->
    <AdSlot />
  </div>
</template>
