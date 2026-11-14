<script setup lang="ts">
// [Sprint 20 W5] The club board, the first page of a slot (the owner's approved draft, Sprint20Drafts.html): the next
// match fills its top (both sides, their strength and last five, the countdown, the referee, the lineup and the
// tactics a tap away), then cards that open their screens: training, the mini table, the board's mood, the market,
// the stadium, the money, the friendlies and the quests. Every number from GET /team/summary (B1).
// [Sprint 56 W1] Rebuilt on the approved draft (docs/design/legends-ui/landscape/Office.html): one phone held sideways,
// no page scroll. The next match first (its three buttons), what waits (it was the bar's window) scrolling inside its
// card, the table around the club, and the clocks (training, the stadium, the market, the daily reward). The money,
// the friendlies, the quests and the news live in the dock's sections now (النادي، المباراة، المزيد).
import { computed, onMounted } from 'vue'
import Icon from '../../components/Icon.vue'
import AgendaPanel from '../../components/shell/AgendaPanel.vue'
import MilestoneCard from '../../components/shell/MilestoneCard.vue'
import AsyncState from '../../components/ui/AsyncState.vue'
import UiButton from '../../components/ui/UiButton.vue'
import UiCard from '../../components/ui/UiCard.vue'
import Explain from '../../components/ui/Explain.vue'
import { countdown, useNow } from '../../lib/clock'
import { REFEREE } from '../../lib/format'
import { useBoard } from '../../stores/board'
import { useSlot } from '../../stores/slot'

const store = useBoard()
const slot = useSlot()
const now = useNow()
const b = computed(() => store.board)
onMounted(() => store.load(slot.current?.league?.id ?? store.league, true))
const strength = (cp: number) => Math.round(cp / 100)
const FORM: Record<string, [string, string]> = { W: ['ف', 'bg-success text-on-gold'], D: ['ت', 'bg-surface-raised'], L: ['خ', 'bg-live text-white'] }
const MOOD: Record<string, [string, string, string]> = {
  calm: ['هادئة', 'تنتظر بداية الموسم', 'bg-surface-raised text-text-soft'],
  happy: ['مسرورة', 'أنت في الهدف أو أعلى', 'bg-success/20 text-success'],
  worried: ['قلقة', 'أنت تحت الهدف بقليل', 'bg-warning/20 text-warning'],
  angry: ['غاضبة', 'أنت بعيد عن الهدف', 'bg-live/20 text-danger'],
}
const leagueId = computed(() => store.league)
const waiting = computed(() => b.value?.pending.length ?? 0)
</script>

<template>
  <div class="office">
    <h1 class="sr-only">{{ $t('لوحة النادي') }}</h1>
    <AsyncState v-if="!b" loading skeleton="card" :rows="3" class="office-wait" />
    <template v-else>
      <!-- The next match. -->
      <section class="office-next" :aria-label="$t('المباراة القادمة')">
        <template v-if="b.match">
          <div class="flex flex-wrap items-center gap-x-3 text-caption text-text-muted">
            <span class="flex-1">{{ $t(b.match.competition === 'league' ? 'الدوري · الجولة {v0}' : 'الكأس', { v0: b.match.round }) }} · {{ $t(b.match.venue === 'home' ? 'على أرضك' : 'خارج أرضك') }}</span>
            <span class="max-lg:hidden">{{ $t('الحكم: {v0}', { v0: b.match.referee ? $t(REFEREE[b.match.referee] ?? b.match.referee) : $t('يُعيَّن قبل المباراة بنصف ساعة') }) }}</span>
          </div>
          <div class="office-vs">
            <div v-for="(side, i) in [b.match.club, b.match.opponent]" :key="side.id" class="flex min-w-0 flex-col items-center gap-0.5" :style="{ order: i * 2 }">
              <img :src="side.crest_url" alt="" class="office-crest drop-shadow" loading="lazy" decoding="async" />
              <b class="max-w-full truncate text-body-lg">{{ $nm(side.name) }}</b>
              <span class="flex items-center gap-1.5"><Explain v-if="i === 0" what="strength" :league-id="leagueId"><span class="font-numbers text-title text-brand-light">{{ strength(side.strength_cp) }}</span></Explain><span v-else class="font-numbers text-title text-brand-light">{{ strength(side.strength_cp) }}</span>
                <span class="flex gap-0.5 max-md:hidden" :aria-label="$t('آخر النتائج')">
                  <span v-for="(r, j) in side.form" :key="j" class="grid size-5 place-items-center rounded-full text-caption font-bold leading-none" :class="FORM[r][1]">{{ $t(FORM[r][0]) }}</span>
                </span></span>
            </div>
            <div class="order-1 flex flex-col items-center gap-0.5">
              <RouterLink v-if="b.match.status === 'live'" :to="b.match.match_id ? `/live/${b.match.match_id}` : '/match'" class="flex min-h-touch items-center gap-1.5 rounded-pill bg-live px-3 font-bold text-white"><span class="size-2 animate-pulse rounded-full bg-white" />{{ $t('مباشر الآن') }}</RouterLink>
              <template v-else>
                <span class="text-caption text-text-muted">{{ $t('تبدأ بعد') }}</span>
                <b class="office-cd font-numbers leading-none text-gold" dir="ltr">{{ countdown(b.match.scheduled_at, now) || '00:00:00' }}</b>
              </template>
            </div>
          </div>
          <!-- The lineup's state: a warning row when it needs the coach; ready, a tick on its button (and the row on a computer). -->
          <RouterLink to="/lineup" class="office-ready flex min-h-touch items-center gap-2 rounded-lg bg-surface-sunk px-3 py-1" :class="b.lineup.ready ? 'is-ready' : 'ring-1 ring-live/60'">
            <span class="min-w-0 flex-1 truncate"><b class="text-body">{{ $t(b.lineup.ready ? 'التشكيلة جاهزة' : 'في تشكيلتك مصاب أو موقوف') }}</b>
              <span class="text-caption text-text-muted"> · <bdi dir="ltr">{{ b.lineup.formation.replace(/^custom:.*/, '') }}</bdi><template v-if="b.lineup.auto"> · {{ $t('اختارها المساعد') }}</template></span></span>
            <span :class="b.lineup.ready ? 'text-success' : 'text-live'" aria-hidden="true"><Icon v-if="b.lineup.ready" name="check" :size="16" /><template v-else>!</template></span>
          </RouterLink>
          <div class="grid grid-cols-[1.3fr_1fr_1fr] gap-2">
            <UiButton to="/lineup" size="sm">{{ $t('التشكيلة') }}<span v-if="b.lineup.ready" aria-hidden="true"><Icon name="check" :size="16" /></span></UiButton>
            <UiButton to="/tactics" size="sm" variant="quiet">{{ $t('التكتيك') }}</UiButton>
            <UiButton to="/match" size="sm" variant="quiet" class="!px-2">{{ $t('الخصم') }}</UiButton>
          </div>
        </template>
        <p v-else class="grid flex-1 place-items-center text-text-muted">{{ $t('لا مباراة قادمة الآن.') }}</p>
      </section>

      <UiCard class="office-todo" title="ما ينتظرك">
        <template #action><span class="font-numbers text-caption text-text-muted">{{ waiting }}</span></template>
        <!-- [Sprint 64 W11] A player's milestone, until seen. -->
        <MilestoneCard v-if="b.milestones?.length && leagueId" :items="b.milestones" :league-id="leagueId" />
        <AgendaPanel kind="pending" inline />
      </UiCard>

      <UiCard class="office-table">
        <RouterLink :to="leagueId ? `/leagues/${leagueId}` : '/stats'" class="flex min-h-touch items-center gap-2 font-display text-title">
          <Icon name="league" :size="18" />{{ $t('الترتيب') }}<span class="ms-auto text-caption text-gold">{{ $t('الكل ›') }}</span>
        </RouterLink>
        <table class="w-full text-body">
          <caption class="sr-only">{{ $t('الترتيب المصغر') }}</caption>
          <tbody>
            <tr v-for="r in b.standings.top" :key="r.id" class="border-t border-text/5" :class="r.mine ? 'text-gold' : ''">
              <td class="w-6 py-1.5 font-numbers text-text-muted">{{ r.position }}</td><td class="py-1.5"><bdi>{{ $nm(r.name) }}</bdi></td><td class="py-1.5 text-end font-numbers text-body-lg">{{ r.points }}</td>
            </tr>
          </tbody>
        </table>
        <div v-if="b.board" class="mt-auto flex items-center gap-2 text-caption">
          <span class="text-text-muted">{{ $t('الإدارة') }}</span>
          <span class="rounded-pill px-2 py-0.5 font-bold" :class="MOOD[b.board.mood][2]">{{ $t(MOOD[b.board.mood][0]) }}</span>
          <span class="min-w-0 flex-1 truncate text-text-muted">{{ $t('الهدف: المركز {v0} أو أعلى', { v0: b.board.target }) }}</span>
        </div>
      </UiCard>

      <UiCard class="office-clocks" title="العدّادات">
        <AgendaPanel kind="timers" inline />
      </UiCard>
    </template>
  </div>
</template>

<style scoped>
/* [Sprint 56 W1] Office.html: on a phone held sideways the next match and the clocks in one column, what waits in the
   other; from 900px the table between them. Every card keeps its height and scrolls inside. */
.office {
  display: grid;
  gap: var(--space-sm);
  grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr);
  grid-template-rows: auto minmax(0, 1fr);
  grid-template-areas: "next todo" "clocks todo";
}
.office-wait { grid-column: 1 / -1; }
.office-next { grid-area: next; }
.office-todo { grid-area: todo; min-height: 0; }
.office-clocks { grid-area: clocks; min-height: 0; }
.office-table { display: none; min-height: 0; overflow-y: auto; }
.office-todo, .office-clocks { position: relative; overflow: hidden; }
@media (min-width: 900px) {
  .office { grid-template-columns: minmax(0, 1.3fr) minmax(0, 1fr) minmax(0, 1fr); grid-template-areas: "next table todo" "clocks table todo"; }
  .office-table { display: flex; grid-area: table; }
}
@media (min-width: 1200px) { .office { gap: var(--space-lg); } }
.office-next {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
  min-width: 0;
  padding: var(--space-md);
  border-radius: var(--radius-xl);
  border: 1px solid color-mix(in srgb, var(--color-gold) 35%, transparent);
  background: radial-gradient(120% 90% at 50% 0%, color-mix(in srgb, var(--color-brand) 25%, var(--color-panel)), var(--color-panel));
}
.office-vs { display: grid; grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr); align-items: center; gap: var(--space-sm); text-align: center; }
.office-crest { width: 2.25rem; height: 2.25rem; }
.office-ready.is-ready { display: none; }
@media (min-height: 600px) { .office-ready.is-ready { display: flex; } }
.office-cd { font-size: var(--text-headline); }
@media (min-width: 900px) and (min-height: 600px) { .office-crest { width: 4rem; height: 4rem; } .office-cd { font-size: var(--text-display); } }
</style>
