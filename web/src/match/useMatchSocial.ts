// [Sprint 57 W1] The match between the screens [X24]: the reactions (the two coaches cheer and tease; in a league every
// member who watches, and a cheer or a boo for one side once in half a minute) and the side chat of the league's
// viewers. Each reaction and line is shown once, whether it came from the poll, the channel or this screen.
import { ref, type Ref } from 'vue'
import { leagueMatch, sim, type ChatLine, type Reaction, type Side } from '../api/sim'

export const REACTIONS = [
  { key: 'fire', emoji: '🔥', text: '', label: 'نار' },
  { key: 'clap', emoji: '👏', text: '', label: 'تصفيق' },
  { key: 'wow', emoji: '😱', text: '', label: 'يا للهول' },
  { key: 'laugh', emoji: '😂', text: '', label: 'ضحك' },
  { key: 'angry', emoji: '😤', text: '', label: 'غضب' },
  { key: 'pray', emoji: '🤲', text: '', label: 'يا رب' },
  { key: 'unlucky', emoji: '😅', text: 'هاردلك', label: 'هاردلك' },
  { key: 'coming', emoji: '⚽', text: 'جاي الهدف', label: 'جاي الهدف' },
  { key: 'easy', emoji: '😎', text: 'سهلة', label: 'سهلة' },
  { key: 'focus', emoji: '🧠', text: 'ركّز', label: 'ركّز' },
]
/** The league's boos and cheers for one side [X24]. */
export const CHEERS = { cheer: { emoji: '📣', text: 'تشجيع' }, boo: { emoji: '👎', text: 'استهجان' } } as const

export type SocialDeps = {
  league: boolean
  id: string
  mine: Ref<Side | null>
  /** Shows a reaction on the picture: its side, emoji, words and who. */
  show: (side: Side, emoji: string, text: string, who: string) => void
  /** Who a side is, for a reaction without a name. */
  sideName: (side: Side) => string
  /** A reaction from someone else (a pop on the speakers). */
  pop: () => void
}

export function useMatchSocial(d: SocialDeps) {
  const shown = new Set<number>()
  const mineIds = new Set<number>()
  const reactWait = ref(false)
  const cheerLeft = ref(0)
  let cheerTimer = 0

  function receive(x: Reaction) {
    if (shown.has(x.id)) return
    shown.add(x.id)
    const r = x.key in CHEERS ? CHEERS[x.key as keyof typeof CHEERS] : REACTIONS.find((r) => r.key === x.key)
    if (!r) return
    // A boo or a cheer rises on its target's side; a member who watches has no side: by turns.
    const side: Side = x.target ?? x.side ?? (x.id % 2 ? 'home' : 'away')
    const mineToo = mineIds.has(x.id) || (!d.league && x.side === d.mine.value)
    d.show(side, r.emoji, r.text, mineToo ? 'أنت' : (x.who ?? (x.side ? d.sideName(x.side) : '')))
    if (!mineToo) d.pop()
  }

  async function react(key: string, target?: Side) {
    const cheer = key in CHEERS
    if (!cheer) {
      reactWait.value = true
      window.setTimeout(() => (reactWait.value = false), 1300)
    }
    try {
      const x = d.league ? await leagueMatch.react(d.id, key, target) : await sim.react(d.id, key)
      mineIds.add(x.id)
      receive(x)
      if (cheer) {
        cheerLeft.value = 30
        window.clearInterval(cheerTimer)
        cheerTimer = window.setInterval(() => {
          if (--cheerLeft.value <= 0) window.clearInterval(cheerTimer)
        }, 1000)
      }
    } catch {
      /* too soon: the button comes back in a moment */
    }
  }

  const chat = ref<ChatLine[]>([])
  const chatText = ref('')
  const chatWait = ref(false)
  const chatError = ref('')
  /** The chat's scrolling box (the component sets it), kept at its end while the reader is there. */
  const chatBox = ref<HTMLElement | null>(null)

  function hear(c: ChatLine) {
    if (chat.value.some((x) => x.id === c.id)) return
    const box = chatBox.value
    const atEnd = !box || box.scrollHeight - box.scrollTop - box.clientHeight < 40
    chat.value = [...chat.value, c].slice(-50)
    if (atEnd) requestAnimationFrame(() => chatBox.value?.scrollTo({ top: chatBox.value.scrollHeight }))
  }

  async function sendChat() {
    const body = chatText.value.trim()
    if (!body) return
    chatWait.value = true
    chatError.value = ''
    try {
      hear(await leagueMatch.chat(d.id, body))
      chatText.value = ''
    } catch (e) {
      chatError.value = (e as Error).message
    } finally {
      window.setTimeout(() => (chatWait.value = false), 2000)
    }
  }

  const dispose = () => window.clearInterval(cheerTimer)

  return { receive, react, reactWait, cheerLeft, chat, chatText, chatWait, chatError, chatBox, hear, sendChat, dispose }
}
export type MatchSocial = ReturnType<typeof useMatchSocial>
