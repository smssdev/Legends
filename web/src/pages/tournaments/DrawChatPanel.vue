<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// [X66] The live draw's chat: everyone watching says a line or taps a reaction, and every screen shows it at once
// (channel draw.{id}); a reaction floats up over the draw. Open from an hour before until half an hour after; then kept,
// and a replay (cutoff: the server time the replay has reached) shows each line and reaction at the moment it came.
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { paths } from '../../api/schema'
import { live } from '../../lib/echo'
import { useAuth } from '../../stores/auth'

type Chat = paths['/tournaments/{league}/draw/chat']['get']['responses']['200']['content']['application/json']
type Line = Chat['messages'][number]
const props = defineProps<{ id: string; cutoff: number | null }>()
const auth = useAuth()
const chat = ref<Chat | null>(null)
const lines = ref<Line[]>([])
const draft = ref('')
const notice = ref('')
const list = ref<HTMLElement | null>(null)
const floating = ref<{ key: number; emoji: string; x: number }[]>([])
const reduced = typeof matchMedia !== 'undefined' && matchMedia('(prefers-reduced-motion: reduce)').matches
let poll = 0
let channel = ''
let seq = 0

function arrived(m: Line) {
  const i = lines.value.findIndex((x) => x.id === m.id)
  if (i >= 0) lines.value[i] = m
  else lines.value.push(m)
}
async function load(after?: number) {
  try {
    const { data } = await api.GET('/tournaments/{league}/draw/chat', { params: { path: { league: Number(props.id) }, query: after ? { after } : {} } })
    chat.value = data!
    data!.messages.forEach(arrived)
  } catch (e) {
    notice.value = asApiError(e).message
  }
}
onMounted(async () => {
  await load()
  try {
    channel = `draw.${props.id}`
    live().private(channel).listen('.draw-chat', (e: { message: Line }) => arrived(e.message))
  } catch { /* no live connection: the poll below brings them */ }
  // A screen without the live connection still follows the chat while it is open.
  poll = window.setInterval(() => { if (chat.value?.open) void load(lines.value[lines.value.length - 1]?.id) }, 4000)
})
onBeforeUnmount(() => { window.clearInterval(poll); try { if (channel) live().leave(channel) } catch { /* nothing to leave */ } })

/** Live: everything; in a replay: what had been said by the moment the replay shows. */
const shown = computed(() => lines.value.filter((m) => props.cutoff === null || m.at <= props.cutoff))
const texts = computed(() => shown.value.filter((m) => m.kind === 'text'))
const counts = computed(() => {
  const c: Record<string, number> = {}
  for (const m of shown.value) if (m.kind === 'emoji' && !m.deleted) c[m.body] = (c[m.body] ?? 0) + 1
  return c
})

// Each reaction that comes into view floats up once.
const floated = new Set<number>()
watch(shown, (all) => {
  for (const m of all) {
    if (m.kind !== 'emoji' || m.deleted || floated.has(m.id)) continue
    floated.add(m.id)
    if (reduced || floated.size > 400) continue
    const key = ++seq
    floating.value.push({ key, emoji: m.body, x: 8 + ((m.id * 37) % 80) })
    window.setTimeout(() => (floating.value = floating.value.filter((f) => f.key !== key)), 2600)
  }
  const el = list.value
  if (el && el.scrollHeight - el.scrollTop - el.clientHeight < 120) void nextTick(() => (el.scrollTop = el.scrollHeight))
}, { deep: true })
// A replay starts over: its reactions float again as it reaches them.
watch(() => props.cutoff === null, () => floated.clear())

async function say(kind: 'text' | 'emoji', body: string) {
  if (!body.trim()) return
  notice.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.POST('/tournaments/{league}/draw/chat', { params: { path: { league: Number(props.id) } }, body: { kind, body } })
    arrived(data!.message)
    if (kind === 'text') draft.value = ''
    navigator.vibrate?.(8)
  } catch (e) {
    notice.value = asApiError(e).message
  }
}
async function remove(m: Line) {
  try {
    await ensureCsrf()
    await api.DELETE('/tournaments/{league}/draw/chat/{message}', { params: { path: { league: Number(props.id), message: m.id } } })
    arrived({ ...m, deleted: true, body: '' })
  } catch (e) {
    notice.value = asApiError(e).message
  }
}
const mine = (m: Line) => m.user?.id === auth.user?.id
</script>

<template>
  <section class="z-10 flex flex-col gap-2 bg-panel/95 px-3 pb-[max(1rem,env(safe-area-inset-bottom))] pt-3" :aria-label="$t('دردشة القرعة')">
    <div class="pointer-events-none fixed inset-0 z-40 overflow-hidden" aria-hidden="true">
      <span v-for="f in floating" :key="f.key" class="float-up absolute bottom-24 text-4xl" :style="{ insetInlineStart: f.x + '%' }">{{ f.emoji }}</span>
    </div>

    <div class="flex items-center justify-between gap-2">
      <h2 class="font-bold">{{ $t('دردشة القرعة') }}</h2>
      <span class="flex flex-wrap gap-1 text-sm">
        <span v-for="(n, e) in counts" :key="e" class="rounded-full bg-surface-sunk px-2 font-numbers">{{ e }} {{ n }}</span>
      </span>
    </div>
    <ul ref="list" class="flex max-h-56 flex-col gap-1.5 overflow-y-auto" aria-live="polite">
      <li v-if="!texts.length" class="py-2 text-sm text-text-muted">{{ chat?.open ? $t('كن أول من يعلّق على القرعة!') : $t('لا تعليقات.') }}</li>
      <li v-for="m in texts" :key="m.id" class="group flex items-start gap-2 text-sm">
        <b class="shrink-0" :class="mine(m) ? 'text-gold' : 'text-brand-light'">{{ m.user?.name ?? $t('عضو سابق') }}:</b>
        <span class="min-w-0 flex-1 break-words" :class="m.deleted ? 'italic text-text-muted' : ''">{{ m.deleted ? $t('هذه الرسالة حُذفت') : m.body }}</span>
        <button v-if="!m.deleted && (mine(m) || chat?.can_moderate)" type="button" class="size-8 shrink-0 text-text-muted" :aria-label="$t('احذف الرسالة')" @click="remove(m)"><Icon name="close" :size="18" /></button>
      </li>
    </ul>

    <template v-if="chat?.open && cutoff === null">
      <div class="flex justify-between gap-1" role="group" :aria-label="$t('تفاعل')">
        <button v-for="e in chat.reactions" :key="e" type="button" class="grid size-11 place-items-center rounded-full bg-surface-sunk text-2xl transition active:scale-125"
          :aria-label="$t('تفاعل {v0}', { v0: e })" @click="say('emoji', e)">{{ e }}</button>
      </div>
      <form class="flex gap-2" @submit.prevent="say('text', draft)">
        <input v-model="draft" maxlength="200" :placeholder="$t('علّق على القرعة…')" :aria-label="$t('علّق على القرعة…')" class="h-touch min-w-0 flex-1 rounded-full bg-surface-sunk px-4" />
        <button type="submit" class="grid size-11 shrink-0 place-items-center rounded-full bg-gold font-extrabold text-on-gold disabled:opacity-50" :disabled="!draft.trim()" :aria-label="$t('أرسل')">
          <span class="rtl:-scale-x-100"><Icon name="send" :size="18" class="inline-block align-[-3px]" /></span></button>
      </form>
    </template>
    <p v-else-if="chat && !chat.open && cutoff === null" class="text-xs text-text-muted">{{ $t('تُفتح الدردشة قبل القرعة بساعة وتُغلق بعدها بنصف ساعة.') }}</p>
    <p v-if="notice" class="text-sm text-danger" role="alert">{{ $t(notice) }}</p>
  </section>
</template>

<style scoped>
.float-up { animation: float-up 2.6s ease-out forwards; }
@keyframes float-up {
  0% { transform: translateY(0) scale(0.6); opacity: 0; }
  15% { opacity: 1; transform: translateY(-40px) scale(1.15); }
  100% { transform: translateY(-60vh) translateX(20px) scale(1); opacity: 0; }
}
</style>
