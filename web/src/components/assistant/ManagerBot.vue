<script setup lang="ts">
// [Sprint 22 W1, W2] The Assistant Coach (Manager Bot in English), on every screen of the game: the owner's approved
// draft (docs/design/legends-ui/ManagerBotDraft.html). A gold button fixed on the left in Arabic and on the right in
// English (the owner, 2026-10-29), still, never dragged; once a day a greeting beside it. Its window fills the phone and is a side panel on the computer: who he is,
// the page's quick questions, and the conversation. Every explanation of the game lives here, not on the screens.
import { computed, nextTick, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { SECTIONS } from '../../layouts/nav'
import { locale } from '../../lib/i18n'
import { useBot, type BotMessage } from '../../stores/bot'
import { useSlot } from '../../stores/slot'
import { t } from '../../lib/i18n'
import BotClosing from './BotClosing.vue'

// Raised above the phone's bottom bar inside a slot.
const props = defineProps<{ raised?: boolean }>()

const bot = useBot()
const slot = useSlot()
const route = useRoute()
const router = useRouter()
const draft = ref('')
const input = ref<HTMLTextAreaElement | null>(null)
const list = ref<HTMLElement | null>(null)
const leagueId = computed(() => slot.current?.league?.id ?? null)
const page = computed(() => String(route.name ?? 'home'))

// The greeting: the first visit of the day, until closed.
const HELLO = 'glm.bot.hello'
const today = new Date().toDateString()
const hello = ref((() => { try { return localStorage.getItem(HELLO) !== today } catch { return false } })())
function quiet() {
  hello.value = false
  try { localStorage.setItem(HELLO, today) } catch {}
}

async function show() {
  quiet()
  bot.open = true
  // [X61] Back after following an answer's page on the phone: the task is done, and the card says so.
  if (bot.followed) bot.closing = 'done'
  await bot.start(page.value)
  await nextTick()
  input.value?.focus()
  scroll()
}
watch(page, (p) => bot.open && bot.start(p))
watch(locale, () => { bot.messages = []; bot.open && bot.start(page.value) })
watch(() => bot.messages.length, scroll)
async function scroll() {
  await nextTick()
  list.value?.scrollTo({ top: list.value.scrollHeight, behavior: 'smooth' })
}

function send(question = draft.value, topic: string | null = null) {
  if (!question.trim()) return
  void bot.ask(question, topic, leagueId.value)
  if (question === draft.value) draft.value = ''
}
function key(e: KeyboardEvent) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    send()
  }
}

// An answer's button: the section it names, in the club's league when it lives under one.
function pathFor(go: string): string {
  const league = leagueId.value
  if (go === 'league') return league ? `/leagues/${league}` : '/leagues'
  const s = SECTIONS.find((x) => x.name === go)
  if (s?.inLeague) return league ? `/leagues/${league}${s.path}` : '/leagues'
  return s?.path ?? `/${go}`
}
const labelOf = (go: string) => SECTIONS.find((x) => x.name === go)?.label ?? ({ wallet: 'المحفظة', profile: 'حسابي', support: 'الدعم' } as Record<string, string>)[go] ?? go
function goTo(go: string) {
  void router.push(pathFor(go))
  // [X61] A recommendation followed ends the task: on the computer the closing card at once, on the phone (whose
  // window closes on the page) the next time it opens.
  bot.followed = go
  if (window.matchMedia('(max-width: 767px)').matches) bot.open = false
  else bot.closing = 'done'
}
function end() {
  bot.end(t('على راحتك يا كوتش. هذه خلاصة ما دار بيننا.'))
}

// The answer as text: bold (**) and lists (lines starting with * or -) from the AI, nothing else; escaped first.
function rich(m: BotMessage): string {
  const esc = m.text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  return esc.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>').replace(/^\s*[*-]\s+/gm, '• ')
}
const isPhone = () => window.matchMedia('(max-width: 767px)').matches
const status = computed(() => (!bot.ai ? 'guide' : bot.limited || bot.remaining === 0 ? 'limit' : 'on'))
</script>

<template>
  <div class="bot-root" :class="props.raised ? 'raised' : ''">
    <!-- W1: the button, and the day's greeting beside it. -->
    <div v-if="!bot.open" class="bot-fab-row">
      <!-- [X62] The owner's decision (2026-10-30): the button comes alive, two eyes that look around and blink
           (Sprint 22's still button replaced); still with reduced motion. -->
      <button type="button" class="bot-fab" :aria-label="$t('افتح المدرب المساعد')" @click="show">
        <svg viewBox="0 0 32 32" aria-hidden="true"><path d="M6 5h20a3 3 0 0 1 3 3v12a3 3 0 0 1-3 3H14l-6 5v-5H6a3 3 0 0 1-3-3V8a3 3 0 0 1 3-3z" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linejoin="round" />
          <g class="bot-eyes"><ellipse cx="11.5" cy="13.5" rx="2.6" ry="3" fill="currentColor" /><ellipse cx="20.5" cy="13.5" rx="2.6" ry="3" fill="currentColor" />
            <g class="bot-pupils"><circle cx="12.2" cy="12.8" r="0.9" fill="var(--color-gold-light)" /><circle cx="21.2" cy="12.8" r="0.9" fill="var(--color-gold-light)" /></g></g></svg>
        <span class="bot-on" />
      </button>
      <div v-if="hello" class="bot-hello">
        <button type="button" class="bot-hello-x" :aria-label="$t('إغلاق')" @click="quiet">✕</button>
        <button type="button" class="text-start" @click="show">
          <b class="block text-sm">{{ $t('أهلاً كوتش!') }}</b>
          <span class="text-xs">{{ $t('أنا المدرب المساعد، اسألني عن أي شيء') }}</span>
        </button>
      </div>
    </div>

    <!-- W2: the window. -->
    <section v-else class="bot-panel" role="dialog" :aria-label="bot.name || $t('المدرب المساعد')" @keydown.esc="bot.open = false">
      <header class="bot-head">
        <span class="bot-fab small" aria-hidden="true">
          <svg viewBox="0 0 32 32"><path d="M6 5h20a3 3 0 0 1 3 3v12a3 3 0 0 1-3 3H14l-6 5v-5H6a3 3 0 0 1-3-3V8a3 3 0 0 1 3-3z" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linejoin="round" /><path d="M16 6v16" stroke="currentColor" stroke-width="1.8" /><circle cx="16" cy="14" r="3.8" fill="none" stroke="currentColor" stroke-width="1.8" /><circle cx="16" cy="14" r="1.3" fill="currentColor" /></svg>
        </span>
        <div class="min-w-0 flex-1">
          <b class="block truncate">{{ bot.name || $t('المدرب المساعد') }}</b>
          <small v-if="status === 'on'" class="text-ring">● {{ leagueId ? $t('متصل · يعرف ناديك') : $t('متصل') }}</small>
          <small v-else-if="status === 'limit'" class="text-warning">● {{ $t('من دليل اللعبة حتى الغد') }}</small>
          <small v-else class="text-text-muted">● {{ $t('من دليل اللعبة') }}</small>
        </div>
        <button v-if="bot.messages.length > 1" type="button" class="bot-end" @click="end">{{ $t('إنهاء') }}</button>
        <button type="button" class="bot-close" :aria-label="$t('إغلاق')" @click="bot.open = false">✕</button>
      </header>

      <div ref="list" class="bot-body" aria-live="polite">
        <!-- [X61] A conversation kept for later: pick it up, or start again. -->
        <div v-if="bot.saved && bot.messages.length <= 1" class="bot-resume">
          <b class="text-sm">{{ $t('تابع من حيث توقفت') }}</b>
          <p class="line-clamp-2 text-xs text-text-muted" dir="auto">{{ bot.saved.messages.filter((m) => m.from === 'bot').slice(-1)[0]?.text }}</p>
          <div class="flex gap-2">
            <button type="button" class="bot-go mt-0 flex-1 justify-center" @click="bot.resume(); scroll()">{{ $t('تابع') }}</button>
            <button type="button" class="bot-q flex-1" @click="bot.forget()">{{ $t('ابدأ من جديد') }}</button>
          </div>
        </div>
        <template v-for="(m, i) in bot.messages" :key="i">
          <div class="bot-msg" :class="m.from" dir="auto">
            <span class="whitespace-pre-line" v-html="rich(m)" />
            <button v-if="m.go" type="button" class="bot-go" @click="goTo(m.go)">{{ $t('افتح {v0}', { v0: $t(labelOf(m.go)) }) }} {{ locale === 'ar' ? '←' : '→' }}</button>
          </div>
          <p v-if="m.notice === 'limit'" class="text-center text-xs text-text-muted">{{ $t('التحليل الذكي لناديك يعود غداً.') }}</p>
          <div v-if="m.related?.length && i === bot.messages.length - 1" class="bot-qs">
            <button v-for="q in m.related" :key="q.question" type="button" class="bot-q" @click="send(q.question, q.topic)">{{ q.question }}</button>
          </div>
        </template>
        <div v-if="bot.thinking" class="bot-msg bot" role="status"><span class="bot-dots" :aria-label="$t('يكتب...')"><i /><i /><i /></span></div>
        <!-- The page's quick questions until the first answer; after it, each answer brings its own. -->
        <template v-if="bot.questions.length && bot.messages.length === 1 && !bot.thinking">
          <span class="text-xs text-text-muted">{{ $t('أسئلة سريعة') }}</span>
          <div class="bot-qs">
            <button v-for="q in bot.questions" :key="q.question" type="button" class="bot-q" @click="send(q.question, q.topic)">{{ q.question }}</button>
          </div>
        </template>
      </div>

      <form class="bot-ask" @submit.prevent="send()">
        <textarea ref="input" v-model="draft" rows="1" maxlength="500" class="bot-input" dir="auto" :disabled="!!bot.closing" :placeholder="$t('اكتب سؤالك...')" :aria-label="$t('اكتب سؤالك...')" @keydown="key" />
        <button type="submit" class="bot-send" :disabled="!draft.trim() || bot.thinking" :aria-label="$t('أرسل')">↑</button>
      </form>
    </section>
    <BotClosing :page="page" :league-id="leagueId" :label-of="labelOf" :path-for="pathFor" @go="(p) => { router.push(p); if (isPhone()) bot.open = false }" />
  </div>
</template>

<style scoped>
/* Fixed on the left in Arabic and on the right in English (the line's end), above the phone's bottom bar inside a slot. */
.bot-root { position: fixed; z-index: 40; inset-inline-end: 1rem; bottom: max(1rem, env(safe-area-inset-bottom)); }
.bot-root.raised { bottom: calc(5.25rem + env(safe-area-inset-bottom)); }
@media (min-width: 768px) { .bot-root.raised { bottom: 1.25rem; } }
.bot-fab-row { display: flex; align-items: center; gap: 0.5rem; flex-direction: row-reverse; }
.bot-fab {
  position: relative;
  display: grid;
  width: 3.5rem;
  height: 3.5rem;
  flex: none;
  place-items: center;
  border-radius: 999px;
  color: var(--color-on-gold);
  background: radial-gradient(circle at 35% 30%, var(--color-gold-light), var(--color-gold) 55%, var(--color-gold-dark));
  box-shadow: 0 8px 22px color-mix(in srgb, var(--color-shade) 50%, transparent), 0 0 0 3px color-mix(in srgb, var(--color-ring) 35%, transparent);
}
.bot-fab svg { width: 1.9rem; height: 1.9rem; }
.bot-fab.small { width: 2.75rem; height: 2.75rem; box-shadow: none; }
.bot-fab.small svg { width: 1.5rem; height: 1.5rem; }
.bot-on { position: absolute; top: 0.15rem; inset-inline-end: 0.15rem; width: 0.8rem; height: 0.8rem; border-radius: 999px; background: var(--color-ring); border: 2px solid var(--color-bg); }
.bot-hello {
  position: relative;
  max-width: 15rem;
  padding: 0.5rem 0.75rem;
  border-radius: 0.9rem;
  border-inline-end: 4px solid var(--color-gold);
  color: var(--color-on-chrome);
  background: var(--color-chrome);
  box-shadow: 0 8px 22px color-mix(in srgb, var(--color-shade) 45%, transparent);
}
.bot-hello-x { position: absolute; top: -0.6rem; inset-inline-start: -0.6rem; display: grid; width: 1.6rem; height: 1.6rem; place-items: center; border-radius: 999px; font-size: 0.7rem; color: var(--color-text); background: var(--color-surface-raised); }
/* The window: the whole phone, a side panel on the computer (opposite the side menu). */
.bot-panel {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: grid;
  grid-template-rows: auto 1fr auto;
  background: var(--color-bg);
}
@media (min-width: 768px) {
  .bot-panel { inset-inline-start: auto; width: 23rem; border-inline-start: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent); box-shadow: -20px 0 50px color-mix(in srgb, var(--color-shade) 50%, transparent); }
}
.bot-head { display: flex; align-items: center; gap: 0.6rem; padding: 0.6rem 0.75rem; padding-top: max(0.6rem, env(safe-area-inset-top)); background: linear-gradient(180deg, color-mix(in srgb, var(--color-brand) 18%, var(--color-panel)), var(--color-panel)); border-bottom: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent); }
.bot-end { min-height: 2.75rem; padding: 0 0.85rem; border-radius: 0.75rem; font-weight: 800; font-size: 0.8rem; color: var(--color-gold); border: 1px solid color-mix(in srgb, var(--color-gold) 45%, transparent); }
.bot-resume { display: flex; flex-direction: column; gap: 0.4rem; padding: 0.75rem; border-radius: 0.9rem; background: color-mix(in srgb, var(--color-gold) 10%, var(--color-surface)); border: 1px solid color-mix(in srgb, var(--color-gold) 35%, transparent); animation: fade-up var(--duration-base) var(--ease-soft); }
.bot-close { display: grid; width: 2.75rem; height: 2.75rem; flex: none; place-items: center; border-radius: 0.75rem; background: var(--color-surface-raised); }
.bot-body { display: flex; flex-direction: column; gap: 0.6rem; overflow-y: auto; padding: 0.75rem; overscroll-behavior: contain; }
.bot-msg { max-width: 88%; padding: 0.5rem 0.7rem; border-radius: 0.9rem; font-size: 0.875rem; line-height: 1.75; overflow-wrap: anywhere; }
.bot-msg.bot { align-self: flex-start; background: var(--color-surface); border: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent); border-start-start-radius: 0.25rem; }
.bot-msg.me { align-self: flex-end; color: #fff; background: var(--color-brand); border-start-end-radius: 0.25rem; }
.bot-go { display: flex; align-items: center; margin-top: 0.4rem; min-height: 2.75rem; padding: 0 0.75rem; border-radius: 0.6rem; font-weight: 800; font-size: 0.8rem; color: var(--color-on-gold); background: var(--color-gold); }
.bot-qs { display: flex; flex-wrap: wrap; gap: 0.4rem; }
.bot-q { min-height: 2.75rem; padding: 0.35rem 0.8rem; border-radius: 999px; font-size: 0.8rem; font-weight: 700; text-align: start; color: var(--color-ring); background: color-mix(in srgb, var(--color-brand) 18%, transparent); border: 1px solid color-mix(in srgb, var(--color-ring) 30%, transparent); }
.bot-ask { position: relative; display: flex; padding: 0.6rem 0.75rem; padding-bottom: max(0.75rem, env(safe-area-inset-bottom)); border-top: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent); background: var(--color-panel); }
.bot-input { flex: 1; min-height: 2.75rem; max-height: 8rem; resize: none; padding: 0.6rem 0.75rem; padding-inline-end: 3.25rem; border-radius: 0.75rem; font: inherit; color: var(--color-text); background: var(--color-surface-sunk); }
/* [X61] The send button inside the field, at its end, so it never covers what is typed. */
.bot-send { position: absolute; bottom: max(0.75rem, env(safe-area-inset-bottom)); inset-inline-end: 0.75rem; width: 2.75rem; height: 2.75rem; border-radius: 0.75rem; transition: transform var(--duration-fast) var(--ease-soft); font-weight: 800; color: var(--color-on-gold); background: var(--color-gold); }
.bot-send:disabled { opacity: 0.5; }
.bot-eyes { transform-origin: 16px 13.5px; animation: bot-blink 4.5s infinite; }
.bot-pupils { animation: bot-look 6s var(--ease-soft) infinite; }
@keyframes bot-blink { 0%, 92%, 100% { transform: scaleY(1); } 95% { transform: scaleY(0.1); } }
@keyframes bot-look { 0%, 30% { transform: none; } 40%, 55% { transform: translateX(-1.4px); } 65%, 80% { transform: translateX(1.4px); } 90%, 100% { transform: none; } }
.bot-dots { display: inline-flex; gap: 0.25rem; }
.bot-dots i { width: 0.4rem; height: 0.4rem; border-radius: 999px; background: var(--color-text-muted); opacity: 0.6; animation: bot-dot 1.2s var(--ease-soft) infinite; }
/* [X61] The three dots bounce one after the other while he writes; a message rises in. */
.bot-dots i:nth-child(2) { animation-delay: 0.15s; }
.bot-dots i:nth-child(3) { animation-delay: 0.3s; }
@keyframes bot-dot { 0%, 60%, 100% { transform: none; opacity: 0.6; } 30% { transform: translateY(-0.25rem); opacity: 1; } }
.bot-msg { animation: fade-up var(--duration-base) var(--ease-soft); }
</style>
