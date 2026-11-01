<script setup lang="ts">
// The lineup editor (Sprint 16 W2), after the draft MobileLineup: the formation picker (24 and my own),
// a counter per line, "تحسين", the pitch, the bench and the rest of the squad. A player moves by dragging
// (pointer events: the same code for a finger and a mouse) or by tapping him and then the place he goes.
// Dropped on open grass, a starter stays where he is dropped, inside his line's band, like PES [X5].
// The server checks every rule and answers in Arabic; this screen only arranges.
// [Sprint 21 E5.2] Locked until «تعديل». [Sprint 27 W3, W4, W5: the owner asked for OSM's ease, 2026-10-30] No lock any
// more: every change saves itself a moment later (once the eleven is whole), and «تراجع» takes the last one back. A tap
// on any player opens the list to choose who goes there instead, the best for that place first. An outfield player
// may stand in any line, out of his own at the engine's lower share (shown on his card). The specialists are cards,
// each chosen from the whole squad by the role's skill.
import { t } from '../../lib/i18n'
import UiDialog from '../../components/ui/UiDialog.vue'
import UiSelect from '../../components/ui/UiSelect.vue'
import { computed, onMounted, ref } from 'vue'
import { nm } from '../../lib/names'
import { api, asApiError, ensureCsrf } from '../../api/client'
import UiButton from '../../components/ui/UiButton.vue'
import { money } from '../../lib/format'
import PlayerCard from './PlayerCard.vue'
import { barColor, useTeam, type Formation, type SquadPlayer } from './team'

const { leagueId, team, error, loaded, load } = useTeam()
const formations = ref<Formation[]>([])
const formation = ref('')
const starters = ref<(number | null)[]>([])
const bench = ref<number[]>([])
const saved = ref('')
const saving = ref(false)
// [Sprint 27 W3] Always open to change: kept for the drag code's guards.
const editing = ref(true)
const message = ref('')
// [Sprint 27 W3] The saved states before each change, for «تراجع»; and the save waiting to go.
const history = ref<string[]>([])
let pending = 0
const queued = ref(false)
const view = ref<'overall' | 'fitness' | 'age' | 'value'>('overall')
const card = ref<SquadPlayer | null>(null)
// The ten outfield places [x, y] (the keeper stays in goal), and the bands the server allows each line.
const places = ref<[number, number][]>([])
const bands = ref<Record<string, number[]>>({})
const across = ref<number[]>([30, 650])

onMounted(async () => {
  const [, f] = await Promise.all([load(), api.GET('/data/formations')])
  formations.value = f.data!.formations
  bands.value = f.data!.bands
  across.value = f.data!.across
  if (team.value) apply(team.value.lineup)
})

type Slot = { role: string; line: string; x: number; y: number }
function apply(l: { formation: string; starters: (number | null)[]; bench: number[]; slots: Slot[] }) {
  formation.value = l.formation
  starters.value = [...l.starters]
  bench.value = [...l.bench]
  places.value = l.slots.slice(1).map((s) => [s.x, s.y])
  if (!saved.value) saved.value = snapshot()
}
/** Another formation: its own places. */
function pick(name: string) {
  if (name === formation.value) return
  remember()
  formation.value = name
  const f = all.value.find((x) => x.name === name)
  if (f) places.value = f.slots.slice(1).map((s) => [s.x, s.y])
  later()
}
const snapshot = () => JSON.stringify([formation.value, starters.value, bench.value, places.value])
const dirty = computed(() => saved.value !== '' && snapshot() !== saved.value)

const players = computed(() => new Map((team.value?.players ?? []).map((p) => [p.id, p])))
const all = computed(() => [...formations.value, ...(team.value?.custom_formations ?? [])])
// [Sprint 30 Q7] Folded to two rows (the current one always among them) until «كل الخطط».
const FORMATIONS_FOLDED = 7
const allFormations = ref(false)
const shownFormations = computed(() => {
  if (allFormations.value) return all.value
  const first = all.value.slice(0, FORMATIONS_FOLDED)
  const cur = all.value.find((f) => f.name === formation.value)
  return cur && !first.includes(cur) ? [...first.slice(0, FORMATIONS_FOLDED - 1), cur] : first
})
const current = computed(() => {
  const f = all.value.find((x) => x.name === formation.value)
  if (!f) return undefined
  // The places the coach dragged them to.
  return { ...f, slots: f.slots.map((s, i) => (i > 0 && places.value[i - 1] ? { ...s, x: places.value[i - 1][0], y: places.value[i - 1][1] } : s)) }
})
const reserves = computed(() => {
  const used = new Set([...starters.value, ...bench.value])
  return (team.value?.players ?? []).filter((p) => !used.has(p.id))
})

/** A slot's place on the vertical pitch: depth up the screen, right-sided roles on the right. */
const place = (s: { x: number; y: number }) => ({ top: `${100 - (s.x / 720) * 100}%`, left: `${(s.y / 680) * 100}%` })
// [Sprint 30 Q7] Why a player cannot play, in words, wherever he is listed.
const unavailable = (p: SquadPlayer) => p.injured_matches ? t('مصاب: {v0} مباراة', { v0: p.injured_matches }) : p.suspended_matches ? t('موقوف: {v0} مباراة', { v0: p.suspended_matches }) : t('غير جاهز')
const shown = (p: SquadPlayer) => ({ overall: p.overall, fitness: `${p.fitness}%`, age: p.age, value: money(p.value) })[view.value]
/** The name on the pitch: the last word, or the last two when it is short ("Vinícius Jr." → "Vinícius Jr."). */
const short = (latin: string) => {
  // The name as the coach chose to see it [X40], shortened to its last word (two when the last is a short particle).
  const w = nm(latin).split(' ')
  return w.length > 1 && w[w.length - 1].length <= 3 ? w.slice(-2).join(' ') : w[w.length - 1]
}
// Chemistry [X22]: measured by the server on the saved eleven, so the links show until the lineup changes.
const chemistry = computed(() => team.value?.lineup.chemistry)
const chemColor = (score: number) => (score >= 85 ? 'var(--color-success)' : score < 50 ? 'var(--color-live)' : 'var(--color-gold)')
const LINK_COLOR = { green: 'var(--color-success)', yellow: 'var(--color-gold)', red: 'var(--color-live)' } as const
const links = computed(() => {
  if (dirty.value || !chemistry.value || !current.value) return []
  const at = (id: number) => {
    const i = starters.value.indexOf(id)
    const s = current.value!.slots[i]
    return s ? { x: (s.y / 680) * 100, y: 100 - (s.x / 720) * 100 } : null
  }
  return chemistry.value.links.flatMap((l) => {
    const [a, b] = [at(l.a), at(l.b)]
    return a && b ? [{ ...l, x1: a.x, y1: a.y, x2: b.x, y2: b.y }] : []
  })
})
// The mini cards on the pitch [X29], as the squad's cards: gold from 85, silver from 75, bronze under.
const tier = (overall: number) => (overall >= 85 ? 'gold' : overall >= 75 ? 'silver' : 'bronze')
const MINI = {
  gold: 'border-gold from-gold/30 to-surface text-gold',
  silver: 'border-chrome/70 from-silver/25 to-surface text-text',
  bronze: 'border-bronze from-bronze/35 to-surface text-text',
} as const

// Moving players: a "spot" is a slot on the pitch, a place on the bench, or the rest of the squad.
type Spot = { zone: 'slot' | 'bench' | 'reserve'; index: number }

function playerAt(s: Spot): number | null {
  if (s.zone === 'slot') return starters.value[s.index] ?? null
  if (s.zone === 'bench') return bench.value[s.index] ?? null
  return reserves.value[s.index]?.id ?? null
}

/** Move a player to another spot; whoever stood there takes his place. Dropping on the rest of the squad takes him out. */
function move(from: Spot, to: Spot) {
  const a = playerAt(from)
  if (a === null || (from.zone === to.zone && from.index === to.index)) return
  message.value = ''
  if (to.zone === 'reserve') {
    remember()
    if (from.zone === 'slot') starters.value[from.index] = null
    if (from.zone === 'bench') bench.value.splice(from.index, 1)
    return
  }
  const b = playerAt(to)
  if (from.zone === 'bench' && to.zone === 'bench') {
    remember()
    const list = bench.value.filter((_, i) => i !== from.index)
    list.splice(Math.min(to.index, list.length), 0, a)
    bench.value = list
    return
  }
  if (to.zone === 'bench' && b === null && bench.value.length >= 7) {
    message.value = 'الاحتياط 7 لاعبين على الأكثر.'
    return
  }
  // [Sprint 27 W4] Any outfield player in any outfield place; the goal only for a goalkeeper, and he only in goal.
  const keeper = (id: number | null) => id !== null && players.value.get(id)?.line === 'gk'
  const wrong = (id: number | null, slot: number) => id !== null && (slot === 0 ? !keeper(id) : keeper(id))
  if ((to.zone === 'slot' && wrong(a, to.index)) || (from.zone === 'slot' && wrong(b, from.index))) {
    message.value = 'خانة الحارس لحارس مرمى، والحارس مكانه في المرمى أو على الدكة.'
    return
  }
  remember()
  // The target takes him; the source takes whoever was there (or empties).
  if (to.zone === 'slot') starters.value[to.index] = a
  else if (b === null) bench.value.push(a)
  else bench.value[to.index] = a
  if (from.zone === 'slot') starters.value[from.index] = b
  else if (from.zone === 'bench') {
    if (b === null) bench.value.splice(from.index, 1)
    else bench.value[from.index] = b
  }
}

/** [Sprint 27 W3] Before a change: the state to go back to with «تراجع». */
function remember() {
  history.value = [...history.value.slice(-19), snapshot()]
}
/** Save a moment after the last change, once the eleven is whole (an empty place waits for its player). */
function later() {
  window.clearTimeout(pending)
  if (starters.value.some((x) => x === null)) {
    message.value = 'اختر لاعباً للخانة الفارغة، فتُحفظ التشكيلة.'
    return
  }
  queued.value = true
  pending = window.setTimeout(save, 600)
}
function undo() {
  const back = history.value.pop()
  if (!back) return
  history.value = [...history.value]
  ;[formation.value, starters.value, bench.value, places.value] = JSON.parse(back)
  message.value = ''
  later()
}

// [Sprint 27 W3, X2: the owner's most important point, 2026-10-30] Choosing who plays where, both ways, by taps alone
// (a drag still works): a tap on a place asks "who plays here?", the best for it first; a tap on a player off the pitch
// (or «انقله» on one on it) asks "where does he play?", every place with his rating there. Each row shows the rating the
// player will really play at in that place (the server's place_bp, as the engine plays him), so a striker in midfield
// is seen at once for what he gives. A player already in the eleven swaps with the one he replaces.
type Pick = { mode: 'place'; spot: Spot } | { mode: 'player'; id: number }
const picking = ref<Pick | null>(null)
const filter = ref<'best' | 'gk' | 'def' | 'mid' | 'att'>('best')
const choosing = computed<Spot | null>(() => (picking.value?.mode === 'place' ? picking.value.spot : null))
function tap(s: Spot) {
  const id = playerAt(s)
  if (s.zone === 'reserve' && id === null) return
  filter.value = 'best'
  // Off the pitch, a player: where does he play? A place on the pitch (or an empty bench place): who plays here?
  picking.value = s.zone !== 'slot' && id !== null ? { mode: 'player', id } : { mode: 'place', spot: s }
}
/** Where a player is now. */
function spotOf(id: number): Spot {
  const i = starters.value.indexOf(id)
  if (i >= 0) return { zone: 'slot', index: i }
  const j = bench.value.indexOf(id)
  if (j >= 0) return { zone: 'bench', index: j }
  return { zone: 'reserve', index: reserves.value.findIndex((p) => p.id === id) }
}
/** The rating a player plays at in a line: the server's share of his ability there (100% in his own line). */
const ratingAt = (p: SquadPlayer, line: string | undefined) =>
  line ? Math.floor((p.overall * ((p.place_bp as Record<string, number> | undefined)?.[line] ?? 10000)) / 10000) : p.overall
const shareAt = (p: SquadPlayer, line: string | undefined) => (line ? ((p.place_bp as Record<string, number> | undefined)?.[line] ?? 10000) / 100 : 100)
/** The goal for a goalkeeper, and a goalkeeper for the goal (the server's rule). */
const allowed = (p: SquadPlayer, slot: number) => (slot === 0 ? p.line === 'gk' : p.line !== 'gk')
const LINES = { gk: 'حراس', def: 'دفاع', mid: 'وسط', att: 'هجوم' } as const
const slotLabel = (i: number) => current.value?.slots[i]?.role ?? ''

/** "Who plays here?": the players for a place, the best rating there first. */
const options = computed(() => {
  const s = choosing.value
  if (!s || !team.value) return []
  const here = playerAt(s)
  const slot = s.zone === 'slot' ? current.value?.slots[s.index] : undefined
  return team.value.players
    .filter((p) => p.id !== here && (s.zone !== 'slot' || allowed(p, s.index)) && (filter.value === 'best' || p.line === filter.value))
    .map((p) => ({ p, rating: ratingAt(p, slot?.line), share: shareAt(p, slot?.line), from: spotOf(p.id) }))
    .sort((a, b) => b.rating - a.rating || b.p.fitness - a.p.fitness)
})
/** "Where does he play?": every place on the pitch with his rating there, then the bench and out. */
const places_ = computed(() => {
  const pk = picking.value
  if (pk?.mode !== 'player' || !current.value) return []
  const p = players.value.get(pk.id)
  if (!p) return []
  return current.value.slots
    .map((slot, i) => ({ i, slot, rating: ratingAt(p, slot.line), share: shareAt(p, slot.line), now: starters.value[i] ? players.value.get(starters.value[i]!) : undefined }))
    .filter((x) => allowed(p, x.i) && x.now?.id !== p.id)
    .sort((a, b) => b.rating - a.rating || a.i - b.i)
})
const pickedPlayer = computed(() => (picking.value?.mode === 'player' ? players.value.get(picking.value.id) : undefined))
function choose(id: number) {
  const to = choosing.value
  picking.value = null
  if (!to) return
  move(spotOf(id), to)
  later()
}
function goTo(to: Spot) {
  const pk = picking.value
  picking.value = null
  if (pk?.mode !== 'player') return
  move(spotOf(pk.id), to)
  later()
}
/** The one on this place, moved elsewhere: "where does he play?". */
function moveOccupant() {
  const s = choosing.value
  const id = s ? playerAt(s) : null
  if (id !== null) picking.value = { mode: 'player', id }
}
/** Out of the eleven, from the place being chosen for. */
function takeOut() {
  const s = choosing.value
  picking.value = null
  if (!s || playerAt(s) === null) return
  move(s, { zone: 'reserve', index: -1 })
  later()
}
const WHERE: Record<string, string> = { slot: 'أساسي', bench: 'احتياط', reserve: '' }
/** Starters playing out of their line, at the engine's lower share. */
const offLine = (i: number) => {
  const p = players.value.get(starters.value[i] ?? 0)
  const slot = current.value?.slots[i]
  return i > 0 && !!p && !!slot && shareAt(p, slot.line) < 100
}

// Dragging with pointer events: a ghost follows the finger; on release, the spot under it receives.
const drag = ref<{ from: Spot; id: number; x: number; y: number; moved: boolean } | null>(null)
function down(e: PointerEvent, s: Spot) {
  const id = playerAt(s)
  if (id === null || !editing.value) return
  drag.value = { from: s, id, x: e.clientX, y: e.clientY, moved: false }
  window.addEventListener('pointermove', follow)
  window.addEventListener('pointerup', up, { once: true })
  // [Sprint 30 Q7] A touch the phone takes back (a call, a system gesture) drops nothing anywhere: the drag ends.
  window.addEventListener('pointercancel', cancelDrag, { once: true })
}
function cancelDrag() {
  window.removeEventListener('pointermove', follow)
  window.removeEventListener('pointerup', up)
  edge = 0
  drag.value = null
}
function follow(e: PointerEvent) {
  if (!drag.value) return
  if (Math.hypot(e.clientX - drag.value.x, e.clientY - drag.value.y) > 8) drag.value.moved = true
  drag.value.x = e.clientX
  drag.value.y = e.clientY
  // On a phone the bench and the top of the pitch are not on one screen: near an edge, the page scrolls.
  edge = e.clientY < 80 ? -14 : e.clientY > window.innerHeight - 80 ? 14 : 0
  if (edge && !scrolling) scroll()
}
let edge = 0
let scrolling = false
function scroll() {
  if (!drag.value || !edge) {
    scrolling = false
    return
  }
  scrolling = true
  window.scrollBy(0, edge)
  requestAnimationFrame(scroll)
}
function up(e: PointerEvent) {
  window.removeEventListener('pointermove', follow)
  window.removeEventListener('pointercancel', cancelDrag)
  edge = 0
  const d = drag.value
  drag.value = null
  if (!d?.moved) return
  const el = document.elementFromPoint(e.clientX, e.clientY)?.closest<HTMLElement>('[data-spot]')
  if (el) {
    const [zone, index] = el.dataset.spot!.split(':')
    move(d.from, { zone: zone as Spot['zone'], index: Number(index) })
  } else if (d.from.zone === 'slot' && d.from.index > 0) {
    remember()
    place_(d.from.index, e)
  }
  later()
  // The click that follows a drag must not also select.
  suppress = true
  window.setTimeout(() => (suppress = false), 0)
}
let suppress = false

// A starter dropped on open grass stays there, held inside his line's band [X5].
const pitch = ref<HTMLElement | null>(null)
function place_(slot: number, e: PointerEvent) {
  const r = pitch.value?.getBoundingClientRect()
  const line = current.value?.slots[slot].line
  if (!r || !line || e.clientX < r.left || e.clientX > r.right || e.clientY < r.top || e.clientY > r.bottom) return
  const [from, to] = bands.value[line] ?? [0, 720]
  const clamp = (v: number, lo: number, hi: number) => Math.round(Math.min(hi, Math.max(lo, v)))
  const x = clamp((1 - (e.clientY - r.top) / r.height) * 720, from, to)
  const y = clamp(((e.clientX - r.left) / r.width) * 680, across.value[0], across.value[1])
  places.value[slot - 1] = [x, y]
  places.value = [...places.value]
  message.value = ''
}
/** The band a dragged starter may go to, drawn on the pitch while he moves. */
const band = computed(() => {
  const d = drag.value
  if (!d?.moved || d.from.zone !== 'slot' || d.from.index === 0) return null
  const [from, to] = bands.value[current.value?.slots[d.from.index].line ?? ''] ?? []
  return from === undefined ? null : { top: `${100 - (to / 720) * 100}%`, height: `${((to - from) / 720) * 100}%` }
})
const click = (s: Spot) => !suppress && tap(s)
const isSelected = (s: Spot) => (choosing.value?.zone === s.zone && choosing.value.index === s.index) || (picking.value?.mode === 'player' && playerAt(s) === picking.value.id)

async function improve() {
  if (!leagueId.value) return
  const { data } = await api.GET('/leagues/{league}/team/suggestion', { params: { path: { league: leagueId.value } } })
  remember()
  const keep = saved.value
  apply(data!.lineup)
  saved.value = keep
  later()
}

async function save() {
  if (!leagueId.value) return
  saving.value = true
  message.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/lineup', {
      params: { path: { league: leagueId.value } },
      body: { formation: formation.value, starters: starters.value as number[], bench: bench.value, positions: places.value },
    })
    team.value = data as typeof team.value
    saved.value = ''
    // A change made while this one was saving waits for its own save: the screen keeps it.
    if (!dirtyAgainst(team.value!.lineup)) apply(team.value!.lineup)
    else saved.value = JSON.stringify([team.value!.lineup.formation, team.value!.lineup.starters, team.value!.lineup.bench, team.value!.lineup.slots.slice(1).map((x) => [x.x, x.y])])
  } catch (e) {
    const err = asApiError(e)
    message.value = Object.values(err.errors)[0]?.[0] ?? err.message
    // Not saved: back to what the server holds.
    if (saved.value) [formation.value, starters.value, bench.value, places.value] = JSON.parse(saved.value)
  }
  queued.value = false
  saving.value = false
}
const dirtyAgainst = (l: { formation: string; starters: (number | null)[]; bench: number[] }) =>
  JSON.stringify([l.formation, l.starters, l.bench]) !== JSON.stringify([formation.value, starters.value, bench.value])

// Captain and set-piece takers [PLAN 2.16]. [Sprint 27 W5] Cards, each chosen from the whole squad by its skill;
// «تلقائي» lets the server choose the best of the eleven.
const ROLES = { captain: 'القائد', penalty: 'ضربات الجزاء', free_kick: 'الضربات الحرة', corner: 'الركنيات' } as const
const SKILL = { captain: 'القيادة', penalty: 'الجزاء', free_kick: 'الحرة', corner: 'العرضيات' } as const
type Role = keyof typeof ROLES
const takerRole = ref<Role | null>(null)
async function setTaker(role: Role, value: number | null) {
  takerRole.value = null
  if (!leagueId.value || !team.value) return
  const body: Record<string, number | null> = {}
  for (const r of Object.keys(ROLES) as Role[]) {
    const t = team.value.takers[r]
    body[r] = r === role ? value : (t?.chosen_id ?? null)
  }
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/takers', { params: { path: { league: leagueId.value } }, body })
    team.value = data as typeof team.value
  } catch (e) {
    message.value = asApiError(e).message
  }
}
const skillOf = (role: Role, id: number | null | undefined) => team.value?.takers[role]?.candidates?.find((c) => c.id === id)?.skill

// My own formations: ten cells on a 4 × 5 grid, the goalkeeper fixed [PLAN 2.15].
const ROWS = [['att', 'هجوم'], ['am', 'وسط هجومي'], ['dm', 'وسط دفاعي'], ['def', 'دفاع']] as const
const customOpen = ref(false)
const customNumber = ref(1)
const customName = ref('')
const cells = ref<string[]>([])
const customError = ref('')
const lineOf = (row: string) => (row === 'def' ? 'def' : row === 'att' ? 'att' : 'mid')
const customLines = computed(() => {
  const c = { def: 0, mid: 0, att: 0 }
  cells.value.forEach((k) => c[lineOf(k.split(':')[0]) as 'def']++)
  return c
})
const LIMITS = { def: [3, 6], mid: [2, 6], att: [1, 5] } as const
const within = (l: keyof typeof LIMITS) => customLines.value[l] >= LIMITS[l][0] && customLines.value[l] <= LIMITS[l][1]
function toggle(row: string, col: number) {
  const k = `${row}:${col}`
  cells.value = cells.value.includes(k) ? cells.value.filter((x) => x !== k) : cells.value.length < 10 ? [...cells.value, k] : cells.value
}
function openCustom() {
  const used = (team.value?.custom_formations ?? []).map((c) => c.number)
  customNumber.value = [1, 2, 3].find((n) => !used.includes(n)) ?? 1
  customName.value = `مخصصة ${customNumber.value}`
  cells.value = ['def:1', 'def:2', 'def:4', 'def:5', 'dm:3', 'am:2', 'am:4', 'att:1', 'att:3', 'att:5']
  customError.value = ''
  customOpen.value = true
}
async function saveCustom() {
  if (!leagueId.value) return
  customError.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/formations/{number}', {
      params: { path: { league: leagueId.value, number: customNumber.value } },
      body: { name: customName.value, cells: cells.value.map((k) => [k.split(':')[0] as 'def', Number(k.split(':')[1])]) },
    })
    team.value = data as typeof team.value
    remember()
    formation.value = `custom:${customNumber.value}`
    const f = all.value.find((x) => x.name === formation.value)
    if (f) places.value = f.slots.slice(1).map((s) => [s.x, s.y])
    customOpen.value = false
    later()
  } catch (e) {
    const err = asApiError(e)
    customError.value = Object.values(err.errors)[0]?.[0] ?? err.message
  }
}
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <div v-else-if="loaded && !team" class="rounded-xl bg-surface p-8 text-center">
      <p class="mb-3 text-text-muted">{{ $t('ليس لديك فريق بعد.') }}</p>
      <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink>
    </div>
    <template v-else-if="team && current">
      <header class="flex items-start justify-between gap-3">
        <div>
          <h1 class="font-display text-3xl font-extrabold">{{ $t('التشكيلة') }}</h1>
          <p class="text-sm text-text-muted">{{ $nm(team.club.name) }}<template v-if="team.lineup.auto && !dirty"> {{ $t('· تلقائية («تحسين»)') }}</template></p>
        </div>
        <!-- [Sprint 27 W3] No lock: saved by itself, and «تراجع» for the last change. -->
        <div class="flex items-center gap-2">
          <span class="text-xs text-text-muted" role="status">{{ saving || queued ? $t('يحفظ…') : dirty ? '' : $t('محفوظة ✓') }}</span>
          <UiButton variant="outline" :disabled="!history.length || saving" @click="undo">{{ $t('تراجع') }}</UiButton>
        </div>
      </header>

      <!-- [Sprint 30 Q7] The formations in a grid (two rows, then all), never a long sideways scroll. -->
      <div class="grid grid-cols-4 gap-2 sm:grid-cols-6" role="group" :aria-label="$t('الطريقة')">
        <button
          v-for="f in shownFormations"
          :key="f.name"
          type="button"
          class="h-12 min-w-0 truncate rounded-xl border px-2 font-numbers text-base font-bold sm:text-lg"
          :class="f.name === formation ? 'border-gold bg-surface-raised text-gold' : 'border-transparent bg-surface text-text-soft'"
          :aria-pressed="f.name === formation"
          :dir="f.name.startsWith('custom:') ? undefined : 'ltr'"
          @click="pick(f.name)"
        >{{ $t(f.label) }}</button>
        <button type="button" class="h-12 min-w-0 rounded-xl border border-dashed border-gold/50 px-2 text-sm font-bold text-gold" @click="openCustom">{{ $t('+ مخصصة') }}</button>
      </div>
      <button v-if="all.length > FORMATIONS_FOLDED" type="button" class="-mt-2 min-h-touch self-start text-sm font-bold text-gold" :aria-expanded="allFormations" @click="allFormations = !allFormations">
        {{ allFormations ? $t('خطط أقل') : $t('كل الخطط ({v0})', { v0: all.length }) }}</button>

      <div class="flex flex-wrap items-center gap-2">
        <span v-for="(label, l) in { def: 'دفاع', mid: 'وسط', att: 'هجوم' }" :key="l" class="flex h-10 items-center gap-2 rounded-xl bg-surface px-3 text-sm">
          <span class="size-2.5 rounded-full" :class="{ def: 'bg-line-def', mid: 'bg-line-mid', att: 'bg-line-att' }[l]" />{{ $t(label) }}
          <span class="font-numbers text-base font-bold">{{ current.lines[l] }}</span>
        </span>
        <!-- [Sprint 20 W10, W12] The server's best eleven (in the edit mode), and the screens next to this one. -->
        <UiButton variant="outline" class="ms-auto" @click="improve">{{ $t('أفضل تشكيلة') }}</UiButton>
        <RouterLink :to="{ name: 'tactics' }" class="flex h-10 items-center rounded-xl bg-surface px-3 text-sm font-bold">{{ $t('التكتيك ›') }}</RouterLink>
        <RouterLink :to="{ name: 'specialists' }" class="flex h-10 items-center rounded-xl bg-surface px-3 text-sm font-bold">{{ $t('الجهاز الفني ›') }}</RouterLink>
      </div>

      <div v-if="chemistry" class="flex items-center gap-3 rounded-xl bg-surface px-3 py-2">
        <span class="flex items-center gap-1 text-sm font-bold">{{ $t('الكيمياء') }}</span>
        <span class="h-2 flex-1 overflow-hidden rounded-full bg-surface-sunk" role="meter" :aria-valuenow="chemistry.score" aria-valuemin="0" aria-valuemax="100" :aria-label="$t('الكيمياء')">
          <span class="block h-full rounded-full" :style="{ width: `${chemistry.score}%`, background: chemColor(chemistry.score) }" />
        </span>
        <span class="font-numbers text-lg font-bold" :style="{ color: chemColor(chemistry.score) }">{{ chemistry.score }}</span>
      </div>
      <p v-if="chemistry && dirty" class="text-xs text-text-muted">{{ $t('احفظ التشكيلة لتُحسب الكيمياء وروابطها من جديد.') }}</p>

      <div class="flex gap-1 rounded-xl bg-surface-sunk p-1 text-sm" role="group" :aria-label="$t('العرض')">
        <button v-for="(label, v) in { overall: 'القوة', fitness: 'اللياقة', age: 'السن', value: 'القيمة' }" :key="v" type="button" class="h-10 flex-1 rounded-lg font-bold" :class="view === v ? 'bg-surface-raised text-gold' : 'text-text-soft'" :aria-pressed="view === v" @click="view = v">{{ $t(label) }}</button>
      </div>

      <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm" role="status">{{ $t(message) }}</p>

      <!-- [X32] The pitch under floodlights: mown stripes, a light pool in the middle and a dark edge, framed in emerald. -->
      <div ref="pitch" class="lineup-pitch relative mx-auto aspect-[68/90] w-full max-w-md select-none overflow-hidden rounded-xxl md:max-w-lg">
        <div class="pointer-events-none absolute inset-3 rounded-md border-2 border-white/40" />
        <div class="pointer-events-none absolute inset-x-3 top-1/2 border-t-2 border-white/40" />
        <div class="pointer-events-none absolute left-1/2 top-1/2 size-24 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white/40" />
        <div class="pointer-events-none absolute inset-x-[28%] bottom-3 h-[13%] border-2 border-b-0 border-white/40" />
        <div class="pointer-events-none absolute inset-x-[28%] top-3 h-[13%] border-2 border-t-0 border-white/40" />
        <div v-if="band" class="pointer-events-none absolute inset-x-0 border-y-2 border-dashed border-gold/70 bg-gold/15" :style="band" />
        <svg v-if="links.length" class="pointer-events-none absolute inset-0 size-full" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
          <line v-for="l in links" :key="`${l.a}-${l.b}`" :x1="l.x1" :y1="l.y1" :x2="l.x2" :y2="l.y2" :stroke="LINK_COLOR[l.color]" stroke-width="3" stroke-linecap="round" vector-effect="non-scaling-stroke" opacity="0.85" />
        </svg>
        <button
          v-for="(slot, i) in current.slots"
          :key="i"
          type="button"
          :data-spot="`slot:${i}`"
          class="absolute flex w-20 -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-0.5 transition-[top,left] duration-300 ease-out motion-reduce:transition-none"
          :class="editing ? 'touch-none' : ''"
          :style="place(slot)"
          :aria-label="$t('{v0}: {v1}', { v0: slot.role, v1: starters[i] ? players.get(starters[i]!)?.name : $t('فارغة') })"
          @touchmove="editing && $event.preventDefault()"
          @contextmenu="editing && $event.preventDefault()"
          @pointerdown="down($event, { zone: 'slot', index: i })"
          @click="click({ zone: 'slot', index: i })"
        >
          <template v-if="starters[i] && players.get(starters[i]!)">
            <!-- A mini card [X29]: gold, silver or bronze by rating, its line's colour on top, the number and the slot's role. -->
            <span
              class="mini-card relative flex h-[4.5rem] w-14 flex-col items-center justify-center overflow-hidden rounded-lg border-2 bg-gradient-to-b shadow-lg shadow-shade/50"
              :class="[MINI[tier(players.get(starters[i]!)!.overall)], isSelected({ zone: 'slot', index: i }) ? 'ring-4 ring-gold' : '', players.get(starters[i]!)!.available ? '' : 'opacity-60']"
            >
              <span class="absolute inset-x-0 top-0 h-1" :style="{ background: `var(--color-line-${slot.line})` }" aria-hidden="true" />
              <b class="font-numbers text-lg leading-none">{{ shown(players.get(starters[i]!)!) }}</b>
              <!-- [Sprint 27 W4] Out of his lines: he plays at the engine's lower share. -->
              <span v-if="offLine(i)" class="absolute end-0.5 top-1.5 rounded bg-warning px-0.5 font-numbers text-[9px] font-bold leading-tight text-on-gold" :title="$t('خارج مركزه: {v0}% من مستواه', { v0: shareAt(players.get(starters[i]!)!, slot.line) })">{{ shareAt(players.get(starters[i]!)!, slot.line) }}%</span>
              <span class="mt-0.5 font-numbers text-[10px] leading-none text-text-soft" dir="ltr">{{ slot.role }}</span>
              <!-- [Sprint 30 Q7] Why he cannot play, on the card itself: injured or suspended, and for how many matches. -->
              <span v-if="players.get(starters[i]!)!.injured_matches" class="absolute start-0.5 top-1.5 rounded bg-live px-0.5 font-numbers text-[9px] font-bold leading-tight text-white" :title="$t('مصاب: {v0} مباراة', { v0: players.get(starters[i]!)!.injured_matches })">✚{{ players.get(starters[i]!)!.injured_matches }}</span>
              <span v-else-if="players.get(starters[i]!)!.suspended_matches" class="absolute start-0.5 top-1.5 rounded bg-live px-0.5 font-numbers text-[9px] font-bold leading-tight text-white" :title="$t('موقوف: {v0} مباراة', { v0: players.get(starters[i]!)!.suspended_matches })">▮{{ players.get(starters[i]!)!.suspended_matches }}</span>
            </span>
            <span class="max-w-full truncate rounded bg-chrome px-1.5 text-xs font-extrabold text-on-chrome shadow" dir="auto">{{ short(players.get(starters[i]!)!.name) }}</span>
            <span class="h-1 w-10 rounded-full bg-bg/60"><span class="block h-full rounded-full" :class="barColor(players.get(starters[i]!)!.fitness)" :style="{ width: `${players.get(starters[i]!)!.fitness}%` }" /></span>
          </template>
          <span v-else class="flex size-12 items-center justify-center rounded-full border-2 border-dashed border-white/70 text-2xl text-white">+</span>
        </button>
      </div>

      <section aria-labelledby="h-bench" class="flex flex-col gap-2">
        <div class="flex items-center justify-between">
          <h2 id="h-bench" class="font-display text-xl font-extrabold">{{ $t('الاحتياط') }} <span class="font-numbers text-base text-text-muted">{{ bench.length }}/7</span></h2>
          <span class="text-sm text-text-muted">{{ $t('اضغط لاعباً لتختار من مكانه، أو اسحبه') }}</span>
        </div>
        <div class="flex gap-2 overflow-x-auto pb-1">
          <button
            v-for="(id, i) in bench"
            :key="id"
            type="button"
            :data-spot="`bench:${i}`"
            class="flex h-20 w-32 shrink-0 flex-col justify-between rounded-xl bg-surface p-2 text-start"
            :class="[isSelected({ zone: 'bench', index: i }) ? 'ring-2 ring-gold' : '', editing ? 'touch-none' : '']"
            @touchmove="editing && $event.preventDefault()"
          @pointerdown="down($event, { zone: 'bench', index: i })"
            @click="click({ zone: 'bench', index: i })"
          >
            <span class="flex items-center justify-between"><span class="font-numbers text-xl font-bold text-gold">{{ shown(players.get(id)!) }}</span><span class="text-xs text-text-muted">{{ players.get(id)!.position }}</span></span>
            <span class="truncate text-sm font-bold">{{ $nm(players.get(id)!.name) }}</span>
            <span v-if="!players.get(id)!.available" class="text-[11px] font-bold text-danger">{{ unavailable(players.get(id)!) }}</span>
          </button>
          <button
            v-if="bench.length < 7"
            type="button"
            :data-spot="`bench:${bench.length}`"
            class="flex h-20 w-32 shrink-0 items-center justify-center rounded-xl border-2 border-dashed border-text/20 text-sm text-text-muted"
            @click="click({ zone: 'bench', index: bench.length })"
          >{{ $t('مكان فارغ') }}</button>
        </div>
      </section>

      <section aria-labelledby="h-rest" class="flex flex-col gap-2" data-spot="reserve:-1">
        <h2 id="h-rest" class="font-display text-xl font-extrabold">{{ $t('باقي الفريق') }}</h2>
        <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
          <button
            v-for="(p, i) in reserves"
            :key="p.id"
            type="button"
            :data-spot="`reserve:${i}`"
            class="flex min-h-touch items-center gap-2 rounded-lg bg-surface p-2 text-start text-sm"
            :class="[isSelected({ zone: 'reserve', index: i }) ? 'ring-2 ring-gold' : '', p.available ? '' : 'opacity-60', editing ? 'touch-none' : '']"
            @touchmove="editing && $event.preventDefault()"
          @pointerdown="down($event, { zone: 'reserve', index: i })"
            @click="click({ zone: 'reserve', index: i })"
            @dblclick="card = p"
          >
            <span class="font-numbers text-lg font-bold text-gold">{{ shown(p) }}</span>
            <span class="min-w-0 flex-1 truncate">{{ $nm(p.name) }}<span v-if="!p.available" class="block text-[11px] font-bold text-danger">{{ unavailable(p) }}</span></span>
            <span class="text-xs text-text-muted">{{ p.position }}</span>
          </button>
        </div>
      </section>

      <!-- [Sprint 27 W5] The specialists: a card per role, chosen from the whole squad. -->
      <section class="flex flex-col gap-2" aria-labelledby="h-takers">
        <h2 id="h-takers" class="font-display text-xl font-extrabold">{{ $t('المتخصصون') }}</h2>
        <div class="grid grid-cols-2 gap-2 md:grid-cols-4">
          <button v-for="(label, role) in ROLES" :key="role" type="button" class="flex min-h-touch flex-col items-start gap-1 rounded-xl bg-surface p-3 text-start" @click="takerRole = role">
            <span class="text-xs text-text-muted">{{ $t(label) }}</span>
            <b class="w-full truncate">{{ $nm(players.get(team.takers[role]?.player_id ?? 0)?.name) || '—' }}</b>
            <span class="flex w-full items-center justify-between text-xs">
              <span class="font-numbers text-gold">{{ skillOf(role, team.takers[role]?.player_id) ?? '' }}</span>
              <span class="rounded-pill px-2" :class="team.takers[role]?.auto ? 'bg-surface-sunk text-text-muted' : 'bg-gold/15 text-gold'">{{ team.takers[role]?.auto ? $t('تلقائي') : $t('اختيارك') }}</span>
            </span>
          </button>
        </div>
      </section>
    </template>
    <p v-else class="text-text-muted">{{ $t('جارٍ التحميل…') }}</p>

    <div
      v-if="drag?.moved && players.get(drag.id)"
      class="pointer-events-none fixed z-50 flex size-14 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-[3px] border-gold bg-bg font-numbers text-lg font-bold shadow-lg"
      :style="{ left: `${drag.x}px`, top: `${drag.y}px` }"
    >{{ shown(players.get(drag.id)!) }}</div>

    <!-- [Sprint 27 W3, X2] Who plays here? Each with the rating he will play at in this place. -->
    <UiDialog :open="!!choosing" :title="choosing?.zone === 'slot' ? $t('من يلعب {v0}؟', { v0: slotLabel(choosing.index) }) : $t('من يجلس على الدكة؟')" @close="picking = null">
      <div v-if="choosing" class="flex flex-col gap-2">
        <div v-if="playerAt(choosing) !== null" class="grid grid-cols-3 gap-2">
          <button type="button" class="h-touch rounded-lg bg-surface-raised px-1 text-xs font-bold" @click="moveOccupant">{{ $t('انقله لمكان آخر') }}</button>
          <button type="button" class="h-touch rounded-lg bg-surface-raised px-1 text-xs font-bold" @click="takeOut">{{ $t('أخرجه من القائمة') }}</button>
          <button type="button" class="h-touch rounded-lg bg-surface-raised px-1 text-xs font-bold" @click="card = players.get(playerAt(choosing!)!) ?? null; picking = null">{{ $t('بطاقته') }}</button>
        </div>
        <div class="flex gap-1 rounded-lg bg-surface-sunk p-1 text-sm" role="group" :aria-label="$t('العرض')">
          <button v-for="(label, f) in { best: 'الأنسب', ...LINES }" :key="f" type="button" class="h-10 flex-1 rounded-md font-bold" :class="filter === f ? 'bg-surface-raised text-gold' : 'text-text-soft'" :aria-pressed="filter === f" @click="filter = f">{{ $t(label) }}</button>
        </div>
        <ul class="flex max-h-[58vh] flex-col gap-1 overflow-y-auto">
          <li v-for="o in options" :key="o.p.id">
            <button type="button" class="flex min-h-14 w-full items-center gap-3 rounded-lg bg-surface px-3 py-2 text-start active:bg-surface-raised" :class="o.p.available ? '' : 'opacity-60'" @click="choose(o.p.id)">
              <span class="flex w-12 shrink-0 flex-col items-center leading-none">
                <b class="font-numbers text-2xl" :class="o.share < 100 ? 'text-warning' : 'text-gold'">{{ o.rating }}</b>
                <span v-if="o.share < 100" class="font-numbers text-[10px] text-text-muted"><s>{{ o.p.overall }}</s> · {{ o.share }}%</span>
              </span>
              <span class="min-w-0 flex-1"><b class="block truncate">{{ $nm(o.p.name) }}</b>
                <span class="text-xs text-text-muted" dir="ltr">{{ o.p.position }}</span>
                <span v-if="o.share < 100" class="ms-1 text-xs text-warning">{{ $t('خارج مركزه') }}</span>
                <span v-if="!o.p.available" class="ms-1 text-xs text-danger">{{ $t('غير متاح') }}</span></span>
              <span class="flex shrink-0 flex-col items-end gap-1">
                <span class="h-1 w-10 rounded-full bg-bg/60"><span class="block h-full rounded-full" :class="barColor(o.p.fitness)" :style="{ width: `${o.p.fitness}%` }" /></span>
                <span v-if="o.from.zone === 'slot'" class="text-[10px] text-text-muted">{{ $t('يتبادل مع {v0}', { v0: slotLabel(o.from.index) }) }}</span>
                <span v-else-if="WHERE[o.from.zone]" class="text-[10px] text-text-muted">{{ $t(WHERE[o.from.zone]) }}</span>
              </span>
            </button>
          </li>
          <li v-if="!options.length" class="p-3 text-center text-sm text-text-muted">{{ $t('لا أحد في هذا الخط.') }}</li>
        </ul>
      </div>
    </UiDialog>

    <!-- [X2] Where does he play? Every place with his rating there, the best first; or the bench, or out. -->
    <UiDialog :open="!!pickedPlayer" :title="pickedPlayer ? $t('أين يلعب {v0}؟', { v0: short(pickedPlayer.name) }) : ''" @close="picking = null">
      <div v-if="pickedPlayer" class="flex flex-col gap-2">
        <p class="text-sm text-text-muted"><span dir="ltr">{{ pickedPlayer.position }}</span> · {{ $t('القوة') }} <b class="font-numbers text-gold">{{ pickedPlayer.overall }}</b></p>
        <ul class="grid max-h-[58vh] grid-cols-2 gap-1.5 overflow-y-auto">
          <li v-for="x in places_" :key="x.i">
            <button type="button" class="flex min-h-16 w-full flex-col items-start gap-0.5 rounded-lg bg-surface p-2 text-start active:bg-surface-raised" @click="goTo({ zone: 'slot', index: x.i })">
              <span class="flex w-full items-center justify-between">
                <b class="font-numbers text-sm" dir="ltr" :style="{ color: `var(--color-line-${x.slot.line})` }">{{ x.slot.role }}</b>
                <b class="font-numbers text-xl" :class="x.share < 100 ? 'text-warning' : 'text-gold'">{{ x.rating }}</b>
              </span>
              <span class="w-full truncate text-xs text-text-muted">{{ x.now ? $t('بدل {v0}', { v0: short(x.now.name) }) : $t('مكان فارغ') }}<template v-if="x.share < 100"> · {{ x.share }}%</template></span>
            </button>
          </li>
        </ul>
        <div class="grid grid-cols-2 gap-2">
          <button v-if="!bench.includes(pickedPlayer.id) && bench.length < 7" type="button" class="h-touch rounded-lg bg-surface-raised text-sm font-bold" @click="goTo({ zone: 'bench', index: bench.length })">{{ $t('إلى الاحتياط') }}</button>
          <button v-if="spotOf(pickedPlayer.id).zone !== 'reserve'" type="button" class="h-touch rounded-lg bg-surface-raised text-sm font-bold" @click="goTo({ zone: 'reserve', index: -1 })">{{ $t('أخرجه من القائمة') }}</button>
          <button type="button" class="h-touch rounded-lg bg-surface-raised text-sm font-bold" @click="card = pickedPlayer ?? null; picking = null">{{ $t('بطاقته') }}</button>
        </div>
      </div>
    </UiDialog>

    <!-- [Sprint 27 W5] A specialist: anyone in the squad, the best at it first. -->
    <UiDialog :open="!!takerRole" :title="takerRole ? ROLES[takerRole] : ''" @close="takerRole = null">
      <ul v-if="takerRole && team" class="flex max-h-[65vh] flex-col gap-1 overflow-y-auto">
        <li>
          <button type="button" class="flex min-h-touch w-full items-center justify-between rounded-lg px-3 font-bold" :class="team.takers[takerRole]?.chosen_id ? 'bg-surface' : 'bg-gold/15 text-gold'" @click="setTaker(takerRole!, null)">
            {{ $t('تلقائي: الأفضل من الأساسيين') }}
          </button>
        </li>
        <li v-for="c in team.takers[takerRole]?.candidates ?? []" :key="c.id">
          <button type="button" class="flex min-h-touch w-full items-center gap-2 rounded-lg px-3 py-2 text-start" :class="team.takers[takerRole]?.chosen_id === c.id ? 'bg-gold/15' : 'bg-surface'" @click="setTaker(takerRole!, c.id)">
            <span class="font-numbers w-8 text-lg font-bold text-gold">{{ c.skill }}</span>
            <span class="min-w-0 flex-1 truncate text-sm font-bold">{{ $nm(players.get(c.id)?.name) }}</span>
            <span class="text-xs" :class="c.on ? 'text-success' : 'text-text-muted'">{{ c.on ? $t('أساسي') : $t('ليس أساسياً') }}</span>
          </button>
        </li>
      </ul>
      <p v-if="takerRole" class="mt-2 text-xs text-text-muted">{{ $t('الرقم: {v0}', { v0: $t(SKILL[takerRole]) }) }}</p>
    </UiDialog>

    <PlayerCard v-if="card" :player="card" @close="card = null" />

    <!-- [X61] Headless UI's Dialog, from the top (it was a sheet from the bottom). -->
    <UiDialog :open="customOpen" title="تشكيلة مخصصة" @close="customOpen = false">
      <form class="flex flex-col gap-3" @submit.prevent="saveCustom">
        <div class="flex gap-2">
          <input v-model="customName" maxlength="30" class="h-12 flex-1 rounded-lg border border-text/10 bg-surface-sunk px-3" :aria-label="$t('الاسم')" />
          <UiSelect :model-value="String(customNumber)" label="الرقم" class="w-20" :options="[1, 2, 3].map((n) => ({ value: String(n), label: String(n) }))" @update:model-value="(v) => (customNumber = Number(v))" />
        </div>
        <div class="flex gap-2 text-sm">
          <span v-for="(label, l) in { def: 'دفاع', mid: 'وسط', att: 'هجوم' }" :key="l" class="rounded-lg px-2 py-1" :class="within(l) ? 'bg-success/15 text-success' : 'bg-live/15 text-danger'">
            {{ $t(label) }} <span class="font-numbers">{{ customLines[l] }}</span> ({{ LIMITS[l][0] }}–{{ LIMITS[l][1] }})
          </span>
          <span class="ms-auto font-numbers">{{ cells.length }}/10</span>
        </div>
        <div class="grid gap-1 rounded-xl bg-pitch p-2">
          <div v-for="[row, label] in ROWS" :key="row" class="grid grid-cols-5 gap-1" :aria-label="label">
            <button
              v-for="col in [1, 2, 3, 4, 5]"
              :key="col"
              type="button"
              class="flex h-11 items-center justify-center rounded-lg border-2"
              :class="cells.includes(`${row}:${col}`) ? 'border-white bg-bg' : 'border-white/30'"
              :aria-pressed="cells.includes(`${row}:${col}`)"
              :aria-label="`${label} ${col}`"
              @click="toggle(row, col)"
            >
              <span v-if="cells.includes(`${row}:${col}`)" class="size-3 rounded-full bg-gold" />
            </button>
          </div>
          <div class="flex h-11 items-center justify-center text-sm font-bold text-white">{{ $t('الحارس') }}</div>
        </div>
        <p v-if="customError" class="text-sm text-danger" role="alert">{{ $t(customError) }}</p>
        <div class="flex gap-2">
          <UiButton type="submit" block>{{ $t('احفظ التشكيلة') }}</UiButton>
          <UiButton variant="quiet" @click="customOpen = false">{{ $t('إلغاء') }}</UiButton>
        </div>
      </form>
    </UiDialog>
  </div>
</template>

<style scoped>
.lineup-pitch {
  background:
    radial-gradient(ellipse 70% 45% at 50% 50%, rgb(255 255 255 / 0.12), transparent 70%),
    radial-gradient(ellipse 120% 90% at 50% 50%, transparent 60%, rgb(0 0 0 / 0.35)),
    repeating-linear-gradient(0deg, var(--color-pitch-dark) 0, var(--color-pitch-dark) 7.5%, var(--color-pitch) 7.5%, var(--color-pitch) 15%);
  box-shadow: 0 0 0 3px var(--color-brand-dark), 0 0 0 5px color-mix(in srgb, var(--color-gold) 45%, transparent), 0 30px 60px -30px color-mix(in srgb, var(--color-shade) 90%, transparent);
}
/* A sheen across the top of each mini card, as on a printed card. */
.mini-card::after {
  content: "";
  position: absolute;
  inset: 0 0 55% 0;
  background: linear-gradient(180deg, rgb(255 255 255 / 0.22), transparent);
  pointer-events: none;
}
</style>
