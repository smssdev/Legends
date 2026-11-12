// [Sprint 22] The Assistant Coach's conversation (Manager Bot in English): kept while the coach moves between screens,
// and gone with the visit (the server never keeps it either). Each question carries the last messages, so he
// remembers what was said.
// [X61] Its end: «إنهاء» (or a recommendation followed) closes on a card; «احفظ وتابع لاحقاً» keeps the last
// conversation on this device only, and the next opening offers «تابع من حيث توقفت».
import { storage } from '../lib/storage'
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../api/client'
import type { components } from '../api/schema'

type Question = components['schemas']['AssistantQuestion']
export interface BotMessage { from: 'me' | 'bot'; text: string; go?: string | null; related?: Question[]; notice?: string | null }

export const useBot = defineStore('bot', () => {
  const open = ref(false)
  const name = ref('')
  const messages = ref<BotMessage[]>([])
  const questions = ref<Question[]>([])
  const ai = ref(false)
  const remaining = ref<number | null>(null)
  const limited = ref(false)
  const thinking = ref(false)
  let page = ''
  // The closing card: shown, and why (the coach ended it, or followed an answer's page).
  const closing = ref<null | 'ended' | 'done'>(null)
  const followed = ref<string | null>(null)
  const SAVED = 'bot.saved'
  type Saved = { at: string; messages: BotMessage[] }
  const saved = ref<Saved | null>(read())
  function read(): Saved | null {
    try { return JSON.parse(storage.get(SAVED) ?? 'null') } catch { return null }
  }

  /** «إنهاء»: a short goodbye from him, then the card. */
  function end(goodbye: string) {
    if (messages.value.length > 1) messages.value.push({ from: 'bot', text: goodbye })
    closing.value = 'ended'
  }
  function save() {
    const kept: Saved = { at: new Date().toISOString(), messages: messages.value.slice(-12).map(({ from, text, go }) => ({ from, text, go })) }
    try { storage.set(SAVED, JSON.stringify(kept)) } catch {}
    saved.value = kept
  }
  /** Back to the saved conversation; it stays saved until a new one is. */
  function resume() {
    if (saved.value) messages.value = [...saved.value.messages]
  }
  /** Forgets the saved conversation; at sign-out (all: true, Sprint 51 W5) the one on screen too. */
  function forget(all = false) {
    try { storage.remove(SAVED) } catch {}
    saved.value = null
    if (all) {
      messages.value = []
      open.value = false
      closing.value = null
    }
  }

  /** The page's quick questions (and, the first time, who he is). */
  async function start(at: string) {
    if (at === page && messages.value.length) return
    page = at
    const { data } = await api.GET('/assistant/start', { params: { query: { page: at } } })
    if (!data) return
    name.value = data.name
    questions.value = data.questions
    ai.value = data.ai
    remaining.value = data.remaining
    if (!messages.value.length) messages.value.push({ from: 'bot', text: data.intro })
  }

  async function ask(question: string, topic: string | null, leagueId: number | null) {
    const text = question.trim()
    if (!text || thinking.value) return
    const history = messages.value.slice(1).slice(-8).map((m) => ({ from: m.from, text: m.text.slice(0, 2000) }))
    messages.value.push({ from: 'me', text })
    thinking.value = true
    try {
      const { data } = await api.POST('/assistant/ask', { body: { question: text.slice(0, 500), topic, page, league_id: leagueId, history } })
      if (data) {
        messages.value.push({ from: 'bot', text: data.answer, go: data.go, related: data.related, notice: data.notice })
        remaining.value = data.remaining
        limited.value = data.notice === 'limit'
      }
    } catch (e) {
      messages.value.push({ from: 'bot', text: e instanceof Error ? e.message : '' })
    } finally {
      thinking.value = false
    }
  }

  return { open, name, messages, questions, ai, remaining, limited, thinking, start, ask, closing, followed, saved, end, save, resume, forget }
})
