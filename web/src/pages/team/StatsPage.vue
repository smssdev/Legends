<script setup lang="ts">
// The league table and its statistics [X17; «جدول الدوري» since Sprint 21 E4.2, with the leaders on top]: the season's table in detail, the scorers and the assists, the cards, each club's
// buying and selling, the squads' value and the runs of results. A club's name opens its squad (what anyone in the
// league may see: no tactic). No draft of its own: the design system's cards and the league table's look.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { nm } from '../../lib/names'
import { t } from '../../lib/i18n'
import { useSlot } from '../../stores/slot'
import { money } from '../../lib/format'
import ClubSquadDialog from '../../components/ClubSquadDialog.vue'

type Stats = components['schemas']['LeagueStats']
type Club = components['schemas']['StatsClub']
const TABS = { table: 'الترتيب', scorers: 'الهدافون', assists: 'صناع اللعب', cards: 'الانضباط', money: 'المالية', value: 'القيمة السوقية', runs: 'السلاسل' } as const
type Tab = keyof typeof TABS

const leagueId = ref<number | null>(null)
const s = ref<Stats | null>(null)
const tab = ref<Tab>('table')
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
</script>

<template>
  <div class="flex flex-col gap-4">
    <div>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('جدول الدوري') }}</h1>
      <p class="mt-1 text-sm text-text-muted">{{ $t('كل ما يراه أعضاء الدوري عن الموسم. اضغط اسم أي نادٍ لترى تشكيلته ولاعبيه.') }}</p>
    </div>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-[#FF8A8A]">{{ $t(error) }}</p>
    <p v-else-if="loaded && !leagueId" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('انضم إلى دوري واستلم فريقاً لترى إحصائياته.') }}</p>
    <p v-else-if="!loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>

    <template v-if="s">
      <div class="flex gap-1 overflow-x-auto rounded-xl bg-surface p-1" role="tablist" :aria-label="$t('أقسام الإحصائيات')">
        <button v-for="(label, key) in TABS" :key="key" type="button" role="tab" class="h-touch shrink-0 rounded-lg px-4 font-bold" :class="tab === key ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-selected="tab === key" @click="tab = key">{{ $t(label) }}</button>
      </div>
      <p v-if="empty && tab !== 'value'" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لم تُلعب مباريات في هذا الموسم بعد.') }}</p>
      <!-- [Sprint 21 E4.2] The season's leaders at a glance. -->
      <section v-else-if="tab === 'table'" class="grid grid-cols-2 gap-2 lg:grid-cols-4" :aria-label="$t('المتصدرون')">
        <div v-for="card in leaders" :key="card.label" class="flex flex-col gap-0.5 rounded-xl bg-surface p-3">
          <span class="text-xs text-text-muted">{{ $t(card.label) }}</span>
          <b class="truncate font-display text-base"><bdi>{{ card.name }}</bdi></b>
          <span class="font-numbers text-sm text-gold">{{ card.value }}</span>
        </div>
      </section>

      <section v-if="tab === 'table'" class="overflow-x-auto rounded-xl bg-surface p-3" :aria-label="$t('الترتيب المفصل')">
        <table class="w-full min-w-[640px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2">#</th><th class="text-start">{{ $t('النادي') }}</th><th>{{ $t('لعب') }}</th><th>{{ $t('فاز') }}</th><th>{{ $t('تعادل') }}</th><th>{{ $t('خسر') }}</th><th>{{ $t('له') }}</th><th>{{ $t('عليه') }}</th><th>{{ $t('الفارق') }}</th><th>{{ $t('معدل التسجيل') }}</th><th>{{ $t('معدل الاستقبال') }}</th><th>{{ $t('النقاط') }}</th></tr></thead>
          <tbody class="font-numbers">
            <tr v-for="r in s.table" :key="r.club.id" class="border-t border-text/5 text-center" :class="mine(r.club.id)">
              <td class="py-2">{{ r.position }}</td>
              <td class="text-start font-sans"><button type="button" class="flex min-h-touch items-center gap-2 font-bold hover:text-gold" @click="openSquad(r.club)"><img :src="r.club.crest_url" alt="" class="size-6" />{{ $nm(r.club.name) }}</button></td>
              <td>{{ r.played }}</td><td>{{ r.won }}</td><td>{{ r.drawn }}</td><td>{{ r.lost }}</td><td>{{ r.goals_for }}</td><td>{{ r.goals_against }}</td>
              <td dir="ltr">{{ r.goal_difference > 0 ? '+' : '' }}{{ r.goal_difference }}</td><td>{{ avg(r.goals_per_match_x100) }}</td><td>{{ avg(r.conceded_per_match_x100) }}</td>
              <td class="font-bold text-gold">{{ r.points }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section v-for="list in (['scorers', 'assists'] as const)" v-show="tab === list" :key="list" class="flex flex-col gap-1 rounded-xl bg-surface p-3" :aria-label="TABS[list]">
        <div v-for="(p, i) in s[list]" :key="p.player.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
          <span class="w-6 text-center font-numbers text-text-muted">{{ i + 1 }}</span>
          <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ $nm(p.player.name) }}</bdi></b><button type="button" class="text-xs text-text-muted hover:text-gold" @click="openSquad(p.club)">{{ $nm(p.club.name) }}</button></span>
          <b class="font-numbers text-xl text-gold">{{ list === 'scorers' ? p.goals : p.assists }}</b>
          <span class="w-20 text-xs text-text-muted">{{ list === 'scorers' ? $t('{v0} صناعة', { v0: p.assists }) : $t('{v0} هدف', { v0: p.goals }) }}</span>
        </div>
        <p v-if="!s[list].length" class="text-text-muted">{{ $t('لا أحد بعد.') }}</p>
      </section>

      <template v-if="tab === 'cards'">
        <section class="overflow-x-auto rounded-xl bg-surface p-3" :aria-label="$t('بطاقات الأندية')">
          <h2 class="mb-2 font-display text-lg font-bold">{{ $t('الأندية') }}</h2>
          <table class="w-full text-sm">
            <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('النادي') }}</th><th>{{ $t('صفراء') }}</th><th>{{ $t('حمراء') }}</th></tr></thead>
            <tbody class="font-numbers"><tr v-for="c in s.discipline.clubs" :key="c.club.id" class="border-t border-text/5 text-center" :class="mine(c.club.id)">
              <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(c.club)">{{ $nm(c.club.name) }}</button></td>
              <td><span class="inline-block h-4 w-3 rounded-sm bg-warning align-middle" aria-hidden="true" /> {{ c.yellow }}</td><td><span class="inline-block h-4 w-3 rounded-sm bg-live align-middle" aria-hidden="true" /> {{ c.red }}</td>
            </tr></tbody>
          </table>
        </section>
        <section v-for="[key, title] in ([['players', 'أكثر اللاعبين طرداً'], ['bookings', 'أكثر اللاعبين إنذاراً']] as const)" :key="key" class="flex flex-col gap-1 rounded-xl bg-surface p-3" :aria-label="title">
          <h2 class="mb-1 font-display text-lg font-bold">{{ $t(title) }}</h2>
          <div v-for="p in s.discipline[key]" :key="p.player.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
            <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ $nm(p.player.name) }}</bdi></b><span class="text-xs text-text-muted">{{ $nm(p.club.name) }}</span></span>
            <span class="font-numbers">🟨 {{ p.yellow }} · 🟥 {{ p.red }}</span>
          </div>
          <p v-if="!s.discipline[key].length" class="text-text-muted">{{ $t('لا أحد بعد.') }}</p>
        </section>
      </template>

      <section v-if="tab === 'money'" class="overflow-x-auto rounded-xl bg-surface p-3" :aria-label="$t('التقرير المالي')">
        <table class="w-full min-w-[520px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('النادي') }}</th><th>{{ $t('اشترى') }}</th><th>{{ $t('صفقات') }}</th><th>{{ $t('باع') }}</th><th>{{ $t('صفقات') }}</th><th>{{ $t('الصافي') }}</th></tr></thead>
          <tbody class="font-numbers"><tr v-for="f in s.finance" :key="f.club.id" class="border-t border-text/5 text-center" :class="mine(f.club.id)">
            <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(f.club)">{{ $nm(f.club.name) }}</button></td>
            <td dir="ltr">{{ money(f.bought) }}</td><td>{{ f.bought_count }}</td><td dir="ltr">{{ money(f.sold) }}</td><td>{{ f.sold_count }}</td>
            <td dir="ltr" :class="f.net >= 0 ? 'text-success' : 'text-[#FF8A8A]'">{{ f.net >= 0 ? '+' : '' }}{{ money(f.net) }}</td>
          </tr></tbody>
        </table>
      </section>

      <section v-if="tab === 'value'" class="flex flex-col gap-1 rounded-xl bg-surface p-3" :aria-label="$t('القيمة السوقية')">
        <div v-for="r in s.value" :key="r.club.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
          <span class="w-6 text-center font-numbers text-text-muted">{{ r.position }}</span>
          <img :src="r.club.crest_url" alt="" class="size-7" />
          <button type="button" class="min-w-0 flex-1 truncate text-start font-bold hover:text-gold" @click="openSquad(r.club)">{{ $nm(r.club.name) }}</button>
          <span class="text-xs text-text-muted">{{ $t('{v0} لاعباً', { v0: r.players }) }}</span>
          <b class="font-numbers text-gold" dir="ltr">{{ money(r.value) }}</b>
        </div>
      </section>

      <section v-if="tab === 'runs'" class="overflow-x-auto rounded-xl bg-surface p-3" :aria-label="$t('سلاسل النتائج')">
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
  </div>
</template>
