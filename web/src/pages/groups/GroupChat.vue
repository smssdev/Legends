<script setup lang="ts">
// [Sprint 29] Inside a chat group (docs/design/legends-ui/Sprint29Drafts.html, 2): my messages on one side, the
// others' with their names on the other, the group's notes in the middle. New messages come at once on the group's
// channel; older ones load on scrolling up. A message can be answered or deleted; "⋮" opens the members, the link,
// adding, the admins and leaving.
import { useToast } from '../../stores/toast'
import { useConfirm } from '../../stores/confirm'
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import { live } from '../../lib/echo'
import { t } from '../../lib/i18n'
import { useAuth } from '../../stores/auth'
import UiButton from '../../components/ui/UiButton.vue'
import UiDialog from '../../components/ui/UiDialog.vue'
import { noteText } from './notes'

type Group = components['schemas']['ChatGroup']
type Message = components['schemas']['ChatMessage']
const props = defineProps<{ id: string }>()
const router = useRouter()
const auth = useAuth()
const group = ref<Group | null>(null)
const messages = ref<Message[]>([])
const error = ref('')
const draft = ref('')
const replyTo = ref<Message | null>(null)
const sending = ref(false)
const more = ref(true)
const menu = ref(false)
const picked = ref<Message | null>(null)
const adding = ref('')
const notice = ref('')
const list = ref<HTMLElement | null>(null)
const gid = computed(() => Number(props.id))
const me = computed(() => auth.user?.id)

const atBottom = () => !list.value || list.value.scrollHeight - list.value.scrollTop - list.value.clientHeight < 80
const toBottom = () => nextTick(() => list.value && (list.value.scrollTop = list.value.scrollHeight))

async function load() {
  try {
    const { data } = await api.GET('/groups/{group}', { params: { path: { group: gid.value } } })
    group.value = data!.group
    messages.value = data!.messages
    more.value = data!.messages.length >= 50
    toBottom()
  } catch (e) {
    error.value = asApiError(e).message
  }
}

async function older() {
  if (!more.value || !messages.value.length) return
  const el = list.value
  const before = el?.scrollHeight ?? 0
  const { data } = await api.GET('/groups/{group}/messages', { params: { path: { group: gid.value }, query: { before: messages.value[0].id } } })
  more.value = data!.messages.length >= 50
  messages.value = [...data!.messages, ...messages.value]
  await nextTick()
  if (el) el.scrollTop = el.scrollHeight - before
}

function arrived(m: Message) {
  const i = messages.value.findIndex((x) => x.id === m.id)
  if (i >= 0) messages.value[i] = m
  else {
    const stick = atBottom()
    messages.value.push(m)
    if (stick) toBottom()
    void api.POST('/groups/{group}/read', { params: { path: { group: gid.value } }, body: { last_id: m.id } }).catch(() => {})
  }
}

let channel = ''
function follow() {
  try {
    channel = `chat.${gid.value}`
    live().private(channel).listen('.chat', (e: { message: Message }) => arrived(e.message))
  } catch { /* no live connection: the messages come on the next visit */ }
}
onMounted(async () => { await load(); follow() })
onBeforeUnmount(() => { try { if (channel) live().leave(channel) } catch { /* nothing to leave */ } })
watch(gid, async () => { try { if (channel) live().leave(channel) } catch { /* nothing to leave */ } await load(); follow() })

/** [X65] A picture or a voice note, as the form the server reads; the caption is what is typed. */
async function sendMedia(kind: 'image' | 'audio', file: Blob, name: string, seconds?: number) {
  sending.value = true
  notice.value = ''
  try {
    await ensureCsrf()
    const form = new FormData()
    form.append('kind', kind)
    form.append('file', file, name)
    if (draft.value.trim()) form.append('caption', draft.value.trim())
    if (seconds) form.append('seconds', String(seconds))
    if (replyTo.value) form.append('reply_to', String(replyTo.value.id))
    const { data } = await api.POST('/groups/{group}/media', { params: { path: { group: gid.value } }, body: form as never, bodySerializer: (b: unknown) => b as FormData })
    arrived(data!.message)
    draft.value = ''
    replyTo.value = null
    toBottom()
  } catch (e) {
    notice.value = asApiError(e).message
  } finally {
    sending.value = false
  }
}
const picker = ref<HTMLInputElement | null>(null)
function picture(e: Event) {
  const f = (e.target as HTMLInputElement).files?.[0]
  if (f) void sendMedia('image', f, f.name)
  ;(e.target as HTMLInputElement).value = ''
}

// A voice note: tap to record, tap again to send (up to two minutes), ✕ to drop it.
const recording = ref(false)
const recorded = ref(0)
let recorder: MediaRecorder | null = null
let chunks: Blob[] = []
let started = 0
let clock = 0
let dropped = false
async function record() {
  if (recording.value) return void recorder?.stop()
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    const type = ['audio/webm;codecs=opus', 'audio/ogg;codecs=opus', 'audio/mp4'].find((m) => MediaRecorder.isTypeSupported(m)) ?? ''
    recorder = new MediaRecorder(stream, type ? { mimeType: type } : undefined)
    chunks = []
    dropped = false
    recorder.ondataavailable = (ev) => ev.data.size && chunks.push(ev.data)
    recorder.onstop = () => {
      stream.getTracks().forEach((tr) => tr.stop())
      window.clearInterval(clock)
      recording.value = false
      const secs = Math.max(1, Math.round((Date.now() - started) / 1000))
      const blob = new Blob(chunks, { type: recorder?.mimeType || 'audio/webm' })
      if (!dropped && blob.size) void sendMedia('audio', blob, blob.type.includes('mp4') ? 'voice.m4a' : blob.type.includes('ogg') ? 'voice.ogg' : 'voice.webm', secs)
    }
    recorder.start()
    started = Date.now()
    recorded.value = 0
    recording.value = true
    clock = window.setInterval(() => {
      recorded.value = Math.round((Date.now() - started) / 1000)
      if (recorded.value >= 120) recorder?.stop()
    }, 250)
  } catch {
    notice.value = t('اسمح للمتصفح باستخدام الميكروفون لتسجيل رسالة صوتية.')
  }
}
function dropRecording() { dropped = true; recorder?.stop() }
onBeforeUnmount(() => { dropped = true; recorder?.state === 'recording' && recorder.stop() })
const mmss = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`
const lightbox = ref<string | null>(null)

async function send() {
  const body = draft.value.trim()
  if (!body || sending.value) return
  sending.value = true
  try {
    await ensureCsrf()
    const { data } = await api.POST('/groups/{group}/messages', { params: { path: { group: gid.value } }, body: { body, reply_to: replyTo.value?.id ?? null } })
    arrived(data!.message)
    draft.value = ''
    replyTo.value = null
    toBottom()
  } catch (e) {
    notice.value = asApiError(e).message
  } finally {
    sending.value = false
  }
}

// [Sprint 30 G6] A report to the admins (once per message is enough).
const REPORT_REASONS = { abuse: 'سب أو إساءة', inappropriate: 'محتوى غير لائق', spam: 'إزعاج أو إعلانات', other: 'سبب آخر' } as const
const reporting = ref(false)
const reportReason = ref<keyof typeof REPORT_REASONS | ''>('')
const reportNote = ref('')
watch(picked, () => { reporting.value = false; reportReason.value = ''; reportNote.value = '' })
async function report(m: Message) {
  try {
    await ensureCsrf()
    await api.POST('/groups/{group}/messages/{message}/report', { params: { path: { group: gid.value, message: m.id } }, body: { reason: reportReason.value as 'abuse', note: reportNote.value.trim() || null } })
    useToast().show(t('وصل البلاغ للإدارة. شكراً لك.'))
    picked.value = null
  } catch (e) {
    notice.value = asApiError(e).message
  }
}
async function remove(m: Message) {
  picked.value = null
  try {
    await ensureCsrf()
    await api.DELETE('/groups/{group}/messages/{message}', { params: { path: { group: gid.value, message: m.id } } })
    arrived({ ...m, deleted: true, body: '' })
  } catch (e) {
    notice.value = asApiError(e).message
  }
}

async function act(run: () => Promise<{ data?: { group: Group } }>) {
  notice.value = ''
  try {
    await ensureCsrf()
    const { data } = await run()
    if (data?.group) group.value = { ...group.value!, ...data.group }
  } catch (e) {
    notice.value = asApiError(e).message
  }
}
const add = () => act(async () => {
  const r = await api.POST('/groups/{group}/members', { params: { path: { group: gid.value } }, body: { usernames: adding.value.split(/[\s,،]+/).filter(Boolean) } })
  adding.value = ''
  return r
})
const kick = async (user: number) => (await useConfirm().ask({ title: 'إخراج العضو من الجروب؟', action: 'أخرجه' })) && act(() => api.DELETE('/groups/{group}/members/{user}', { params: { path: { group: gid.value, user } } }))
const admin = (user: number, on: boolean) => act(() => api.PUT('/groups/{group}/members/{user}/admin', { params: { path: { group: gid.value, user } }, body: { admin: on } }))
async function leave() {
  if (!(await useConfirm().ask({ title: 'مغادرة الجروب؟', text: 'لن تصلك رسائله، ويعيدك أي مشرف بالإضافة أو الرابط.', action: 'غادر' }))) return
  try {
    await ensureCsrf()
    await api.POST('/groups/{group}/leave', { params: { path: { group: gid.value } } })
    await router.push({ name: 'groups' })
  } catch (e) {
    notice.value = asApiError(e).message
  }
}
async function copyLink() {
  if (!group.value?.invite_url) return
  try {
    await navigator.clipboard.writeText(group.value.invite_url)
    notice.value = t('نُسخ رابط الجروب.')
  } catch { notice.value = group.value.invite_url }
}

const hhmm = (iso: string) => new Date(iso).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })
const members = computed(() => (group.value?.members ?? []).map((m) => m.name).slice(0, 4).join('، '))
</script>

<template>
  <div class="-mx-4 -my-4 flex h-[calc(100dvh-8rem)] flex-col md:mx-0 md:my-0 md:h-[calc(100dvh-6rem)] md:overflow-hidden md:rounded-2xl">
    <header class="flex items-center gap-3 border-b border-text/10 bg-panel px-4 py-3">
      <RouterLink :to="{ name: 'groups' }" class="grid size-11 place-items-center text-xl" :aria-label="$t('الجروبات')">‹</RouterLink>
      <span class="min-w-0 flex-1">
        <b class="block truncate">{{ group?.name }}</b>
        <small class="block truncate text-text-muted">{{ $t('{n} أعضاء', { n: group?.members_count ?? 0 }) }} · {{ members }}</small>
      </span>
      <RouterLink v-if="group?.league_id" :to="{ name: 'league-home', params: { id: group.league_id } }" class="text-sm font-bold text-gold">{{ $t('الدوري') }}</RouterLink>
      <button class="grid size-11 place-items-center rounded-full text-xl hover:bg-surface" :aria-label="$t('خيارات الجروب')" @click="menu = true">⋮</button>
    </header>
    <p v-if="error" class="m-3 rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <div ref="list" class="flex flex-1 flex-col gap-2 overflow-y-auto bg-bg px-3 py-3" aria-live="polite" @scroll.passive="list && list.scrollTop < 40 && older()">
      <template v-for="m in messages" :key="m.id">
        <span v-if="m.kind === 'note'" class="self-center rounded-full bg-surface-sunk px-3 py-1 text-xs text-text-muted">{{ noteText(m.body) }}</span>
        <button v-else type="button" class="max-w-[80%] rounded-2xl px-3 py-2 text-start text-[15px] leading-relaxed"
          :class="m.user?.id === me ? 'self-start rounded-ee-md bg-brand' : 'self-end rounded-es-md bg-surface-raised'" @click="!m.deleted && (picked = m)">
          <i v-if="m.user?.id !== me" class="block text-xs font-bold not-italic text-gold-light">{{ m.user?.name ?? $t('عضو سابق') }}</i>
          <span v-if="m.reply_to" class="mb-1 block border-s-2 border-gold-light ps-2 text-xs opacity-80">{{ m.reply_to.body || $t('هذه الرسالة حُذفت') }}</span>
          <span v-if="m.deleted" class="italic text-text-muted">{{ $t('هذه الرسالة حُذفت') }}</span>
          <template v-else>
            <img v-if="m.kind === 'image' && m.media_url" :src="m.media_url" :alt="m.body || $t('صورة')" loading="lazy"
              class="mb-1 max-h-72 w-full rounded-xl object-cover" @click.stop="lightbox = m.media_url" />
            <span v-if="m.kind === 'audio' && m.media_url" class="mb-1 flex items-center gap-2" @click.stop>
              <span aria-hidden="true">🎤</span><audio :src="m.media_url" controls preload="none" class="h-10 max-w-[230px]" />
              <span v-if="m.seconds" class="font-numbers text-xs opacity-80" dir="ltr">{{ mmss(m.seconds) }}</span>
            </span>
            <span v-if="m.body" class="whitespace-pre-wrap break-words">{{ m.body }}</span>
          </template>
          <span class="mt-0.5 block text-end font-numbers text-[11px] opacity-70" dir="ltr">{{ hhmm(m.created_at) }}</span>
        </button>
      </template>
    </div>

    <p v-if="notice" class="bg-surface-sunk px-4 py-2 text-sm" role="status">{{ $t(notice) }}</p>
    <div v-if="replyTo" class="flex items-center gap-2 bg-panel px-4 pt-2 text-sm">
      <span class="min-w-0 flex-1 truncate border-s-2 border-gold-light ps-2 text-text-muted">{{ replyTo.body || (replyTo.kind === 'image' ? $t('صورة') : replyTo.kind === 'audio' ? $t('رسالة صوتية') : '') }}</span>
      <button class="size-9" :aria-label="$t('إلغاء الرد')" @click="replyTo = null">✕</button>
    </div>
    <!-- [Sprint 40 B3] A finished league's group: kept to read, no more messages. -->
    <p v-if="group?.closed" class="bg-panel p-4 text-center text-sm text-text-muted pb-[max(1rem,env(safe-area-inset-bottom))]" role="status">{{ $t('انتهى الدوري، وجروبه للقراءة فقط.') }}</p>
    <form v-else class="flex items-end gap-2 bg-panel p-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] pe-20 md:pe-3" @submit.prevent="send">
      <template v-if="recording">
        <button type="button" class="grid size-12 shrink-0 place-items-center rounded-full bg-surface-sunk" :aria-label="$t('ألغِ التسجيل')" @click="dropRecording">✕</button>
        <span class="flex min-h-touch flex-1 items-center gap-2 rounded-3xl bg-surface-sunk px-4" role="status">
          <span class="size-2.5 animate-pulse rounded-full bg-live" /><span class="font-numbers" dir="ltr">{{ mmss(recorded) }}</span>
          <span class="text-sm text-text-muted">{{ $t('يُسجَّل… اضغط ➤ للإرسال') }}</span></span>
        <button type="button" class="grid size-12 shrink-0 place-items-center rounded-full bg-gold text-lg font-black text-on-gold" :aria-label="$t('أرسل الرسالة الصوتية')" @click="record">
          <span class="rtl:-scale-x-100">➤</span></button>
      </template>
      <template v-else>
      <input ref="picker" type="file" accept="image/*" class="hidden" @change="picture" />
      <button type="button" class="grid size-12 shrink-0 place-items-center rounded-full bg-surface-sunk text-xl disabled:opacity-50" :disabled="sending"
        :aria-label="$t('أرسل صورة')" @click="picker?.click()">📷</button>
      <textarea v-model="draft" rows="1" maxlength="1000" :placeholder="$t('اكتب رسالة…')" :aria-label="$t('اكتب رسالة…')"
        class="max-h-32 min-h-touch flex-1 resize-none rounded-3xl bg-surface-sunk px-4 py-3" @keydown.enter.exact.prevent="send" />
      <button type="submit" class="grid size-12 shrink-0 place-items-center rounded-full bg-gold text-lg font-black text-on-gold disabled:opacity-50"
        :disabled="sending" :aria-label="draft.trim() ? $t('أرسل') : $t('سجّل رسالة صوتية')" @click="!draft.trim() && ($event.preventDefault(), record())">
        <span v-if="draft.trim()" class="rtl:-scale-x-100">➤</span><span v-else>🎤</span></button>
      </template>
    </form>
    <UiDialog :open="!!lightbox" bare @close="lightbox = null">
      <img v-if="lightbox" :src="lightbox" :alt="$t('صورة')" class="max-h-[85vh] w-full rounded-xl object-contain" @click="lightbox = null" />
    </UiDialog>

    <UiDialog :open="!!picked" :title="$t('الرسالة')" @close="picked = null">
      <div class="flex flex-col gap-2">
        <UiButton variant="outline" block @click="replyTo = picked; picked = null">{{ $t('رد') }}</UiButton>
        <UiButton v-if="picked && (picked.user?.id === me || group?.is_admin)" variant="danger" block @click="remove(picked!)">{{ $t('احذف الرسالة') }}</UiButton>
        <!-- [Sprint 30 G6] Another's message to the admins: why, and a word if needed. -->
        <template v-if="picked && picked.user && picked.user.id !== me">
          <UiButton v-if="!reporting" variant="quiet" block @click="reporting = true">{{ $t('بلّغ عن الرسالة') }}</UiButton>
          <form v-else class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3" @submit.prevent="report(picked!)">
            <span class="text-sm font-bold">{{ $t('لماذا تبلّغ عنها؟') }}</span>
            <label v-for="(label, k) in REPORT_REASONS" :key="k" class="flex min-h-touch items-center gap-2 text-sm"><input v-model="reportReason" type="radio" :value="k" class="size-5 accent-gold" />{{ $t(label) }}</label>
            <input v-model="reportNote" maxlength="300" :placeholder="$t('تفاصيل (اختياري)')" class="h-touch rounded-md bg-surface px-3 text-sm" />
            <UiButton type="submit" variant="danger" block :disabled="!reportReason">{{ $t('أرسل البلاغ للإدارة') }}</UiButton>
          </form>
        </template>
      </div>
    </UiDialog>

    <UiDialog :open="menu" :title="group?.name" @close="menu = false">
      <div class="flex flex-col gap-3">
        <template v-if="group?.invite_url">
          <p class="text-sm text-text-muted">{{ $t('أي مدرب يفتح هذا الرابط ينضم إلى الجروب.') }}</p>
          <UiButton variant="outline" block @click="copyLink">{{ $t('انسخ رابط الجروب') }}</UiButton>
        </template>
        <form v-if="group?.is_admin && !group.league_id" class="flex gap-2" @submit.prevent="add">
          <input v-model="adding" dir="ltr" :placeholder="$t('اسم المستخدم')" class="h-touch min-w-0 flex-1 rounded-lg bg-surface-sunk px-3" />
          <UiButton type="submit">{{ $t('أضف') }}</UiButton>
        </form>
        <h3 class="font-bold">{{ $t('الأعضاء') }}</h3>
        <ul class="flex max-h-72 flex-col gap-1 overflow-y-auto">
          <li v-for="m in group?.members ?? []" :key="m.id" class="flex min-h-touch items-center gap-2 rounded-lg bg-surface-sunk px-3">
            <span class="min-w-0 flex-1 truncate">{{ m.name }} <small class="text-text-muted" dir="ltr">@{{ m.username }}</small></span>
            <span v-if="m.is_admin" class="rounded-full bg-gold/20 px-2 text-xs font-bold text-gold">{{ $t('مشرف') }}</span>
            <template v-if="group?.is_admin && !group.league_id && m.id !== me">
              <button class="min-h-touch px-2 text-xs font-bold text-text-muted" @click="admin(m.id, !m.is_admin)">{{ m.is_admin ? $t('أزل الإشراف') : $t('اجعله مشرفاً') }}</button>
              <button class="min-h-touch px-2 text-xs font-bold text-danger" @click="kick(m.id)">{{ $t('أخرج') }}</button>
            </template>
          </li>
        </ul>
        <UiButton v-if="!group?.league_id" variant="danger" block @click="leave">{{ $t('غادر الجروب') }}</UiButton>
      </div>
    </UiDialog>
  </div>
</template>
