// The inbox (Sprint 22): the unread count for the badge, the messages, and reading them. New messages and
// reads from the account's other screens come on its private channel (Reverb); the count is also asked
// every minute and on return to the page, so it stays right without the live connection.
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import { live } from '../lib/echo'

export type Message = components['schemas']['Message']

export const useInbox = defineStore('inbox', () => {
  const unread = ref(0)
  const messages = ref<Message[]>([])
  const more = ref(false)
  const loaded = ref(false)
  const error = ref('')
  let userId: number | null = null
  let timer = 0

  async function count() {
    try {
      const { data } = await api.GET('/messages/unread')
      unread.value = data!.unread
    } catch {
      /* the badge keeps its last number */
    }
  }

  async function load(next = false) {
    try {
      const before = next && messages.value.length ? messages.value[messages.value.length - 1].id : undefined
      const { data } = await api.GET('/messages', { params: { query: { before } } })
      messages.value = next ? [...messages.value, ...data!.messages] : data!.messages
      more.value = data!.more
      unread.value = data!.unread
      error.value = ''
    } catch (e) {
      error.value = asApiError(e).message
    }
    loaded.value = true
  }

  function markRead(ids: number[] | 'all', left: number) {
    for (const m of messages.value) if (ids === 'all' || ids.includes(m.id)) m.read = true
    unread.value = left
  }

  async function read(m: Message) {
    if (m.read) return
    m.read = true
    unread.value = Math.max(0, unread.value - 1)
    try {
      await ensureCsrf()
      const { data } = await api.POST('/messages/{message}/read', { params: { path: { message: m.id } } })
      unread.value = data!.unread
    } catch {
      /* read on the next try */
    }
  }

  async function readAll() {
    markRead('all', 0)
    try {
      await ensureCsrf()
      await api.POST('/messages/read-all')
    } catch (e) {
      error.value = asApiError(e).message
    }
  }

  /** Start following the account's inbox (once signed in); stop when signed out. */
  function follow(id: number | null) {
    if (id === userId) return
    if (userId) live().leave(`App.Models.User.${userId}`)
    window.clearInterval(timer)
    userId = id
    messages.value = []
    loaded.value = false
    unread.value = 0
    if (!id) return
    count()
    timer = window.setInterval(count, 60_000)
    try {
      live().private(`App.Models.User.${id}`)
        .listen('.message', (e: { message: Message; unread: number }) => {
          if (!messages.value.some((m) => m.id === e.message.id)) messages.value.unshift(e.message)
          unread.value = e.unread
        })
        .listen('.messages-read', (e: { ids: number[]; unread: number }) => markRead(e.ids, e.unread))
    } catch {
      /* no live connection: the minute count keeps the badge */
    }
  }
  if (typeof document !== 'undefined') document.addEventListener('visibilitychange', () => document.visibilityState === 'visible' && userId && count())

  return { unread, messages, more, loaded, error, load, read, readAll, follow, count }
})
