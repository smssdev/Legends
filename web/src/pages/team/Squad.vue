<script setup lang="ts">
// The squad (Sprint 16 W1), after the draft MobileSquad: count, strength and value, filters by line, and
// each player with his line, status, fitness, value and rating. A tap opens his card. [Sprint 20 W11] Its header also
// says the eleven's average, the place against the objective, the formation, the strongest player and the next
// opponent, and «فريق نادٍ آخر» opens any club's squad of the league (without its tactics).
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import LineBadge from '../../components/ui/LineBadge.vue'
import AsyncState from '../../components/ui/AsyncState.vue'
import UiTabs from '../../components/ui/UiTabs.vue'
import UiSelect from '../../components/ui/UiSelect.vue'
import PlayerTile from '../../components/ui/PlayerTile.vue'
import { LINES, money, strength, type Line } from '../../lib/format'
import TeamCard from './squad/TeamCard.vue'
import PlayersTable from './squad/PlayersTable.vue'
import RatingsTable from './squad/RatingsTable.vue'
import TransfersTable from './squad/TransfersTable.vue'
import type { SeasonData } from './squad/squad'
import PlayerCard from './PlayerCard.vue'
import { useTeam, type SquadPlayer } from './team'
import { t } from '../../lib/i18n'
import ClubSquadDialog from '../../components/ClubSquadDialog.vue'
import { api } from '../../api/client'
import { useBoard } from '../../stores/board'
import { useToast } from '../../stores/toast'

const board = useBoard()
const others = ref<{ id: number; name: string }[]>([])
const otherClub = ref<number | null>(null)
async function loadOthers() {
  if (others.value.length || !board.league) return
  const data = (await api.GET('/leagues/{league}/clubs', { params: { path: { league: board.league } } })).data
  others.value = (data?.clubs ?? []).filter((c) => c.id !== board.board?.club.id).map((c) => ({ id: c.id, name: c.name }))
}

const { leagueId, team, error, loaded, load: loadTeam } = useTeam()
// [Sprint 48 T2] The season's numbers (goals, ratings by round, the league's transfers) beside the squad.
const season = ref<SeasonData | null>(null)
async function load() {
  await loadTeam()
  if (!leagueId.value || !team.value) return
  try {
    season.value = ((await api.GET('/leagues/{league}/team/season', { params: { path: { league: leagueId.value } } })).data ?? null) as SeasonData | null
  } catch {
    /* the tables still show the squad without the season */
  }
}
// [Sprint 48 T2] The three tabs of the owner's screenshots: the players, the league's transfers, the ratings by round.
// [Sprint 56 W2] Plus the season's numbers as their own columns («الأداء»), as Squad.html.
const TABS = [{ key: 'players', label: 'اللاعبون' }, { key: 'stats', label: 'الأداء' }, { key: 'ratings', label: 'التقييمات' }, { key: 'transfers', label: 'الانتقالات' }]
type Tab = 'players' | 'stats' | 'ratings' | 'transfers'
const tab = ref<Tab>('players')
// The line as text for the phone's list (UiSelect's value).
const lineKey = computed({ get: () => line.value as string, set: (v: string) => (line.value = (v || 'all') as 'all' | Line) })
const LINE_TABS = computed(() => (['all', 'gk', 'def', 'mid', 'att'] as const).map((l) => ({ key: l, label: l === 'all' ? 'الكل' : LINES[l].plural, n: l === 'all' ? team.value?.players.length ?? 0 : count(l) })))
const line = ref<'all' | Line>('all')
const open = ref<SquadPlayer | null>(null)
// The list or the cards, remembered on this device [X29].
const view = ref<'list' | 'cards'>((() => { try { return localStorage.getItem('legends.squadView') === 'cards' ? 'cards' : 'list' } catch { return 'list' } })())
function setView(v: 'list' | 'cards') {
  view.value = v
  try { localStorage.setItem('legends.squadView', v) } catch {}
}
onMounted(load)
// [X87] A change made elsewhere on the screen (an undo from the toast, after the card closed): the squad again.
let again = 0
const changed = () => { clearTimeout(again); again = window.setTimeout(() => load(), 450) }
onMounted(() => window.addEventListener('glm:league-changed', changed))
onBeforeUnmount(() => window.removeEventListener('glm:league-changed', changed))
// [Sprint 39 S1] A player sold or listed from his card: the word, and the squad again.
const toast = useToast()
const saleOpen = ref(false)
function openSale(p: SquadPlayer) {
  saleOpen.value = true
  open.value = p
}
async function sold(text: string) {
  open.value = null
  if (text) toast.show(text)
  await load()
}

const players = computed(() => (team.value?.players ?? []).filter((p) => line.value === 'all' || p.line === line.value))
const count = (l: Line) => (team.value?.players ?? []).filter((p) => p.line === l).length
const captain = computed(() => team.value?.takers.captain?.player_id)
// [Sprint 21 E3.5] The list by line, each under its own heading: keepers, defenders, midfield, attack.
// [Sprint 39 S2] Each line's divider: its name and its letters, as the coach knows them.
const LINE_TITLE = { gk: 'حراسة المرمى · GK', def: 'خط الدفاع · DEF', mid: 'خط الوسط · MID', att: 'خط الهجوم · FWD' } as const
const groups = computed(() => (['gk', 'def', 'mid', 'att'] as const).map((l) => ({ line: l, players: players.value.filter((p) => p.line === l) })).filter((g) => g.players.length))

function status(p: SquadPlayer) {
  if (p.injured_matches) return { text: t('مصاب · {n} مباريات', { n: p.injured_matches }), tone: 'text-danger' }
  if (p.suspended_matches) return { text: t('موقوف · {n}', { n: p.suspended_matches }), tone: 'text-danger' }
  if (p.id === captain.value) return { text: 'القائد', tone: 'text-gold' }
  // [X84] On the transfer list.
  if (p.listed) return { text: 'معروض للبيع', tone: 'text-gold' }
  // The fatigue lines [Sprint 39 E2]: from 90% full, from 75% slower, under 75% a sharp drop and twice the injuries.
  if (p.fitness < 75) return { text: 'مرهق: خطر إصابة', tone: 'text-danger' }
  if (p.fitness < 90) return { text: 'متعب', tone: 'text-warning' }
  return { text: { starter: 'أساسي', bench: 'احتياط', reserve: 'خارج القائمة' }[p.role], tone: p.role === 'starter' ? 'text-success' : 'text-text-muted' }
}
</script>

<template>
  <!-- [Sprint 56 W2] Squad.html: the table fills the screen and scrolls inside itself under its tabs; the player's card a
       panel at the side; the team's card beside the table on a computer. -->
  <div class="squad">
    <h1 class="sr-only">{{ $t('الفريق') }}</h1>
    <AsyncState v-if="error || !team" :loading="!loaded && !error" :error="error || null" :empty="loaded && !team && !error" skeleton="row" :rows="6"
      empty-icon="team" empty-title="ليس لديك فريق بعد" empty-text="انضم لدوري أو أنشئ دورياً واختر فريقك." :empty-cta="{ label: 'دورياتي', to: '/leagues' }" @retry="load" />
    <template v-else>
      <div class="squad-main">
        <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
          <UiTabs v-model="tab" :items="TABS" label="الفريق" size="sm" />
          <!-- The lines: tabs where there is room, one list on a phone and a tablet (the table keeps its rows). -->
          <UiTabs v-if="tab !== 'transfers'" v-model="line" :items="LINE_TABS" label="الخطوط" tone="brand" size="sm" class="min-w-0 max-w-full max-xl:hidden" />
          <div v-if="tab !== 'transfers'" class="w-28 xl:hidden"><UiSelect v-model="lineKey" label="الخطوط" :options="LINE_TABS.map((l) => ({ value: l.key, label: `${$t(l.label)} ${l.n}` }))" /></div>
          <span class="flex-1" />
          <span class="text-caption text-text-muted max-lg:hidden"><span class="font-numbers">{{ team.players.length }}</span> {{ $t('لاعباً · القوة') }} <b class="font-numbers text-gold">{{ strength(team.club.strength_cp) }}</b> {{ $t('· القيمة') }} <span class="font-numbers">{{ money(team.squad_value) }}</span></span>
          <label>
            <span class="sr-only">{{ $t('فريق نادٍ آخر') }}</span>
            <select class="h-touch w-28 rounded-lg bg-surface px-1 text-caption" :value="''" @focus="loadOthers" @pointerdown="loadOthers" @change="otherClub = Number(($event.target as HTMLSelectElement).value) || null; ($event.target as HTMLSelectElement).value = ''">
              <option value="">{{ $t('فريق نادٍ آخر ▾') }}</option>
              <option v-for="c in others" :key="c.id" :value="c.id">{{ $nm(c.name) }}</option>
            </select>
          </label>
          <div v-if="tab === 'players'" class="flex shrink-0 gap-1 rounded-xl bg-surface p-1 max-md:hidden" role="group" :aria-label="$t('طريقة العرض')">
            <button v-for="[k, label, icon] in ([['list', 'جدول', 'M4 6h16M4 12h16M4 18h16'], ['cards', 'بطاقات', 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z']] as const)" :key="k" type="button" class="grid size-touch place-items-center rounded-lg" :class="view === k ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="view === k" :aria-label="$t(label)" @click="setView(k)">
              <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path :d="icon" /></svg>
            </button>
          </div>
        </div>

        <PlayersTable v-if="(tab === 'players' && view === 'list') || tab === 'stats'" :groups="groups" :season="season?.players ?? null" :status="status" :cols="tab === 'stats' ? 'stats' : 'list'" class="squad-scroll" @open="open = $event" @sale="openSale" />
        <!-- The cards, by line like the table. -->
        <div v-else-if="tab === 'players'" class="squad-scroll flex flex-col gap-5 overflow-y-auto overscroll-contain">
          <section v-for="grp in groups" :key="grp.line" class="flex flex-col gap-2" :aria-label="$t(LINES[grp.line].plural)">
            <h2 class="line-divider flex items-center gap-2 text-body font-bold" :style="{ '--line': `var(--color-line-${grp.line})` }">
              <LineBadge :line="grp.line" />{{ $t(LINE_TITLE[grp.line]) }}
              <span class="font-numbers text-text-muted">{{ grp.players.length }}</span>
            </h2>
            <ul class="grid grid-cols-3 gap-3 xl:grid-cols-4">
              <li v-for="p in grp.players" :key="p.id" class="v-card">
                <button type="button" class="block w-full text-start" :aria-label="p.name" @click="open = p">
                  <PlayerTile :name="p.name" :line="p.line as Line" :position="p.position" :overall="p.overall" :value="p.value" :fitness="p.fitness" :status="status(p).text" :status-tone="status(p).tone" :attributes="p.attributes as Record<string, number | null>" />
                </button>
              </li>
            </ul>
          </section>
        </div>
        <TransfersTable v-else-if="tab === 'transfers'" :transfers="season?.transfers ?? []" :club="team.club.name" class="squad-scroll overflow-y-auto" />
        <RatingsTable v-else-if="season" :groups="groups" :season="season" class="squad-scroll overflow-y-auto" @open="open = $event" />
        <AsyncState v-else loading skeleton="row" :rows="6" />
      </div>

      <TeamCard :team="team" :board="board.board" :season="season" class="squad-side" @open="open = $event" />
    </template>
    <PlayerCard v-if="open" :player="open" :sell="saleOpen" @close="open = null; saleOpen = false" @sold="sold" />
    <ClubSquadDialog v-if="otherClub && board.league" :league-id="board.league" :club-id="otherClub" @close="otherClub = null" />
  </div>
</template>

<style scoped>
.squad { display: grid; gap: var(--space-md); grid-template-columns: minmax(0, 1fr); }
.squad-main { display: flex; min-height: 0; flex-direction: column; gap: var(--space-sm); }
.squad-scroll { position: relative; flex: 1; min-height: 0; }
.squad-side { display: none; }
@media (min-width: 1200px) { .squad { grid-template-columns: minmax(0, 1fr) 21rem; } .squad-side { display: block; min-height: 0; overflow-y: auto; } }
/* [Sprint 39 S2] A line's divider: its colour first, then a hairline across to the end. */
.line-divider::after { content: ''; flex: 1; height: 1px; background: linear-gradient(to left, transparent, var(--line)); opacity: 0.5; }
:dir(rtl) .line-divider::after { background: linear-gradient(to right, transparent, var(--line)); }
</style>
