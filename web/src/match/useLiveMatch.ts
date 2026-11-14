// [Sprint 57 W1] A live match (two coaches, or a league's members watching): the server keeps the clock and makes each
// minute a moment before it starts, with its start time (tick.at). This screen knows the server's time (useMatchClock)
// and plays every minute at that instant, so every screen shows the same scene together. The minutes come pushed on
// the league's channel [Sprint 53] or from the poll; back after a gap, the screen jumps to now with what it missed.
import { computed, ref, watch } from 'vue'
import { leagueMatch, seats, sim, type LiveSummary, type LiveSync, type Reading, type Side, type Tick } from '../api/sim'
import { useLiveSync } from './useLiveSync'
import type { useMatchClock } from './useMatchClock'
import type { MatchPlayer, Pitch } from './useMatchPlayer'
import type { MatchSocial } from './useMatchSocial'
import type { CoachOrders } from './useCoachOrders'
import type { useReplay } from './useReplay'

/** On the channel the poll only checks now and then. */
const PUSHED_POLL_MS = 12_000

export type LiveDeps = {
  id: string
  league: boolean
  player: MatchPlayer
  pitch: { value: Pitch | undefined }
  clock: ReturnType<typeof useMatchClock>
  social: () => MatchSocial
  orders: () => CoachOrders
  replay: ReturnType<typeof useReplay>
  mine: { value: Side | null }
  /** The screen kept on (the wake lock), and let go. */
  awake: { keep: () => void }
  /** Away from the page without the sound: the commentator stops. */
  hush: () => void
}

export function useLiveMatch(d: LiveDeps) {
  const P = d.player
  const source = d.league ? leagueMatch : sim
  const starting = ref(false)
  const countdown = ref(0)
  const copied = ref(false)
  const offline = ref(false)
  // [E8.5] What a gap missed, shown for a few seconds after the jump to now.
  const caught = ref<LiveSummary | null>(null)
  // The assistant's notes to this coach (league), newest first.
  const readings = ref<Reading[]>([])
  const readyBusy = ref(false)
  const friendSeat = seats.get(`${d.id}.friend`)
  const friendLink = computed(() => (friendSeat ? `${location.origin}/sim/${d.id}?seat=${friendSeat}` : ''))
  let seen = 0
  let pollTimer = 0
  let caughtTimer = 0
  let kickoffAt = 0
  let resumeAt = 0
  let breakAhead = false
  // The minutes waiting for their start: timer id → the minute and its start on performance.now().
  const playTimers = new Map<number, { t: Tick; startAt: number }>()
  const serverNow = d.clock.serverNow
  const missed = (t: Parameters<typeof d.replay.missedGoal>[0]) => d.replay.missedGoal(t, P.score.value)

  // [UP17] «أنا مستعد» and the emergency substitution (league, live).
  const iAmReady = computed(() => !!d.mine.value && !!P.pause.value?.ready.includes(d.mine.value))
  const injuredId = computed(() =>
    d.mine.value && P.pause.value && !P.pause.value.window ? (P.pause.value.injured[d.mine.value] ?? null) : null,
  )
  const injuredName = computed(() => P.teams.value[d.mine.value as Side]?.players.find((p) => p.id === injuredId.value)?.name ?? '')
  const benchForInjury = computed(() =>
    (P.teams.value[d.mine.value as Side]?.players ?? []).filter((p) => !p.on && p.out === '' && p.slot === null),
  )

  /** Countdown to the kick-off and to the second half (or the window's end), on the shared clock. */
  function clockTick() {
    const now = serverNow()
    countdown.value = kickoffAt > now ? Math.ceil((kickoffAt - now) / 1000) : 0
    if (P.halftime.value || P.windowOn.value || injuredId.value) P.halftimeLeft.value = Math.max(0, Math.ceil((resumeAt - now) / 1000))
  }
  P.hooks.clockTick = clockTick

  async function sayReady() {
    readyBusy.value = true
    try {
      const r = await leagueMatch.ready(d.id)
      if (P.pause.value) P.pause.value = { ...P.pause.value, ready: r.ready as Side[], until: r.resume_at }
      resumeAt = r.resume_at
      clockTick()
    } catch (e) {
      P.error.value = (e as Error).message
    } finally {
      readyBusy.value = false
    }
  }
  async function emergencySub(inId: number) {
    if (injuredId.value) await d.orders().order('تبديل طارئ', { type: 'sub', out: injuredId.value, in: inId })
  }

  async function share() {
    try {
      if (navigator.share) await navigator.share({ title: 'Legends', text: 'أدر فريقك في مباراتنا', url: friendLink.value })
      else await navigator.clipboard.writeText(friendLink.value)
      copied.value = true
      window.setTimeout(() => (copied.value = false), 2000)
    } catch {
      /* the user closed the share sheet */
    }
  }

  async function startLive() {
    starting.value = true
    try {
      const sent = Date.now()
      const r = await sim.start(d.id)
      d.clock.sample(sent, r.server_now)
      handleSync(r)
    } catch (e) {
      P.error.value = (e as Error).message
    } finally {
      starting.value = false
    }
  }

  /** A break under way or the kick-off still to come: the poll keeps its quick pace. */
  const quickPoll = () => !P.started.value || P.halftime.value || P.windowOn.value || !!P.pause.value

  async function poll() {
    clearTimeout(pollTimer)
    if (P.finished.value) return
    let wait = 1000
    try {
      const sent = Date.now()
      const r = await source.live(d.id, seen)
      d.clock.sample(sent, r.server_now)
      offline.value = false
      wait = handleSync(r)
      // [Sprint 53] On the channel the minutes come by themselves: the poll only checks now and then.
      if (d.league && sync.connected.value) wait = Math.max(wait, quickPoll() ? (P.started.value ? 2000 : wait) : PUSHED_POLL_MS)
    } catch (e) {
      // A lost connection: keep asking. The server keeps every minute, so coming back loses nothing (Sprint 20 W2).
      if (navigator.onLine === false || e instanceof TypeError) {
        offline.value = true
        wait = 2000
      } else P.error.value = (e as Error).message
    }
    if (!P.finished.value) pollTimer = window.setTimeout(poll, wait)
  }

  /** Back on the page (a locked phone, another tab): catch up at once. */
  function onVisible() {
    if (!P.live.value || P.finished.value) return
    if (document.visibilityState !== 'visible') {
      // Away with the sound on, the broadcast plays on like a TV left running [X41]; without it the commentator stops.
      d.hush()
      return
    }
    catchUp()
    d.awake.keep()
    poll()
  }

  /**
   * Back from a locked screen (Sprint 21 W1): the minutes whose time came while away are told at once, without their
   * scenes, and only the one playing now animates, on the server's clock; the later ones keep their timers.
   */
  function catchUp() {
    const now = performance.now()
    const late = [...playTimers.entries()].filter(([, p]) => p.startAt <= now).sort((a, b) => a[1].t.tick - b[1].t.tick)
    late.forEach(([id, { t, startAt }], i) => {
      clearTimeout(id)
      playTimers.delete(id)
      if (i < late.length - 1) {
        P.show(t, false)
        missed(t)
      } else P.show(t, true, startAt)
    })
  }

  /** Schedules the new minutes on the shared clock and returns how long to wait before asking again. */
  function handleSync(r: LiveSync): number {
    P.started.value = r.started
    P.error.value = ''
    // [UP17] The break: both coaches ready ends it early (its end moves), and an injured player of mine waits.
    P.pause.value = r.pause ?? null
    if (r.pause) resumeAt = r.pause.until
    // Back after a gap: one path for a hidden tab, a lost connection and joining late [E8.5].
    if (r.gap && r.summary && r.summary.minutes > 0 && r.summary.to_tick > seen) {
      caught.value = r.summary
      clearTimeout(caughtTimer)
      caughtTimer = window.setTimeout(() => (caught.value = null), 8000)
    }
    for (const m of r.missed ?? []) {
      if (m.tick <= seen) continue
      seen = m.tick
      missed(m as Parameters<typeof missed>[0])
      for (const e of m.events) {
        const text = P.say(e)
        if (text)
          P.feed.value.unshift({ minute: `${m.minute}'`, text, important: ['goal', 'card', 'penalty', 'period', 'sub'].includes(e.type) })
        if (e.type === 'shootout') P.shootout.value = e.score
      }
    }
    for (const x of r.readings ?? []) if (!readings.value.some((y) => y.id === x.id)) readings.value.unshift(x)
    const fresh = takeTicks(r.ticks, r.next_at)
    if (r.tick === 0 && !fresh.length && seen === 0) kickoffAt = r.next_at ?? 0
    for (const x of r.reactions ?? []) d.social().receive(x)
    for (const c of r.chat ?? []) d.social().hear(c)
    const left = r.next_at === null ? 1500 : r.next_at - r.server_now - 1100
    // [E8.7] A server under load asks for fewer polls.
    return Math.max(r.poll_ms ?? 0, Math.min(1000, Math.max(250, left)))
  }

  /** The new minutes, from the poll or the channel: each plays when its time comes, one already over is told at once. */
  function takeTicks(ticks: Tick[], nextAt: number | null): Tick[] {
    const fresh = ticks.filter((t) => t.tick > seen)
    fresh.forEach((t, i) => {
      seen = t.tick
      // The second half starts with the first minute after the break.
      if (breakAhead) {
        resumeAt = t.at ?? resumeAt
        breakAhead = false
      }
      if (t.window || t.events.some((e) => e.type === 'period' && e.name === 'halftime')) breakAhead = true
      const delay = (t.at ?? serverNow()) - serverNow()
      const next = fresh[i + 1]
      // Already over (a locked screen, a slow phone): its result at once, no scene. Only the minute playing now animates.
      if (next?.at !== undefined && next.at <= serverNow()) {
        P.show(t, false)
        return missed(t)
      }
      const startAt = performance.now() + delay
      if (delay <= 0) return P.show(t, true, startAt)
      // [Sprint 42 I1] A live minute arrives before it plays: its scene is drawn ahead in the meantime.
      d.pitch.value?.prepare(t)
      const id = window.setTimeout(() => {
        playTimers.delete(id)
        P.show(t, true, startAt)
      }, delay)
      playTimers.set(id, { t, startAt })
    })
    if (fresh.length && fresh[0].tick === 1) kickoffAt = fresh[0].at ?? 0
    if (breakAhead && nextAt) resumeAt = nextAt
    return fresh
  }

  // [Sprint 53] A live league match on its channel: the minutes, the chat and the reactions pushed.
  const channelMatch = computed(() => (d.league && P.live.value && !P.finished.value ? Number(d.id) : null))
  const sync = useLiveSync(channelMatch, {
    minute(e) {
      if (P.finished.value || P.rerun.value) return
      const t = e.live
      if (t.tick <= seen) return
      // A minute missing in between (a dropped message): the poll brings everything from `seen`.
      if (t.tick > seen + 1) return void poll()
      // The channel carries no tactics: my own stay as the last poll gave them.
      const mine = d.mine.value
      const own = mine ? P.teams.value[mine]?.tactics : null
      if (mine && own && t.teams?.[mine]) t.teams[mine] = { ...t.teams[mine], tactics: own }
      P.started.value = true
      takeTicks([t], e.next_at)
      // A break opens or the match ends: its details (who is ready, an injury) from the poll.
      if (t.finished || t.window || t.events.some((x) => x.type === 'period' && x.name === 'halftime')) poll()
    },
    chat: (c) => d.social().hear(c),
    reaction: (x) => d.social().receive(x),
    rejoined: () => {
      if (P.live.value && !P.finished.value) poll()
    },
  })
  // [Sprint 53 W1] The channel lost: back to the poll's own pace at once.
  watch(
    () => sync.connected.value,
    (on) => {
      if (!on && P.live.value && !P.finished.value) poll()
    },
  )

  /** The live match from its first minute ([X93]: back on the page, the screen comes back where the match is). */
  function begin() {
    const v = P.view.value!
    P.intro.value = !v.started || v.tick === 0
    P.started.value = v.started
    seen = 0
    d.clock.start(clockTick)
    d.awake.keep()
    return poll()
  }

  function dispose() {
    clearTimeout(caughtTimer)
    clearTimeout(pollTimer)
    d.clock.stop()
    playTimers.forEach((_, id) => clearTimeout(id))
  }

  return {
    sync,
    starting,
    countdown,
    copied,
    offline,
    caught,
    readings,
    readyBusy,
    friendLink,
    iAmReady,
    injuredId,
    injuredName,
    benchForInjury,
    sayReady,
    emergencySub,
    share,
    startLive,
    onVisible,
    begin,
    dispose,
  }
}
export type LiveMatch = ReturnType<typeof useLiveMatch>
