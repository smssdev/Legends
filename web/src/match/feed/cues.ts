// [Sprint 57 W3] What a scene sounds like and what the studio reacts to after it, from the minute's story (pure; the
// feed plays them on the scene's clock). Moved from MatchFeed.vue as they were.
import type { Story } from './told'

/** A sound at a fraction of the scene, or at its key moment. */
export type Cue = [number | 'key', string]

const SOUNDS: Record<string, Cue[]> = {
  goal: [[0.3, 'kick'], ['key', 'kick'], ['key', 'roar']], save: [[0.3, 'kick'], ['key', 'groan']], miss: [[0.3, 'kick'], ['key', 'groan']], blocked: [['key', 'thud'], ['key', 'groan']],
  penalty: [[0.03, 'whistle-long'], [0.34, 'heart'], [0.42, 'heart'], [0.51, 'heart'], ['key', 'kick'], ['key', 'roar']], freekick: [[0.05, 'whistle'], [0.25, 'heart'], [0.37, 'heart'], ['key', 'kick'], ['key', 'roar']],
  // [Sprint 42] The cartoon clips: the tackle's thud and the whistle, the card, the injury's whistle, the sub's beeps.
  card: [[0.12, 'thud'], [0.14, 'whistle'], ['key', 'whistle'], ['key', 'murmur']], foul: [[0.29, 'thud'], [0.31, 'whistle'], [0.57, 'whistle']],
  // [Sprint 42 F] The second set: the shot and the kick off the line, the trap's whistle, the megaphone's murmur, the slip.
  clearance: [[0.1, 'kick'], ['key', 'thud'], [0.66, 'groan']], trap: [['key', 'whistle']], rant: [[0.1, 'murmur']], slip: [['key', 'thud'], [0.4, 'groan']], var: [[0.32, 'kick'], [0.37, 'roar'], [0.52, 'whistle'], ['key', 'whistle'], ['key', 'groan']], offside: [['key', 'whistle']], corner: [[0.35, 'kick'], ['key', 'kick']], whistle: [[0.1, 'whistle']], sub: [[0.06, 'beep'], [0.2, 'beep'], [0.52, 'thud']], board: [[0.1, 'beep']], injury: [[0.04, 'whistle'], [0.2, 'groan']],
}
// [Sprint 42] And each card's drama: the whistles round the swarm, the thumps in the fight, the bottle kicked.
const DRAMA_SOUNDS: Record<string, Cue[]> = { swarm: [[0.31, 'whistle'], [0.35, 'whistle'], [0.39, 'whistle'], [0.43, 'whistle']], brawl: [[0.3, 'thud'], [0.34, 'thud'], [0.38, 'thud'], [0.42, 'whistle']], spit: [[0.39, 'murmur'], [0.4, 'groan']] }

/** The scene's sounds. */
export function soundsOf(s: Story): Cue[] {
  const base = (s.scene && SOUNDS[s.scene]) || []
  if (s.scene === 'foul' && s.data.drama === 'dive') return [[0.25, 'groan'], [0.8, 'whistle']]
  // [Sprint 42 F2] The double save's second shot and second block; the blackout's dark silence, then the roar.
  if (s.scene === 'save' && s.data.drama === 'double') return [...base, [0.69, 'kick'], [0.79, 'thud'], [0.8, 'roar']]
  if (s.scene !== 'card') return base
  return [...base, ...(DRAMA_SOUNDS[s.data.drama] ?? []), ...(s.data.type === 'red' ? [[0.78, 'kick'] as Cue] : [])]
}

/** [Sprint 42 J2] What the commentators react to back in the studio after a clip (the moment, as their pools name it). */
export function reactionKey(s: Story): string | null {
  if (!s.scene) return null
  const d = s.data ?? {}
  return s.goal && s.scene !== 'penalty' ? (d.drama === 'blackout' ? 'blackout' : 'goal')
    : s.scene === 'penalty' ? (d.scored ? 'penalty_goal' : 'penalty_miss')
    : s.scene === 'save' ? (d.drama === 'double' ? 'double' : 'save')
    : s.scene === 'miss' ? (d.how === 'post' ? 'post' : 'miss')
    : s.scene === 'card' ? (['brawl', 'spit'].includes(d.drama) ? 'brawl' : d.type === 'red' ? 'red' : 'yellow')
    : s.scene === 'foul' ? (d.drama === 'dive' ? 'dive' : 'foul')
    : s.scene === 'trap' ? 'offside' : s.scene === 'rant' ? 'coach' : s.scene === 'blocked' ? 'miss' : s.scene
}
