<script setup lang="ts">
// [Sprint 22 W1, W2] The Assistant Coach (Manager Bot in English), on every screen of the game: the owner's approved
// draft (docs/design/legends-ui/ManagerBotDraft.html). A gold button fixed on the left in Arabic and on the right in
// English (the owner, 2026-10-29), still, never dragged; once a day a greeting beside it. Its window is a chat card above
// the button, never the page's whole height, on the phone and the computer (the owner, 2026-10-30): who he is, the page's
// quick questions, the conversation, and a line to the platform's support. Every explanation of the game lives here, not on the screens.
import { computed, nextTick, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { SECTIONS } from '../../layouts/nav'
import { locale } from '../../lib/i18n'
import { useBot, type BotMessage } from '../../stores/bot'
import { useSlot } from '../../stores/slot'
import { t } from '../../lib/i18n'
import BotClosing from './BotClosing.vue'
import Character from '../characters/Character.vue'

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
// [Sprint 30 G8] The greeting leaves by itself after a few seconds: on a phone it sat over the page's bottom buttons
// («أنشئ الدوري…»), which the end-to-end test found.
if (hello.value) setTimeout(() => { if (hello.value) quiet() }, 8000)

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
const labelOf = (go: string) => SECTIONS.find((x) => x.name === go)?.label ?? ({ wallet: 'المحفظة', profile: 'حسابي', support: 'الدعم', ideas: 'اقتراحات التطوير', store: 'العروض' } as Record<string, string>)[go] ?? go
function goTo(go: string) {
  void router.push(pathFor(go))
  // [X61] A recommendation followed ends the task: on the computer the closing card at once, on the phone (whose
  // window closes on the page) the next time it opens.
  bot.followed = go
  if (window.matchMedia('(max-width: 767px)').matches) bot.open = false
  else bot.closing = 'done'
}
// [X67] The platform's support from inside the bot: the support page, where messages reach the developers.
function support() {
  void router.push({ name: 'support' })
  if (isPhone()) bot.open = false
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
      <!-- [Sprint 26 W5] The owner's decision (2026-10-30): the button is the gold face B3 of the characters, calm, and
           glad on the day's greeting (X62's eyes replaced); still with reduced motion. -->
      <button type="button" class="bot-fab face" :aria-label="$t('افتح المدرب المساعد')" @click="show">
        <Character model="B3" :mood="hello ? 'joy' : 'idle'" class="bot-face" />
        <span class="bot-on" />
      </button>
      <div v-if="hello" class="bot-hello">
        <button type="button" class="bot-hello-x" :aria-label="$t('إغلاق')" @click="quiet">✕</button>
        <button type="button" class="min-h-touch text-start" @click="show">
          <b class="block text-sm">{{ $t('أهلاً كوتش!') }}</b>
          <span class="text-xs">{{ $t('أنا المدرب المساعد، اسألني عن أي شيء') }}</span>
        </button>
      </div>
    </div>

    <!-- W2: the window. -->
    <div v-else class="bot-open">
    <section class="bot-panel" role="dialog" :aria-label="bot.name || $t('المدرب المساعد')" @keydown.esc="bot.open = false">
      <header class="bot-head">
        <!-- [Sprint 26 W5] The robot B1 in the window: thinking while he writes, calm otherwise. -->
        <span class="bot-fab small robot" aria-hidden="true"><Character model="B1" :mood="bot.thinking ? 'think' : 'idle'" class="w-full" /></span>
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
      <!-- [X67] The platform's support, at the card's foot. -->
      <button type="button" class="bot-support" @click="support">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 14v-2a8 8 0 0 1 16 0v2" /><path d="M4 14a2 2 0 0 1 2-2h1v6H6a2 2 0 0 1-2-2zM20 14a2 2 0 0 0-2-2h-1v6h1a2 2 0 0 0 2-2zM18 18a4 4 0 0 1-4 3h-2" /></svg>
        {{ $t('تواصل مع دعم المنصة') }}
      </button>
    </section>
    <!-- The round close button where the face was, as in the owner's picture. -->
    <button type="button" class="bot-x" :aria-label="$t('إغلاق')" @click="bot.open = false">✕</button>
    </div>
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
/* [Sprint 26 W5] The faces: B3 is the gold button itself, B1 sits on the window's dark disc. */
.bot-fab.face { width: 4.25rem; height: 4.25rem; background: none; box-shadow: none; overflow: visible; }
.bot-fab.face .bot-face { width: 4.25rem; filter: drop-shadow(0 6px 12px color-mix(in srgb, var(--color-shade) 45%, transparent)); }
.bot-fab.face .bot-face svg, .bot-fab.small.robot svg { width: 100%; height: auto; }
.bot-fab.small.robot { overflow: hidden; background: var(--color-surface-raised); padding: 0.1rem; }
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
/* [Sprint 54] The small ✕ keeps its look; its target is 44px all the same. */
.bot-hello-x::after { content: ""; position: absolute; inset: -0.6rem; }
.bot-hello-x { position: absolute; top: -0.6rem; inset-inline-start: -0.6rem; display: grid; width: 1.6rem; height: 1.6rem; place-items: center; border-radius: 999px; font-size: var(--text-caption); color: var(--color-text); background: var(--color-surface-raised); }
/* [X67] The window: a chat card above the round close button, never the page's whole height (the owner's picture,
   2026-10-30), the same on the phone and the computer. */
.bot-open { display: flex; flex-direction: column; align-items: flex-end; gap: 0.6rem; }
.bot-panel {
  display: grid;
  grid-template-rows: auto 1fr auto auto;
  width: min(23rem, calc(100vw - 2rem));
  height: min(36rem, calc(100dvh - 7.5rem));
  overflow: hidden;
  border-radius: 1.1rem;
  background: var(--color-bg);
  border: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent);
  box-shadow: 0 18px 50px color-mix(in srgb, var(--color-shade) 55%, transparent);
  animation: fade-up var(--duration-base) var(--ease-soft);
}
.bot-root.raised .bot-panel { height: min(36rem, calc(100dvh - 12rem)); }
.bot-x { display: grid; width: 3.5rem; height: 3.5rem; place-items: center; border-radius: 999px; font-size: 1.1rem; font-weight: 800; color: var(--color-gold); background: var(--color-panel); border: 2px solid color-mix(in srgb, var(--color-gold) 55%, transparent); box-shadow: 0 8px 22px color-mix(in srgb, var(--color-shade) 50%, transparent); }
.bot-support { display: flex; min-height: 2.75rem; align-items: center; justify-content: center; gap: 0.4rem; font-size: 0.8rem; font-weight: 700; color: var(--color-ring); background: var(--color-panel); border-top: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent); }
.bot-support svg { width: 1.1rem; height: 1.1rem; }
.bot-head { display: flex; align-items: center; gap: 0.6rem; padding: 0.6rem 0.75rem; background: linear-gradient(180deg, color-mix(in srgb, var(--color-brand) 18%, var(--color-panel)), var(--color-panel)); border-bottom: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent); }
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
.bot-ask { position: relative; display: flex; padding: 0.6rem 0.75rem; border-top: 1px solid color-mix(in srgb, var(--color-text) 10%, transparent); background: var(--color-panel); }
.bot-input { flex: 1; min-height: 2.75rem; max-height: 8rem; resize: none; padding: 0.6rem 0.75rem; padding-inline-end: 3.25rem; border-radius: 0.75rem; font: inherit; color: var(--color-text); background: var(--color-surface-sunk); }
/* [X61] The send button inside the field, at its end, so it never covers what is typed. */
.bot-send { position: absolute; bottom: 0.6rem; inset-inline-end: 0.75rem; width: 2.75rem; height: 2.75rem; border-radius: 0.75rem; transition: transform var(--duration-fast) var(--ease-soft); font-weight: 800; color: var(--color-on-gold); background: var(--color-gold); }
.bot-send:disabled { opacity: 0.5; }
.bot-dots { display: inline-flex; gap: 0.25rem; }
.bot-dots i { width: 0.4rem; height: 0.4rem; border-radius: 999px; background: var(--color-text-muted); opacity: 0.6; animation: bot-dot 1.2s var(--ease-soft) infinite; }
/* [X61] The three dots bounce one after the other while he writes; a message rises in. */
.bot-dots i:nth-child(2) { animation-delay: 0.15s; }
.bot-dots i:nth-child(3) { animation-delay: 0.3s; }
@keyframes bot-dot { 0%, 60%, 100% { transform: none; opacity: 0.6; } 30% { transform: translateY(-0.25rem); opacity: 1; } }
.bot-msg { animation: fade-up var(--duration-base) var(--ease-soft); }
</style>
