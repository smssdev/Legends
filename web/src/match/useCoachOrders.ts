// [Sprint 57 W1] The coach's orders in a match: the quick orders (the server's, config/game.php), the substitutions, the
// tactics as a draft sent as changes only, and the formation. An order waits for its minute (pending), shows as applied
// for a few seconds once that minute has played, and the server's refusals show as they come.
import { computed, reactive, ref, type Ref } from 'vue'
import { api } from '../api/client'
import { uuid } from '../lib/uuid'
import { leagueMatch, sim, type Side, type TeamPlayer, type TeamSnapshot, type Tick, type Tactics } from '../api/sim'

export const TABS = [{ id: 'quick', label: 'سريع' }, { id: 'subs', label: 'تبديل' }, { id: 'tactics', label: 'تكتيك' }, { id: 'shape', label: 'الطريقة' }] as const
export const PLANS = [{ v: 'passing', label: 'تمريرات' }, { v: 'wings', label: 'الأجنحة' }, { v: 'counter', label: 'هجوم مرتد' }, { v: 'long', label: 'كرات طويلة' }, { v: 'shots', label: 'تسديد من بعيد' }]
export const TACKLES = ['قانوني', 'عادي', 'حماس', 'خشونة']
export const SLIDERS = { pressing: 'الضغط على الخصم', style: 'الأسلوب (دفاعي إلى هجومي)', tempo: 'إيقاع اللعب' }
export const LINE_NAMES = { att: 'المهاجمون', mid: 'الوسط', def: 'المدافعون' }
export const POSITIONING = {
  att: [{ v: 'back', label: 'ارتداد' }, { v: 'support', label: 'مساندة الوسط' }, { v: 'only', label: 'هجوم فقط' }],
  mid: [{ v: 'def', label: 'مساندة الدفاع' }, { v: 'stay', label: 'بقاء' }, { v: 'push', label: 'اندفاع' }],
  def: [{ v: 'stay', label: 'بقاء' }, { v: 'fullbacks', label: 'هجوم الظهيرين' }, { v: 'mid', label: 'مساندة الوسط' }],
}
const REFUSED: Record<string, string> = { no_subs_left: 'لا تبديلات متبقية', bad_players: 'اللاعب غير متاح', bad_tactics: 'تكتيك غير صالح', bad_formation: 'طريقة غير صالحة' }

export const formationLabel = (f: string) => (f.startsWith('custom:') ? `خاصة ${f.slice(7)}` : f)

export type OrdersDeps = {
  league: boolean
  id: string
  mine: Ref<Side | null>
  teams: Ref<Record<Side, TeamSnapshot>>
  finished: Ref<boolean>
  error: Ref<string>
}

export function useCoachOrders(d: OrdersDeps) {
  const tab = ref<(typeof TABS)[number]['id']>('quick')
  const initial = ref<Tactics | null>(null)
  // [Sprint 57 B3, W7] The quick orders from the server; null tactics is «عودة للخطة», the coach's own pre-match
  // tactics, which only this screen holds.
  const serverOrders = ref<{ label: string; hint: string; tactics: Partial<Tactics> | null }[]>([])
  const loadQuick = () => api.GET('/data/quick-orders').then((r) => { serverOrders.value = (r.data?.orders ?? []) as typeof serverOrders.value }).catch(() => {})
  const quickOrders = computed<{ label: string; hint: string; tactics: Partial<Tactics> }[]>(() =>
    serverOrders.value.map((o) => ({ label: o.label, hint: o.hint, tactics: o.tactics ?? initial.value ?? {} })))
  const draft = reactive<Tactics>({} as Tactics)
  const draftTrap = computed({ get: () => draft.trap === 1, set: (v) => (draft.trap = v ? 1 : 0) })
  const draftMan = computed({ get: () => draft.marking === 'man', set: (v) => (draft.marking = v ? 'man' : 'zone') })
  const own = () => (d.mine.value ? d.teams.value[d.mine.value] : null)
  const onPitch = computed(() => [...(own()?.players ?? [])].filter((p) => p.on).sort((a, b) => a.fit - b.fit))
  const bench = computed(() => (own()?.players ?? []).filter((p) => !p.on && p.out === '' && p.slot === null))
  const subOut = ref<TeamPlayer | null>(null)
  const pending = ref<{ key: string; label: string; target: number }[]>([])
  const applied = ref<{ key: string; label: string; minute: string }[]>([])
  const rejected = ref<string[]>([])

  async function order(label: string, body: Record<string, unknown>) {
    if (!d.mine.value || d.finished.value) return
    try {
      const r = d.league ? await leagueMatch.order(d.id, body) : await sim.order(d.id, { team: d.mine.value, ...body })
      pending.value.push({ key: uuid(), label, target: r.target_tick })
    } catch (e) {
      d.error.value = (e as Error).message
    }
  }
  const sendTactics = (label: string, tactics: Partial<Tactics>) => order(label, { type: 'tactics', tactics })
  const sendFormation = (f: string) => order(`الطريقة ${formationLabel(f)}`, { type: 'formation', formation: f })
  function sendSub(p: TeamPlayer) {
    const out = subOut.value!
    subOut.value = null
    order(`${p.name} بدلاً من ${out.name}`, { type: 'sub', out: out.id, in: p.id })
  }
  /** The tactics tab: only what changed from the side's tactics now. */
  function applyDraft() {
    const cur = (own()?.tactics ?? {}) as Record<string, unknown>
    const changes = Object.fromEntries(Object.entries(draft).filter(([k, v]) => cur[k] !== v))
    if (Object.keys(changes).length) sendTactics('تعديل التكتيك', changes as Partial<Tactics>)
  }
  /** The side's tactics as the draft (and the plan to come back to), once they are known. */
  function adopt(force = false) {
    const t = own()?.tactics
    if (!t || (!force && draft.plan !== undefined)) return
    Object.assign(draft, t)
    if (force) initial.value = { ...t }
    else initial.value ??= { ...t }
  }
  /** A minute has been told: the orders it applied, and the server's refusals. */
  function settle(t: Tick, minute: string) {
    for (const p of pending.value.filter((o) => t.tick >= o.target)) {
      applied.value.unshift({ key: p.key, label: p.label, minute })
      window.setTimeout(() => (applied.value = applied.value.filter((a) => a.key !== p.key)), 4000)
    }
    pending.value = pending.value.filter((o) => t.tick < o.target)
    rejected.value = (t.rejected ?? []).map((r) => `رُفض الأمر: ${REFUSED[r.reason] ?? r.reason}`)
    adopt()
  }

  // The coach's other live matches (a league and a cup, or two leagues), to switch between them.
  const others = ref<{ id: number; home: string; away: string }[]>([])
  let othersTimer = 0
  async function loadOthers() {
    if (!d.league) return
    othersTimer ||= window.setInterval(loadOthers, 30000)
    try {
      others.value = await leagueMatch.mine()
    } catch {
      /* the switcher is optional */
    }
  }
  const dispose = () => window.clearInterval(othersTimer)

  return { tab, initial, loadQuick, quickOrders, draft, draftTrap, draftMan, onPitch, bench, subOut, pending, applied, rejected, order, sendTactics, sendFormation, sendSub, applyDraft, adopt, settle, others, loadOthers, dispose }
}
export type CoachOrders = ReturnType<typeof useCoachOrders>
