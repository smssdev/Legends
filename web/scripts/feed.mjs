// [Sprint 37 R2] Checks the cartoon feed's pure part before every build: the director's cutaways (director.ts) by tier
// and by the time left. The live pitch's moves (actions.ts) went with the live pitch [Sprint 42 G1].
import { director } from '../src/match/feed/director.ts'

const bad = []
const check = (ok, what) => {
  if (!ok) bad.push(what)
}

// ---- the director
const tick = { tick: 12, moods: { home: 'joy', away: 'sad' } }
const goal = { scene: 'goal', goal: true, side: 'home', data: {} }
const names = (cuts) => cuts.map((c) => c.name).join(',')
check(director(goal, tick, 30, 6, { tier: 'low' }).length === 0, 'low tier: no cutaways')
check(names(director(goal, tick, 30, 6, { tier: 'mid' })) === 'crowd', 'mid tier: one cutaway, the crowd first')
check(names(director(goal, tick, 30, 6, { tier: 'high' })) === 'crowd,coachReact,coachReact', 'high tier: crowd then both coaches')
{
  const [, mine, theirs] = director(goal, tick, 30, 6, { tier: 'high', looks: { home: 'C3' } })
  check(
    mine.data.side === 'home' && mine.data.look === 'C3' && mine.data.mood === 'joy',
    "the scorers' coach in his look and the server's mood",
  )
  check(theirs.data.side === 'away' && theirs.data.look === 'C2' && theirs.data.mood === 'sad', "the other coach in the server's mood")
  const calm = director(goal, { tick: 12, moods: { home: 'idle' } }, 30, 6, { tier: 'high' })
  check(calm[1].data.mood === 'joy' && calm[2].data.mood === 'angry', 'no expressive mood from the server: joy and anger')
}
// Only what fits: the scene, then each cutaway, keeping 4.5 s for a goal's replay.
check(director(goal, tick, 6 + 2.6 + 4.5, 6, { tier: 'high' }).length === 1, 'a short minute keeps only what fits')
check(director(goal, tick, 6 + 2.3 + 4.5, 6, { tier: 'high' }).length === 0, 'no room: no cutaway')
check(
  names(director({ scene: 'card', side: 'away', data: { type: 'red' } }, tick, 30, 4.4, { tier: 'high' })) === 'brawl,coachReact',
  'a red card: the brawl, then the coach',
)
check(
  director({ scene: 'card', side: 'away', data: { type: 'yellow' } }, tick, 30, 4.4, { tier: 'mid' }).length === 0,
  'a yellow card on mid: no cutaway',
)
// [Sprint 42] A red card told as a fight or a spit already has its tempers: no brawl cutaway after it, only the coach.
for (const drama of ['brawl', 'spit'])
  check(
    names(director({ scene: 'card', side: 'away', data: { type: 'red', drama } }, tick, 30, 6.6, { tier: 'high' })) === 'coachReact',
    `a red card told as ${drama}: the coach only`,
  )
check(
  names(director({ scene: 'card', side: 'away', data: { type: 'red', drama: 'tackle' } }, tick, 30, 6.6, { tier: 'high' })) ===
    'brawl,coachReact',
  'a red card after a plain tackle: the brawl, then the coach',
)
// [Sprint 42 F6] A big chance blasted over the bar: the coach's meltdown; a miss wide: his worry, as before.
check(
  names(director({ scene: 'miss', side: 'home', data: { how: 'over' } }, tick, 30, 5, { tier: 'mid' })) === 'meltdown',
  'a chance over the bar: the meltdown',
)
check(
  names(director({ scene: 'miss', side: 'home', data: { how: 'wide' } }, tick, 30, 5, { tier: 'mid' })) === 'coachReact',
  'a chance wide: the worried coach',
)
check(
  names(director({ scene: 'whistle', side: 'home', data: { name: 'halftime' } }, tick, 30, 3.6, { tier: 'high' })) === 'tunnel',
  'half time: the tunnel',
)
check(
  names(director({ scene: 'whistle', side: 'home', data: { name: 'fulltime' } }, tick, 30, 3.6, { tier: 'high' })) ===
    'handshake,coachReact,coachReact',
  'full time: the handshake, then the coaches',
)
check(
  names(director({ scene: 'var', side: 'home', data: {} }, tick, 30, 8.2, { tier: 'high' })) === 'coachReact,coachReact',
  'VAR: both coaches',
)
check(director({ scene: null, data: {} }, tick, 30, 0, { tier: 'high' }).length === 0, 'no scene: no cutaway')
{
  const a = director(goal, tick, 30, 6, { tier: 'high', seed: 9 }),
    b = director(goal, tick, 30, 6, { tier: 'high', seed: 9 })
  check(JSON.stringify(a) === JSON.stringify(b), 'the same seed gives the same cutaways on every screen')
}

if (bad.length) {
  console.error('the director (director.ts) changed\n' + bad.join('\n'))
  process.exit(1)
}
console.log('feed: director OK')
