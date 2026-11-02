// [Sprint 37 R2] Checks the live pitch's pure parts (src/match/feed/director.ts and actions.ts) before every build:
// the director's cutaways by tier and by the time left, and the players' moves from the Keyframes and events.
import { director } from '../src/match/feed/director.ts'
import { pitchActions } from '../src/match/feed/actions.ts'

const bad = []
const check = (ok, what) => { if (!ok) bad.push(what) }

// ---- the director
const tick = { tick: 12, moods: { home: 'joy', away: 'sad' } }
const goal = { scene: 'goal', goal: true, side: 'home', data: {} }
const names = (cuts) => cuts.map((c) => c.name).join(',')
check(director(goal, tick, 30, 6, { tier: 'low' }).length === 0, 'low tier: no cutaways')
check(names(director(goal, tick, 30, 6, { tier: 'mid' })) === 'crowd', 'mid tier: one cutaway, the crowd first')
check(names(director(goal, tick, 30, 6, { tier: 'high' })) === 'crowd,coachReact,coachReact', 'high tier: crowd then both coaches')
{
  const [, mine, theirs] = director(goal, tick, 30, 6, { tier: 'high', looks: { home: 'C3' } })
  check(mine.data.side === 'home' && mine.data.look === 'C3' && mine.data.mood === 'joy', 'the scorers\' coach in his look and the server\'s mood')
  check(theirs.data.side === 'away' && theirs.data.look === 'C2' && theirs.data.mood === 'sad', 'the other coach in the server\'s mood')
  const calm = director(goal, { tick: 12, moods: { home: 'idle' } }, 30, 6, { tier: 'high' })
  check(calm[1].data.mood === 'joy' && calm[2].data.mood === 'angry', 'no expressive mood from the server: joy and anger')
}
// Only what fits: the scene, then each cutaway, keeping 4.5 s for a goal's replay.
check(director(goal, tick, 6 + 2.6 + 4.5, 6, { tier: 'high' }).length === 1, 'a short minute keeps only what fits')
check(director(goal, tick, 6 + 2.3 + 4.5, 6, { tier: 'high' }).length === 0, 'no room: no cutaway')
check(names(director({ scene: 'card', side: 'away', data: { type: 'red' } }, tick, 30, 4.4, { tier: 'high' })) === 'brawl,coachReact', 'a red card: the brawl, then the coach')
check(director({ scene: 'card', side: 'away', data: { type: 'yellow' } }, tick, 30, 4.4, { tier: 'mid' }).length === 0, 'a yellow card on mid: no cutaway')
check(names(director({ scene: 'whistle', side: 'home', data: { name: 'halftime' } }, tick, 30, 3.6, { tier: 'high' })) === 'tunnel', 'half time: the tunnel')
check(names(director({ scene: 'whistle', side: 'home', data: { name: 'fulltime' } }, tick, 30, 3.6, { tier: 'high' })) === 'handshake,coachReact,coachReact', 'full time: the handshake, then the coaches')
check(names(director({ scene: 'var', side: 'home', data: {} }, tick, 30, 8.2, { tier: 'high' })) === 'coachReact,coachReact', 'VAR: both coaches')
check(director({ scene: null, data: {} }, tick, 30, 0, { tier: 'high' }).length === 0, 'no scene: no cutaway')
{
  const a = director(goal, tick, 30, 6, { tier: 'high', seed: 9 }), b = director(goal, tick, 30, 6, { tier: 'high', seed: 9 })
  check(JSON.stringify(a) === JSON.stringify(b), 'the same seed gives the same cutaways on every screen')
}

// ---- the actions
const side = { 1: 'home', 2: 'home', 3: 'away', 9: 'away', 10: 'home' }
const ctx = { gks: new Set(['9', '10']), sideOf: (id) => side[id] }
const P = (o) => ({ 1: [500, 340], 2: [600, 300], 3: [700, 360], 9: [1040, 340], 10: [10, 340], ...o })
check(pitchActions({ tick: 1, events: [] }, [{ b: [1, 1, 0], p: P(), h: 1 }], 0.5, ctx).holder === 1, 'one Keyframe: who holds the ball')
{
  // A pass from 1 to 2: 1 kicks as it leaves him, and its sound is told once.
  const f = [{ b: [500, 340, 0], p: P(), h: 1 }, { b: [600, 300, 0], p: P(), h: 2 }]
  const a = pitchActions({ tick: 1, events: [] }, f, 0.1, ctx)
  check(a.by[1]?.kind === 'kick' && a.holder === 1, 'the passer kicks')
  check(a.sounds.some(([, n]) => n === 'touch'), 'the touch sound')
  check(pitchActions({ tick: 1, events: [] }, f, 0.9, ctx).holder === 2, 'the receiver holds it at the end')
  const line = [{ b: [500, 10, 0], p: P(), h: 1 }, { b: [600, 300, 0], p: P(), h: 2 }]
  check(pitchActions({ tick: 1, events: [] }, line, 0.1, ctx).by[1]?.kind === 'throwin', 'from the touchline: a throw-in')
}
{
  // A shot at the far goal: the keeper there dives towards the ball.
  const f = [{ b: [900, 340, 0], p: P(), h: 1 }, { b: [1040, 300, 0], p: P(), h: null }]
  const a = pitchActions({ tick: 1, events: [{ type: 'attack', result: 'saved', team: 'home' }] }, f, 0.7, ctx)
  check(a.by[9]?.kind === 'dive' && a.by[9].dir === -1, 'the keeper dives the ball\'s way')
}
{
  // A goal: once the ball is in, the scorers celebrate and the others hang their heads (keepers apart).
  const f = [{ b: [900, 340, 0], p: P(), h: 1 }, { b: [1050, 340, 0], p: P(), h: null }]
  const a = pitchActions({ tick: 1, events: [{ type: 'attack', result: 'goal' }, { type: 'goal', team: 'home' }] }, f, 1, ctx)
  check(a.by[2]?.kind === 'party' && a.by[3]?.kind === 'down' && a.by[9]?.kind !== 'party' && a.by[9]?.kind !== 'down', 'the goal: party and heads down')
  check(a.sounds.some(([, n]) => n === 'net'), 'the net sound')
}
{
  // A foul with a red card: the victim goes down, the referee holds up red.
  const f = [{ b: [500, 340, 0], p: P(), h: 3 }, { b: [520, 340, 0], p: P(), h: 1 }, { b: [540, 340, 0], p: P(), h: 1 }]
  const ev = [{ type: 'foul', player: 3, victim: 1 }, { type: 'card', player: 3, color: 'red' }]
  const a = pitchActions({ tick: 1, events: ev }, f, 0.75, ctx)
  check(a.by[1]?.kind === 'fallen' && a.call?.at === 1 && a.call.card === '#D3122F', 'the foul: the victim down, the red card held up')
  check(a.sounds.some(([, n]) => n === 'whistle'), 'the whistle')
  check(pitchActions({ tick: 1, events: ev }, f, 0.2, ctx).call === null, 'no call before the foul')
}
{
  // The same instant gives the same moves (every screen shows the same).
  const f = [{ b: [500, 340, 0], p: P(), h: 1 }, { b: [520, 340, 0], p: P(), h: 3 }]
  const a = pitchActions({ tick: 3, events: [] }, f, 0.8, ctx), b = pitchActions({ tick: 3, events: [] }, f, 0.8, ctx)
  check(JSON.stringify(a) === JSON.stringify(b), 'deterministic')
}

{
  // [Sprint 38 L3] The booked player protests once the card is up.
  const f = [{ b: [500, 340, 0], p: P(), h: 3 }, { b: [520, 340, 0], p: P(), h: 1 }, { b: [540, 340, 0], p: P(), h: 1 }]
  const ev = [{ type: 'foul', player: 3, victim: 1 }, { type: 'card', player: 3, color: 'yellow' }]
  check(pitchActions({ tick: 1, events: ev }, f, 0.75, ctx).by[3]?.kind === 'protest', 'the booked player protests')
  check(pitchActions({ tick: 1, events: [ev[0]] }, f, 0.75, ctx).by[3] === undefined, 'no card: no protest')
}
{
  // [Sprint 38 L1] An injury: down from his Keyframe with the ball, and stays down.
  const f = [{ b: [500, 340, 0], p: P(), h: 1 }, { b: [520, 340, 0], p: P(), h: 2 }, { b: [540, 340, 0], p: P(), h: 1 }]
  const ev = [{ type: 'injury', player: 2 }]
  check(pitchActions({ tick: 1, events: ev }, f, 0.3, ctx).by[2] === undefined, 'not down before his touch')
  const a = pitchActions({ tick: 1, events: ev }, f, 0.95, ctx)
  check(a.by[2]?.kind === 'fallen' && a.by[2].f === 1, 'the injured player down and staying down')
}
{
  // [Sprint 38 L2] Offside: the flag goes up when the attacker caught takes the ball; not for a goal VAR rules out.
  const f = [{ b: [500, 340, 0], p: P(), h: 1 }, { b: [820, 300, 0], p: P(), h: 2 }, { b: [840, 300, 0], p: P(), h: 2 }]
  const ev = [{ type: 'attack', result: 'offside', receiver: 2 }]
  check(pitchActions({ tick: 1, events: ev, moment: { kind: 'offside' } }, f, 0.3, ctx).flag === null, 'no flag before the pass arrives')
  const a = pitchActions({ tick: 1, events: ev, moment: { kind: 'offside' } }, f, 0.8, ctx)
  check(a.flag?.x === 820 && a.flag.w === 1, 'the flag up where he took it')
  check(pitchActions({ tick: 1, events: ev, moment: { kind: 'var' } }, f, 0.8, ctx).flag === null, 'VAR: no flag')
}

if (bad.length) {
  console.error('the live pitch (director.ts, actions.ts) changed\n' + bad.join('\n'))
  process.exit(1)
}
console.log('feed: director and actions OK')
