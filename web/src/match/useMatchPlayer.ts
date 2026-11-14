// [Sprint 57 W1] The match on this screen: its state (the score, the minute, the teams, the feed) and how its minutes
// are played. The simulator and a replayed league match are paced here (step by step, at the chosen speed, waiting a
// little for the commentator); a live match's minutes come from useLiveMatch on the server's clock, and both show each
// minute the same way (show, then tell once its scene has played, so a shot's end is never known before the ball gets
// there).
import { computed, ref, shallowRef, type Ref } from 'vue'
import { leagueMatch, sim, type LiveSync, type MatchEvent, type MatchView, type Side, type TeamSnapshot, type Tick } from '../api/sim'
import { line } from './commentary'
import { isKey, type useReplay } from './useReplay'
import type { useMatchAudio } from './useMatchAudio'
import type { CoachOrders } from './useCoachOrders'

/** What MatchFeed exposes to the page. */
export type Pitch = {
  play: (t: Tick, startAt?: number | null) => void
  skip: () => void
  prepare: (t: Tick) => void
  react: (side: Side, emoji: string, text: string, who: string) => void
}

export type PlayerDeps = {
  id: string
  league: boolean
  pitch: Ref<Pitch | undefined>
  audio: ReturnType<typeof useMatchAudio>
  replay: ReturnType<typeof useReplay>
  orders: () => CoachOrders
  speed: number
}

const IMPORTANT = ['goal', 'card', 'penalty', 'period', 'sub']
const LOW_END = (navigator.hardwareConcurrency ?? 8) <= 4

export function useMatchPlayer(d: PlayerDeps) {
  const { sound, voice } = d.audio
  const view = ref<MatchView | null>(null)
  const teams = ref<Record<Side, TeamSnapshot>>({} as Record<Side, TeamSnapshot>)
  const score = ref<Record<Side, number>>({ home: 0, away: 0 })
  const shootout = ref<{ home: number; away: number } | null>(null)
  const minute = ref<[number, number]>([0, 0])
  const last = shallowRef<Tick | null>(null)
  const momentum = ref<number[]>([])
  const feed = ref<{ minute: string; text: string; important: boolean }[]>([])
  const error = ref('')
  const playing = ref(true)
  const speed = ref(d.speed)
  const halftime = ref(false)
  const halftimeLeft = ref(30)
  // [X42] The coach's window (live): play stops after minutes 15, 30, 60 and 75; its countdown shares halftimeLeft.
  const windowOn = ref(false)
  const started = ref(true)
  const finished = ref(false)
  // [X69] A finished league match played again in full, from the server's replay; an older engine's has its recap only.
  const rerun = ref(false)
  const oldEngine = ref(false)
  // [Sprint 43 C6] A replay lasts its round: after the next one starts, the result and the quick recap only.
  const replayExpired = ref(false)
  const intro = ref(true)
  const highlighting = ref(false)
  const skipping = ref(false)
  // [Sprint 26 W6] How each coach feels now: the server's word with each minute shown.
  const moods = ref<Record<Side, string>>({ home: 'idle', away: 'idle' })
  const live = computed(() => view.value?.mode === 'live' && !rerun.value)
  const minuteText = computed(() => (minute.value[1] ? `${minute.value[0]}+${minute.value[1]}'` : `${minute.value[0]}'`))
  /** Set by the live match: the countdowns on the server's clock. */
  const hooks = { clockTick: () => {} }

  const buffer: Tick[] = []
  let rerunTicks: Tick[] = []
  let fetching = false
  let timer = 0
  let htTimer = 0
  let introTimer = 0
  let waited = 0
  let fixedPace = false
  let pendingScore: Record<Side, number> | null = null
  let hlScore: Record<Side, number> | null = null
  let lastGoal: Tick | null = null

  const nameOf = (side: Side, id?: number) => teams.value[side]?.players.find((p) => p.id === id)?.name ?? ''
  const clubName = (side: Side) => view.value?.clubs[side].name ?? ''
  /** The server's commentary line (Sprint 20 B1); the simulator's own table for a minute that has none. */
  const say = (e: MatchEvent) => e.text ?? line(e, nameOf, clubName)
  const momentMs = (t?: Tick | null) => (t?.moment?.ms ?? view.value?.timing.tick_ms ?? 3000) / speed.value

  async function fetchNext(count = 1) {
    if (fetching || finished.value || rerun.value) return
    fetching = true
    try {
      buffer.push(...(await sim.ticks(d.id, count)).ticks)
    } catch (e) {
      error.value = (e as Error).message
    } finally {
      fetching = false
    }
  }

  function schedule(ms: number) {
    clearTimeout(timer)
    timer = window.setTimeout(step, ms)
  }

  async function step() {
    if (!playing.value || halftime.value || finished.value) return
    // Let the commentator finish his sentence (a little); at the broadcast's fixed pace he never holds the clock [X35].
    const talk = fixedPace ? 0 : voice.remainingMs()
    if (talk > 250 && waited < 2500) {
      waited += Math.min(talk, 500)
      return schedule(Math.min(talk, 500))
    }
    waited = 0
    if (!buffer.length) {
      await fetchNext()
      if (!buffer.length) return schedule(500)
    }
    const t = buffer.shift()!
    fixedPace = !!t.moment && t.moment.ms <= 3400 && t.moment.kind !== 'shootout'
    show(t)
    // [Sprint 42 I1] The next minute's scene drawn ahead, while this one plays.
    if (buffer[0]) d.pitch.value?.prepare(buffer[0])
    if (!t.finished && buffer.length === 0) fetchNext()
    if (!halftime.value && !finished.value) schedule(momentMs(t))
  }

  let pendingReveal: (() => void) | null = null
  let shownAt = 0
  function reveal() {
    const r = pendingReveal
    pendingReveal = null
    r?.()
  }

  /** startAt (live): when the minute starts, on performance.now(), so the scene plays in step with the other screen. */
  function show(t: Tick, animate = true, startAt?: number) {
    reveal()
    intro.value = false
    last.value = t
    minute.value = t.minute
    if (t.moods) moods.value = t.moods
    if (pendingScore) score.value = pendingScore
    pendingScore = null
    // The score changes when the ball crosses the line in the shot, not at the start of the minute.
    const goal = t.events.some((e) => e.type === 'goal')
    if (animate && goal) pendingScore = t.score
    else score.value = t.score
    // Live: the next minute has started, so the half-time break is over.
    if (live.value && halftime.value) {
      halftime.value = false
      clearInterval(htTimer)
    }
    windowOn.value = false
    if (isKey(t)) d.replay.keyTicks.push(t)
    // Live: the goal again in a small frame while the next minute plays (not on a slow phone), not after a goal whose
    // long minute already played its replay [X41].
    if (
      live.value &&
      animate &&
      lastGoal &&
      (lastGoal.moment?.ms ?? 0) < 15000 &&
      !t.events.some((e) => e.type === 'period') &&
      !LOW_END &&
      !d.replay.replayMissed.value
    )
      d.replay.replayTick.value = lastGoal
    lastGoal = live.value && t.events.some((e) => e.type === 'goal' && (e.kind ?? 'open') === 'open') ? t : null
    sound.danger(t.danger)
    // The stands sing: after a goal, and now and then in a quiet spell [Sprint 35].
    if (animate && goal) sound.chant(6)
    else if (animate && t.moment?.kind === 'quiet' && t.minute?.[0] % 13 === 7) sound.chant()
    pendingReveal = () => tell(t, animate)
    // [X93] A minute that started before it was shown (back on the page) counts from its real start.
    shownAt = startAt ?? performance.now()
    if (animate) d.pitch.value?.play(t, startAt)
    else reveal()
  }

  /** What a minute leaves once its scene has played: the feed, the momentum, the break, the orders applied. */
  function tell(t: Tick, animate: boolean) {
    if (t.teams) teams.value = t.teams
    momentum.value = [...momentum.value, t.danger]
    const left = () => (t.events.some((g) => g.type === 'goal') ? momentMs(t) - (performance.now() - shownAt) - 200 : 0)
    for (const e of t.events) {
      const text = say(e)
      if (text) feed.value.unshift({ minute: minuteText.value, text, important: IMPORTANT.includes(e.type) })
      if (e.type === 'period') {
        sound.whistle(e.name === 'fulltime' ? 3 : 2)
        // [X41] A goal in the half's last minute has its replay first: the break waits for the minute to end.
        if (e.name === 'halftime' && animate) {
          const l = left()
          if (l > 0) window.setTimeout(startHalftime, l)
          else startHalftime()
        }
      } else if (e.type === 'shootout') {
        shootout.value = e.score
      }
    }
    // [X42] The coach's window opens when the minute's scene has played (its goal's replay too).
    if (live.value && t.window && animate) {
      const open = () => {
        if (last.value === t) {
          windowOn.value = true
          hooks.clockTick()
        }
      }
      const l = left()
      if (l > 0) window.setTimeout(open, l)
      else open()
    }
    d.orders().settle(t, minuteText.value)
    if (t.finished) {
      if (animate) window.setTimeout(() => (finished.value = true), 1600)
      else finished.value = true
    }
  }

  function startHalftime() {
    halftime.value = true
    // Live: the clock ticker counts down to the second half from the server's time.
    if (live.value) return hooks.clockTick()
    halftimeLeft.value = Math.round((view.value!.timing.halftime_seconds || 30) / speed.value)
    clearInterval(htTimer)
    htTimer = window.setInterval(() => {
      halftimeLeft.value--
      if (halftimeLeft.value <= 0) endHalftime()
    }, 1000)
  }

  function endHalftime() {
    clearInterval(htTimer)
    halftime.value = false
    schedule(200)
  }

  function togglePlay() {
    playing.value = !playing.value
    if (playing.value) schedule(100)
    else clearTimeout(timer)
  }

  async function skip() {
    skipping.value = true
    clearTimeout(timer)
    halftime.value = false
    clearInterval(htTimer)
    if (rerun.value) {
      while (buffer.length) show(buffer.shift()!, false)
      skipping.value = false
      return
    }
    try {
      while (!finished.value) {
        const res = await sim.ticks(d.id, 200)
        buffer.push(...res.ticks)
        while (buffer.length) show(buffer.shift()!, false)
        if (!res.ticks.length) break
      }
    } catch (e) {
      error.value = (e as Error).message
    } finally {
      skipping.value = false
    }
  }

  function skipMoment() {
    d.pitch.value?.skip()
    reveal()
    voice.stop()
    if (!live.value) {
      clearTimeout(timer)
      schedule(120)
    }
  }

  function startRerun() {
    clearTimeout(timer)
    buffer.length = 0
    buffer.push(...rerunTicks)
    d.replay.keyTicks.length = 0
    feed.value = []
    momentum.value = []
    score.value = { home: 0, away: 0 }
    shootout.value = null
    minute.value = [0, 0]
    teams.value = view.value!.teams
    finished.value = false
    halftime.value = false
    playing.value = true
  }
  function watchAgain() {
    startRerun()
    intro.value = false
    schedule(300)
  }

  /** The studio opens the match; the first minute starts when it closes (the tap also turns the sound on). */
  function endIntro() {
    if (!d.audio.soundOn.value) d.audio.toggleSound()
    if (!intro.value || live.value) return
    intro.value = false
    clearTimeout(introTimer)
    schedule(300)
  }

  /** After the final whistle: the goals and the big moments again, scene by scene. */
  async function highlights() {
    highlighting.value = true
    const finalScore = { ...score.value }
    for (const t of d.replay.keyTicks) {
      if (!highlighting.value) break
      minute.value = t.minute
      hlScore = t.score
      d.pitch.value?.play(t)
      await new Promise((r) => window.setTimeout(r, momentMs(t) + 400))
    }
    d.pitch.value?.skip()
    score.value = finalScore
    highlighting.value = false
  }

  /** The scene's cues: the result revealed, the ball in the net. */
  function onCue(name: string) {
    if (name === 'reveal') return reveal()
    if (name !== 'goal') return
    if (highlighting.value && hlScore) score.value = hlScore
    else if (pendingScore) {
      score.value = pendingScore
      pendingScore = null
    }
  }

  /**
   * After the view has loaded (not live): a finished league match opens at its end with its replay ready ([X93]: the
   * score, the stats, the timeline; «شاهدها من جديد» and the highlights play it on demand), else the simulator starts.
   */
  async function begin(): Promise<void> {
    const v = view.value!
    if (d.league && finished.value) {
      const r = await leagueMatch.replay(d.id)
      if (r.replayable && r.ticks?.length) {
        rerun.value = true
        rerunTicks = r.ticks
        startRerun()
        intro.value = false
        while (buffer.length) show(buffer.shift()!, false)
        return
      }
      oldEngine.value = true
      replayExpired.value = !!r.expired
    }
    if (live.value) return
    await fetchNext()
    if (!rerun.value && (v.tick > 0 || finished.value)) {
      intro.value = false
      schedule(300)
    } else introTimer = window.setTimeout(endIntro, 11000)
  }

  /** A live break's details from the poll (half-time ended by the next minute is show's). */
  const pause = ref<LiveSync['pause']>(null)

  function dispose() {
    clearTimeout(timer)
    clearInterval(htTimer)
    clearTimeout(introTimer)
    highlighting.value = false
  }

  return {
    view,
    teams,
    score,
    shootout,
    minute,
    last,
    momentum,
    feed,
    error,
    playing,
    speed,
    halftime,
    halftimeLeft,
    windowOn,
    started,
    finished,
    rerun,
    oldEngine,
    replayExpired,
    intro,
    highlighting,
    skipping,
    moods,
    live,
    minuteText,
    pause,
    hooks,
    say,
    clubName,
    show,
    reveal,
    togglePlay,
    skip,
    skipMoment,
    endHalftime,
    watchAgain,
    endIntro,
    highlights,
    onCue,
    begin,
    dispose,
  }
}
export type MatchPlayer = ReturnType<typeof useMatchPlayer>
