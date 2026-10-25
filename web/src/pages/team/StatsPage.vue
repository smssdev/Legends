<script setup lang="ts">
// The statistics centre [X17]: the season's table in detail, the scorers and the assists, the cards, each club's
// buying and selling, the squads' value and the runs of results. A club's name opens its squad (what anyone in the
// league may see: no tactic). No draft of its own: the design system's cards and the league table's look.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { count, money } from '../../lib/format'

type Stats = components['schemas']['LeagueStats']
type Club = components['schemas']['StatsClub']
const TABS = { table: 'الترتيب', scorers: 'الهدافون', assists: 'صناع اللعب', cards: 'الانضباط', money: 'المالية', value: 'القيمة السوقية', runs: 'السلاسل' } as const
type Tab = keyof typeof TABS

const leagueId = ref<number | null>(null)
const s = ref<Stats | null>(null)
const tab = ref<Tab>('table')
const error = ref('')
const loaded = ref(false)
const squad = ref<any | null>(null)
const squadBusy = ref(false)

const avg = (x100: number) => (x100 / 100).toFixed(2)
const RUN: Record<string, string> = { W: 'فوز', D: 'تعادل', L: 'خسارة' }
const RUN_CLASS: Record<string, string> = { W: 'bg-success text-on-gold', D: 'bg-surface-raised', L: 'bg-live text-white' }
const empty = computed(() => !s.value || s.value.matches === 0)

onMounted(async () => {
  try {
    leagueId.value = await currentLeague()
    if (leagueId.value) s.value = (await api.GET('/leagues/{league}/stats', { params: { path: { league: leagueId.value } } })).data!
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
})

async function openSquad(c: Club) {
  if (!leagueId.value) return
  squadBusy.value = true
  try {
    squad.value = (await api.GET('/leagues/{league}/clubs/{club}', { params: { path: { league: leagueId.value, club: c.id } } })).data
  } catch (e) {
    error.value = asApiError(e).message
  }
  squadBusy.value = false
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <div>
      <h1 class="font-display text-3xl font-extrabold">الإحصائيات</h1>
      <p class="mt-1 text-sm text-text-muted">كل ما يراه أعضاء الدوري عن الموسم. اضغط اسم أي نادٍ لترى تشكيلته ولاعبيه.</p>
    </div>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-[#FF8A8A]">{{ error }}</p>
    <p v-else-if="loaded && !leagueId" class="rounded-xl bg-surface p-4 text-text-muted">انضم إلى دوري واستلم فريقاً لترى إحصائياته.</p>
    <p v-else-if="!loaded" class="text-text-muted">جارٍ التحميل...</p>

    <template v-if="s">
      <div class="flex gap-1 overflow-x-auto rounded-xl bg-surface p-1" role="tablist" aria-label="أقسام الإحصائيات">
        <button v-for="(label, key) in TABS" :key="key" type="button" role="tab" class="h-touch shrink-0 rounded-lg px-4 font-bold" :class="tab === key ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-selected="tab === key" @click="tab = key">{{ label }}</button>
      </div>
      <p v-if="empty && tab !== 'value'" class="rounded-xl bg-surface p-4 text-text-muted">لم تُلعب مباريات في هذا الموسم بعد.</p>

      <section v-if="tab === 'table'" class="overflow-x-auto rounded-xl bg-surface p-3" aria-label="الترتيب المفصل">
        <table class="w-full min-w-[640px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2">#</th><th class="text-start">النادي</th><th>لعب</th><th>فاز</th><th>تعادل</th><th>خسر</th><th>له</th><th>عليه</th><th>الفارق</th><th>معدل التسجيل</th><th>معدل الاستقبال</th><th>النقاط</th></tr></thead>
          <tbody class="font-numbers">
            <tr v-for="r in s.table" :key="r.club.id" class="border-t border-text/5 text-center">
              <td class="py-2">{{ r.position }}</td>
              <td class="text-start font-sans"><button type="button" class="flex min-h-touch items-center gap-2 font-bold hover:text-gold" @click="openSquad(r.club)"><img :src="r.club.crest_url" alt="" class="size-6" />{{ r.club.name }}</button></td>
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
          <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ p.player.name }}</bdi></b><button type="button" class="text-xs text-text-muted hover:text-gold" @click="openSquad(p.club)">{{ p.club.name }}</button></span>
          <b class="font-numbers text-xl text-gold">{{ list === 'scorers' ? p.goals : p.assists }}</b>
          <span class="w-20 text-xs text-text-muted">{{ list === 'scorers' ? `${p.assists} صناعة` : `${p.goals} هدف` }}</span>
        </div>
        <p v-if="!s[list].length" class="text-text-muted">لا أحد بعد.</p>
      </section>

      <template v-if="tab === 'cards'">
        <section class="overflow-x-auto rounded-xl bg-surface p-3" aria-label="بطاقات الأندية">
          <h2 class="mb-2 font-display text-lg font-bold">الأندية</h2>
          <table class="w-full text-sm">
            <thead class="text-text-muted"><tr><th class="py-2 text-start">النادي</th><th>صفراء</th><th>حمراء</th></tr></thead>
            <tbody class="font-numbers"><tr v-for="c in s.discipline.clubs" :key="c.club.id" class="border-t border-text/5 text-center">
              <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(c.club)">{{ c.club.name }}</button></td>
              <td><span class="inline-block h-4 w-3 rounded-sm bg-warning align-middle" aria-hidden="true" /> {{ c.yellow }}</td><td><span class="inline-block h-4 w-3 rounded-sm bg-live align-middle" aria-hidden="true" /> {{ c.red }}</td>
            </tr></tbody>
          </table>
        </section>
        <section v-for="[key, title] in ([['players', 'أكثر اللاعبين طرداً'], ['bookings', 'أكثر اللاعبين إنذاراً']] as const)" :key="key" class="flex flex-col gap-1 rounded-xl bg-surface p-3" :aria-label="title">
          <h2 class="mb-1 font-display text-lg font-bold">{{ title }}</h2>
          <div v-for="p in s.discipline[key]" :key="p.player.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
            <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ p.player.name }}</bdi></b><span class="text-xs text-text-muted">{{ p.club.name }}</span></span>
            <span class="font-numbers">🟨 {{ p.yellow }} · 🟥 {{ p.red }}</span>
          </div>
          <p v-if="!s.discipline[key].length" class="text-text-muted">لا أحد بعد.</p>
        </section>
      </template>

      <section v-if="tab === 'money'" class="overflow-x-auto rounded-xl bg-surface p-3" aria-label="التقرير المالي">
        <table class="w-full min-w-[520px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">النادي</th><th>اشترى</th><th>صفقات</th><th>باع</th><th>صفقات</th><th>الصافي</th></tr></thead>
          <tbody class="font-numbers"><tr v-for="f in s.finance" :key="f.club.id" class="border-t border-text/5 text-center">
            <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(f.club)">{{ f.club.name }}</button></td>
            <td dir="ltr">{{ money(f.bought) }}</td><td>{{ f.bought_count }}</td><td dir="ltr">{{ money(f.sold) }}</td><td>{{ f.sold_count }}</td>
            <td dir="ltr" :class="f.net >= 0 ? 'text-success' : 'text-[#FF8A8A]'">{{ f.net >= 0 ? '+' : '' }}{{ money(f.net) }}</td>
          </tr></tbody>
        </table>
      </section>

      <section v-if="tab === 'value'" class="flex flex-col gap-1 rounded-xl bg-surface p-3" aria-label="القيمة السوقية">
        <div v-for="r in s.value" :key="r.club.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 first:border-0">
          <span class="w-6 text-center font-numbers text-text-muted">{{ r.position }}</span>
          <img :src="r.club.crest_url" alt="" class="size-7" />
          <button type="button" class="min-w-0 flex-1 truncate text-start font-bold hover:text-gold" @click="openSquad(r.club)">{{ r.club.name }}</button>
          <span class="text-xs text-text-muted">{{ r.players }} لاعباً</span>
          <b class="font-numbers text-gold" dir="ltr">{{ money(r.value) }}</b>
        </div>
      </section>

      <section v-if="tab === 'runs'" class="overflow-x-auto rounded-xl bg-surface p-3" aria-label="سلاسل النتائج">
        <table class="w-full min-w-[560px] text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">النادي</th><th>آخر 5</th><th>الحالية</th><th>أطول فوز</th><th>أطول تعادل</th><th>أطول خسارة</th></tr></thead>
          <tbody class="font-numbers"><tr v-for="r in s.streaks" :key="r.club.id" class="border-t border-text/5 text-center">
            <td class="py-2 text-start font-sans"><button type="button" class="font-bold hover:text-gold" @click="openSquad(r.club)">{{ r.club.name }}</button></td>
            <td><span class="inline-flex gap-1" dir="ltr"><span v-for="(k, i) in r.form" :key="i" class="grid size-6 place-items-center rounded-sm text-xs font-bold" :class="RUN_CLASS[k]" :title="RUN[k]">{{ k === 'W' ? 'ف' : k === 'D' ? 'ت' : 'خ' }}</span></span></td>
            <td class="font-sans">{{ r.current ? `${r.current.length} ${RUN[r.current.kind]}` : '-' }}</td>
            <td>{{ r.best.W }}</td><td>{{ r.best.D }}</td><td>{{ r.best.L }}</td>
          </tr></tbody>
        </table>
      </section>
    </template>

    <!-- A rival's squad: what anyone in the league may see. -->
    <div v-if="squad || squadBusy" class="fixed inset-0 z-40 flex items-end justify-center bg-black/60 p-3 md:items-center" role="dialog" aria-modal="true" aria-label="تشكيلة النادي" @click.self="squad = null">
      <div class="flex max-h-[85dvh] w-full max-w-xl flex-col gap-3 overflow-y-auto rounded-xl bg-surface p-4">
        <p v-if="squadBusy" class="text-text-muted">جارٍ التحميل...</p>
        <template v-else-if="squad">
          <div class="flex items-center gap-3">
            <img :src="squad.crest_url" alt="" class="size-10" />
            <div class="min-w-0 flex-1"><h2 class="truncate font-display text-xl font-extrabold">{{ squad.name }}</h2><p class="text-xs text-text-muted">{{ squad.coach?.name ?? 'الحاسوب' }} · {{ count(squad.players.length) }} لاعباً</p></div>
            <button type="button" class="size-touch rounded-md bg-surface-raised" aria-label="إغلاق" @click="squad = null">✕</button>
          </div>
          <div v-for="p in squad.players" :key="p.id" class="flex min-h-touch items-center gap-3 border-t border-text/5 text-sm">
            <span class="w-10 font-numbers text-xs text-text-muted" dir="ltr">{{ p.position }}</span>
            <span class="min-w-0 flex-1 truncate"><bdi>{{ p.name }}</bdi> <span class="text-xs text-text-muted">· {{ p.age }} سنة</span><span v-if="p.injured_matches" class="text-xs text-[#FF8A8A]"> · مصاب</span><span v-if="p.suspended_matches" class="text-xs text-warning"> · موقوف</span></span>
            <b class="font-numbers">{{ p.overall }}</b>
            <span class="w-16 text-end font-numbers text-xs text-text-muted" dir="ltr">{{ money(p.value) }}</span>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>
