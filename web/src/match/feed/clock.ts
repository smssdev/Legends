// [Sprint 57 W3] The broadcast clock through one minute (pure; MatchFeed writes it): minutes and seconds as on TV
// [X35]; with a scene, it runs to the moment's second in the first 0.4 s, stands still through the scene and its
// cutaways [Sprint 42 E1], then runs on. The half and how far the match has gone [Sprint 42 G1].

/** The minute's scene timing: its length, the scene's and the cutaways' (seconds); none for a quiet minute. */
export type Timing = { total: number; sceneT: number; cutT: number; scene: boolean } | null

export type ClockAt = { text: string; frozen: boolean; half: 'first' | 'second' | 'extra' | 'shootout'; progress: number }

/** The clock at u (0..1 of the minute). tick: the minute ([minute, added]) and its number (the moment's second). */
export function clockAt(minute: [number, number], tickNo: number, u: number, p: Timing): ClockAt {
  const base = minute[0] - 1 + (minute[1] || 0)
  let sec = Math.min(59, Math.floor(u * 60))
  const hold = p?.scene && p.total ? Math.min(0.95, (p.sceneT + p.cutT) / p.total) : 0
  const frozen = !!p && hold > 0 && u < hold && u * p.total >= 0.4
  if (p && hold > 0) {
    const at = 12 + ((tickNo || 1) * 37) % 40, run = Math.min(hold, 0.4 / p.total)
    sec = Math.min(59, Math.floor(u < run ? (at * u) / run : u < hold ? at : at + ((59 - at) * (u - hold)) / (1 - hold)))
  }
  const mm = minute[0] + (minute[1] || 0)
  const half = minute[0] > 120 ? 'shootout' : minute[0] > 90 ? 'extra' : minute[0] > 45 ? 'second' : 'first'
  const progress = Math.min(1, Math.round(((mm - 1 + u) / 90) * 200) / 200)
  return { text: `${String(base).padStart(2, '0')}:${String(sec).padStart(2, '0')}`, frozen, half, progress }
}
