<script setup lang="ts">
// The lineup editor (Sprint 16 W2), after the draft MobileLineup: the formation picker (24 and my own),
// a counter per line, "تحسين", the pitch, the bench and the rest of the squad. A player moves by dragging
// (pointer events: the same code for a finger and a mouse) or by tapping him and then the place he goes.
// Dropped on open grass, a starter stays where he is dropped, inside his line's band, like PES [X5].
// The server checks every rule and answers in Arabic; this screen only arranges.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import HelpTip from '../../components/ui/HelpTip.vue'
import UiButton from '../../components/ui/UiButton.vue'
import { useGlossary } from '../../lib/glossary'
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
const message = ref('')
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
  formation.value = name
  const f = all.value.find((x) => x.name === name)
  if (f) places.value = f.slots.slice(1).map((s) => [s.x, s.y])
}
const snapshot = () => JSON.stringify([formation.value, starters.value, bench.value, places.value])
const dirty = computed(() => saved.value !== '' && snapshot() !== saved.value)

const players = computed(() => new Map((team.value?.players ?? []).map((p) => [p.id, p])))
const all = computed(() => [...formations.value, ...(team.value?.custom_formations ?? [])])
const current = computed(() => {
  const f = all.value.find((x) => x.name === formation.value)
  if (!f) return undefined
  // The places the coach dragged them to.
  return { ...f, slots: f.slots.map((s, i) => (i > 0 && places.value[i - 1] ? { ...s, x: places.value[i - 1][0], y: places.value[i - 1][1] } : s)) }
})
// Only for a quick message when dragging: the server is the one that decides [X5].
const POSITION_LINE: Record<string, string> = {
  GK: 'gk', CB: 'def', LB: 'def', RB: 'def', LWB: 'def', RWB: 'def', CDM: 'mid', CM: 'mid', CAM: 'mid', LM: 'mid', RM: 'mid', LW: 'att', RW: 'att', ST: 'att', CF: 'att',
}
const LINE_NAME: Record<string, string> = { gk: 'حراسة المرمى', def: 'الدفاع', mid: 'الوسط', att: 'الهجوم' }
function fitsLine(id: number, line: string) {
  const p = players.value.get(id)
  if (!p) return true
  const lines = new Set([p.line, ...(p.alt_positions ?? '').split(',').map((a) => POSITION_LINE[a.trim()]).filter(Boolean)])
  return lines.has(line)
}
const reserves = computed(() => {
  const used = new Set([...starters.value, ...bench.value])
  return (team.value?.players ?? []).filter((p) => !used.has(p.id))
})

/** A slot's place on the vertical pitch: depth up the screen, right-sided roles on the right. */
const place = (s: { x: number; y: number }) => ({ top: `${100 - (s.x / 720) * 100}%`, left: `${(s.y / 680) * 100}%` })
const shown = (p: SquadPlayer) => ({ overall: p.overall, fitness: `${p.fitness}%`, age: p.age, value: money(p.value) })[view.value]
/** The name on the pitch: the last word, or the last two when it is short ("Vinícius Jr." → "Vinícius Jr."). */
const short = (name: string) => {
  const w = name.split(' ')
  return w.length > 1 && w[w.length - 1].length <= 3 ? w.slice(-2).join(' ') : w[w.length - 1]
}
// Chemistry [X22]: measured by the server on the saved eleven, so the links show until the lineup changes.
const g = useGlossary()
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
const ring = (line: string) => ({ gk: 'border-[#F5B82E]', def: 'border-[#3B82F6]', mid: 'border-[#22A35A]', att: 'border-[#F08A3C]' })[line] ?? 'border-text/30'

// Moving players: a "spot" is a slot on the pitch, a place on the bench, or the rest of the squad.
type Spot = { zone: 'slot' | 'bench' | 'reserve'; index: number }
const selected = ref<Spot | null>(null)

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
    if (from.zone === 'slot') starters.value[from.index] = null
    if (from.zone === 'bench') bench.value.splice(from.index, 1)
    return
  }
  const b = playerAt(to)
  if (from.zone === 'bench' && to.zone === 'bench') {
    const list = bench.value.filter((_, i) => i !== from.index)
    list.splice(Math.min(to.index, list.length), 0, a)
    bench.value = list
    return
  }
  if (to.zone === 'bench' && b === null && bench.value.length >= 7) {
    message.value = 'الاحتياط 7 لاعبين على الأكثر.'
    return
  }
  // Each in his own line: a striker on the wing, never in midfield or defence [X5].
  const slots = current.value?.slots ?? []
  const wrong = (id: number | null, slot: number) => id !== null && slot > 0 && !fitsLine(id, slots[slot].line)
  if ((to.zone === 'slot' && wrong(a, to.index)) || (from.zone === 'slot' && wrong(b, from.index))) {
    const [id, slot] = to.zone === 'slot' && wrong(a, to.index) ? [a, to.index] : [b!, from.index]
    const p = players.value.get(id)!
    message.value = `${p.name} (${p.position}) لا يلعب في ${LINE_NAME[slots[slot].line]}. ضع كل لاعب في خطه، ويتبادل المراكز داخله.`
    return
  }
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

function tap(s: Spot) {
  if (!selected.value) {
    if (playerAt(s) !== null) selected.value = s
    return
  }
  move(selected.value, s)
  selected.value = null
}

// Dragging with pointer events: a ghost follows the finger; on release, the spot under it receives.
const drag = ref<{ from: Spot; id: number; x: number; y: number; moved: boolean } | null>(null)
function down(e: PointerEvent, s: Spot) {
  const id = playerAt(s)
  if (id === null) return
  drag.value = { from: s, id, x: e.clientX, y: e.clientY, moved: false }
  window.addEventListener('pointermove', follow)
  window.addEventListener('pointerup', up, { once: true })
  window.addEventListener('pointercancel', up, { once: true })
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
  edge = 0
  const d = drag.value
  drag.value = null
  if (!d?.moved) return
  const el = document.elementFromPoint(e.clientX, e.clientY)?.closest<HTMLElement>('[data-spot]')
  if (el) {
    const [zone, index] = el.dataset.spot!.split(':')
    move(d.from, { zone: zone as Spot['zone'], index: Number(index) })
  } else if (d.from.zone === 'slot' && d.from.index > 0) place_(d.from.index, e)
  selected.value = null
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
const isSelected = (s: Spot) => selected.value?.zone === s.zone && selected.value.index === s.index

async function improve() {
  if (!leagueId.value) return
  const { data } = await api.GET('/leagues/{league}/team/suggestion', { params: { path: { league: leagueId.value } } })
  const keep = saved.value
  apply(data!.lineup)
  saved.value = keep
  message.value = 'هذه أفضل تشكيلة الآن. اضغط «حفظ» لتثبيتها.'
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
    apply(team.value!.lineup)
    message.value = 'حُفظت التشكيلة.'
  } catch (e) {
    const err = asApiError(e)
    message.value = Object.values(err.errors)[0]?.[0] ?? err.message
  }
  saving.value = false
}

// Captain and set-piece takers [PLAN 2.16]: among the saved starters; empty = automatic.
const ROLES = { captain: 'القائد', penalty: 'ضربات الجزاء', free_kick: 'الضربات الحرة', corner: 'الركنيات' } as const
type Role = keyof typeof ROLES
async function setTaker(role: Role, value: string) {
  if (!leagueId.value || !team.value) return
  const body: Record<string, number | null> = {}
  for (const r of Object.keys(ROLES) as Role[]) {
    const t = team.value.takers[r]
    body[r] = r === role ? (value ? Number(value) : null) : t && !t.auto ? (t.player_id ?? null) : null
  }
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/takers', { params: { path: { league: leagueId.value } }, body })
    team.value = data as typeof team.value
  } catch (e) {
    message.value = asApiError(e).message
  }
}

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
    formation.value = `custom:${customNumber.value}`
    customOpen.value = false
  } catch (e) {
    const err = asApiError(e)
    customError.value = Object.values(err.errors)[0]?.[0] ?? err.message
  }
}
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <div v-else-if="loaded && !team" class="rounded-xl bg-surface p-8 text-center">
      <p class="mb-3 text-text-muted">ليس لديك فريق بعد.</p>
      <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink>
    </div>
    <template v-else-if="team && current">
      <header class="flex items-start justify-between gap-3">
        <div>
          <h1 class="font-display text-3xl font-extrabold">التشكيلة</h1>
          <p class="text-sm text-text-muted">{{ team.club.name }}<template v-if="team.lineup.auto && !dirty"> · تلقائية («تحسين»)</template></p>
        </div>
        <UiButton :disabled="!dirty || saving" @click="save">{{ saving ? 'يحفظ…' : 'حفظ' }}</UiButton>
      </header>

      <div class="flex gap-2 overflow-x-auto pb-1" aria-label="الطريقة">
        <button
          v-for="f in all"
          :key="f.name"
          type="button"
          class="h-12 shrink-0 rounded-xl border px-4 font-numbers text-lg font-bold"
          :class="f.name === formation ? 'border-gold bg-surface-raised text-gold' : 'border-transparent bg-surface text-text-soft'"
          :aria-pressed="f.name === formation"
          :dir="f.name.startsWith('custom:') ? undefined : 'ltr'"
          @click="pick(f.name)"
        >{{ f.label }}</button>
        <button type="button" class="h-12 shrink-0 rounded-xl border border-dashed border-gold/50 px-4 font-bold text-gold" @click="openCustom">+ مخصصة</button>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <span v-for="(label, l) in { def: 'دفاع', mid: 'وسط', att: 'هجوم' }" :key="l" class="flex h-10 items-center gap-2 rounded-xl bg-surface px-3 text-sm">
          <span class="size-2.5 rounded-full" :class="{ def: 'bg-[#3B82F6]', mid: 'bg-[#22A35A]', att: 'bg-[#F08A3C]' }[l]" />{{ label }}
          <span class="font-numbers text-base font-bold">{{ current.lines[l] }}</span>
        </span>
        <UiButton variant="outline" class="ms-auto" @click="improve">تحسين</UiButton>
      </div>

      <div v-if="chemistry" class="flex items-center gap-3 rounded-xl bg-surface px-3 py-2">
        <span class="flex items-center gap-1 text-sm font-bold">الكيمياء<HelpTip :text="g.chemistry" label="الكيمياء" /></span>
        <span class="h-2 flex-1 overflow-hidden rounded-full bg-surface-sunk" role="meter" :aria-valuenow="chemistry.score" aria-valuemin="0" aria-valuemax="100" aria-label="الكيمياء">
          <span class="block h-full rounded-full" :style="{ width: `${chemistry.score}%`, background: chemColor(chemistry.score) }" />
        </span>
        <span class="font-numbers text-lg font-bold" :style="{ color: chemColor(chemistry.score) }">{{ chemistry.score }}</span>
      </div>
      <p v-if="chemistry && dirty" class="text-xs text-text-muted">احفظ التشكيلة لتُحسب الكيمياء وروابطها من جديد.</p>

      <div class="flex gap-1 rounded-xl bg-surface-sunk p-1 text-sm" role="group" aria-label="العرض">
        <button v-for="(label, v) in { overall: 'القوة', fitness: 'اللياقة', age: 'السن', value: 'القيمة' }" :key="v" type="button" class="h-10 flex-1 rounded-lg font-bold" :class="view === v ? 'bg-surface-raised text-gold' : 'text-text-soft'" :aria-pressed="view === v" @click="view = v">{{ label }}</button>
      </div>

      <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm" role="status">{{ message }}</p>
      <p v-if="selected" class="text-sm text-gold">اختر المكان الذي ينتقل إليه اللاعب، أو اسحبه.</p>
      <p class="text-xs text-text-muted">اسحب أي لاعب أساسي إلى أي مكان داخل منطقة خطه ليقف فيه، أو على لاعب آخر من نفس الخط ليتبادلا.</p>

      <div ref="pitch" class="relative mx-auto aspect-[68/90] w-full max-w-md select-none overflow-hidden rounded-xxl border-2 border-white/20 bg-[repeating-linear-gradient(0deg,#1f8f4e_0,#1f8f4e_8%,#22994f_8%,#22994f_16%)]">
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
          class="absolute flex w-20 -translate-x-1/2 -translate-y-1/2 touch-none flex-col items-center gap-0.5"
          :style="place(slot)"
          :aria-label="`${slot.role}: ${starters[i] ? players.get(starters[i]!)?.name : 'فارغة'}`"
          @touchmove.prevent
          @pointerdown="down($event, { zone: 'slot', index: i })"
          @click="click({ zone: 'slot', index: i })"
        >
          <template v-if="starters[i] && players.get(starters[i]!)">
            <span
              class="flex size-12 items-center justify-center rounded-full border-[3px] bg-bg font-numbers text-lg font-bold"
              :class="[ring(slot.line), isSelected({ zone: 'slot', index: i }) ? 'ring-4 ring-gold' : '', players.get(starters[i]!)!.available ? '' : 'opacity-60']"
            >{{ shown(players.get(starters[i]!)!) }}</span>
            <span class="max-w-full truncate rounded bg-bg/85 px-1.5 text-xs font-bold" dir="auto">{{ short(players.get(starters[i]!)!.name) }}</span>
            <span class="h-1 w-10 rounded-full bg-bg/60"><span class="block h-full rounded-full" :class="barColor(players.get(starters[i]!)!.fitness)" :style="{ width: `${players.get(starters[i]!)!.fitness}%` }" /></span>
          </template>
          <span v-else class="flex size-12 items-center justify-center rounded-full border-2 border-dashed border-white/70 text-2xl text-white">+</span>
        </button>
      </div>

      <section aria-labelledby="h-bench" class="flex flex-col gap-2">
        <div class="flex items-center justify-between">
          <h2 id="h-bench" class="font-display text-xl font-extrabold">الاحتياط <span class="font-numbers text-base text-text-muted">{{ bench.length }}/7</span></h2>
          <span class="text-sm text-text-muted">اسحب للملعب، أو اضغط لاعباً ثم مكانه</span>
        </div>
        <div class="flex gap-2 overflow-x-auto pb-1">
          <button
            v-for="(id, i) in bench"
            :key="id"
            type="button"
            :data-spot="`bench:${i}`"
            class="flex h-20 w-32 shrink-0 touch-none flex-col justify-between rounded-xl bg-surface p-2 text-start"
            :class="isSelected({ zone: 'bench', index: i }) ? 'ring-2 ring-gold' : ''"
            @touchmove.prevent
          @pointerdown="down($event, { zone: 'bench', index: i })"
            @click="click({ zone: 'bench', index: i })"
          >
            <span class="flex items-center justify-between"><span class="font-numbers text-xl font-bold text-gold">{{ shown(players.get(id)!) }}</span><span class="text-xs text-text-muted">{{ players.get(id)!.position }}</span></span>
            <span class="truncate text-sm font-bold">{{ players.get(id)!.name }}</span>
          </button>
          <button
            v-if="bench.length < 7"
            type="button"
            :data-spot="`bench:${bench.length}`"
            class="flex h-20 w-32 shrink-0 items-center justify-center rounded-xl border-2 border-dashed border-text/20 text-sm text-text-muted"
            @click="click({ zone: 'bench', index: bench.length })"
          >مكان فارغ</button>
        </div>
      </section>

      <section aria-labelledby="h-rest" class="flex flex-col gap-2" data-spot="reserve:-1">
        <h2 id="h-rest" class="font-display text-xl font-extrabold">باقي الفريق</h2>
        <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
          <button
            v-for="(p, i) in reserves"
            :key="p.id"
            type="button"
            :data-spot="`reserve:${i}`"
            class="flex min-h-touch touch-none items-center gap-2 rounded-lg bg-surface p-2 text-start text-sm"
            :class="[isSelected({ zone: 'reserve', index: i }) ? 'ring-2 ring-gold' : '', p.available ? '' : 'opacity-60']"
            @touchmove.prevent
          @pointerdown="down($event, { zone: 'reserve', index: i })"
            @click="click({ zone: 'reserve', index: i })"
            @dblclick="card = p"
          >
            <span class="font-numbers text-lg font-bold text-gold">{{ shown(p) }}</span>
            <span class="min-w-0 flex-1 truncate">{{ p.name }}</span>
            <span class="text-xs text-text-muted">{{ p.position }}</span>
          </button>
        </div>
      </section>

      <section class="flex flex-col gap-2 rounded-xl bg-surface p-4" aria-labelledby="h-takers">
        <h2 id="h-takers" class="font-display text-xl font-extrabold">القائد ومنفذو الكرات الثابتة</h2>
        <p class="text-xs text-text-muted">من الأساسيين المحفوظين. «تلقائي» يختار الأنسب، ولو خرج المنفذ يختار المحرك بديله.</p>
        <label v-for="(label, role) in ROLES" :key="role" class="flex items-center justify-between gap-3">
          <span class="font-bold">{{ label }}</span>
          <select
            class="h-11 min-w-44 rounded-lg border border-text/10 bg-surface-sunk px-3"
            :value="team.takers[role]?.auto ? '' : team.takers[role]?.player_id"
            @change="setTaker(role, ($event.target as HTMLSelectElement).value)"
          >
            <option value="">تلقائي ({{ players.get(team.takers[role]?.player_id ?? 0)?.name ?? '—' }})</option>
            <option v-for="id in team.lineup.starters.filter((x) => x)" :key="id!" :value="id">{{ players.get(id!)?.name }}</option>
          </select>
        </label>
      </section>
    </template>
    <p v-else class="text-text-muted">جارٍ التحميل…</p>

    <div
      v-if="drag?.moved && players.get(drag.id)"
      class="pointer-events-none fixed z-50 flex size-14 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-[3px] border-gold bg-bg font-numbers text-lg font-bold shadow-lg"
      :style="{ left: `${drag.x}px`, top: `${drag.y}px` }"
    >{{ shown(players.get(drag.id)!) }}</div>

    <PlayerCard v-if="card" :player="card" @close="card = null" />

    <div v-if="customOpen" class="fixed inset-0 z-40 flex items-end justify-center bg-black/60 md:items-center" @click.self="customOpen = false">
      <form class="flex w-full max-w-md flex-col gap-3 rounded-t-xxl bg-bg p-4 md:rounded-xxl" role="dialog" aria-modal="true" aria-label="تشكيلة مخصصة" @submit.prevent="saveCustom">
        <h2 class="font-display text-2xl font-extrabold">تشكيلة مخصصة</h2>
        <div class="flex gap-2">
          <input v-model="customName" maxlength="30" class="h-12 flex-1 rounded-lg border border-text/10 bg-surface-sunk px-3" aria-label="الاسم" />
          <select v-model.number="customNumber" class="h-12 w-20 rounded-lg border border-text/10 bg-surface-sunk px-3" aria-label="الرقم">
            <option v-for="n in 3" :key="n" :value="n">{{ n }}</option>
          </select>
        </div>
        <div class="flex gap-2 text-sm">
          <span v-for="(label, l) in { def: 'دفاع', mid: 'وسط', att: 'هجوم' }" :key="l" class="rounded-lg px-2 py-1" :class="within(l) ? 'bg-success/15 text-success' : 'bg-live/15 text-[#FF8A8A]'">
            {{ label }} <span class="font-numbers">{{ customLines[l] }}</span> ({{ LIMITS[l][0] }}–{{ LIMITS[l][1] }})
          </span>
          <span class="ms-auto font-numbers">{{ cells.length }}/10</span>
        </div>
        <div class="grid gap-1 rounded-xl bg-[#1f8f4e] p-2">
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
          <div class="flex h-11 items-center justify-center text-sm font-bold text-white">الحارس</div>
        </div>
        <p v-if="customError" class="text-sm text-[#FF8A8A]" role="alert">{{ customError }}</p>
        <div class="flex gap-2">
          <UiButton type="submit" block>احفظ التشكيلة</UiButton>
          <UiButton variant="quiet" @click="customOpen = false">إلغاء</UiButton>
        </div>
      </form>
    </div>
  </div>
</template>
