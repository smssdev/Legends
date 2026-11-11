<script setup lang="ts">
// The frame around every game screen. [Sprint 55 W1] Rebuilt on the approved landscape drafts
// (docs/design/legends-ui/landscape/LandscapeShell.html, the owner's sign-off 2026-11-11, option A on the computer):
// - The dock (ShellDock): 72px at the line's start, 200px with the names on the computer. The club at its head (a tap
//   switches clubs), the six sections by their one name (nav.ts DOCK), «المزيد», and the Assistant Coach at its foot.
//   Outside a club: the home screen, my leagues, a new league, the tournaments and the messages.
// - The bar (ShellBar), 42px: the screen's name, the next match's countdown, the coins and the club's money, the
//   messages and the account (a dot when it is not verified).
// - The screen in what is left, scrolling inside itself (the frame never moves), the footer at its end.
// - Held upright on a phone (the coach chose «تابع عمودياً», TurnPhone): the same dock along the bottom.
// Signed out (the landing, the sign-in) only a slim bar with the brand and the two doors.
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import BrandMark from '../components/BrandMark.vue'
import ShellBar from '../components/shell/ShellBar.vue'
import ShellDock, { type DockEntry } from '../components/shell/ShellDock.vue'
import type { MoreGroup } from '../components/shell/ShellMore.vue'
import ToastHost from '../components/shell/ToastHost.vue'
import UiButton from '../components/ui/UiButton.vue'
import AfterRound from '../components/shell/AfterRound.vue'
import ManagerBot from '../components/assistant/ManagerBot.vue'
import PublicFooter from '../components/PublicFooter.vue'
import SoundPrompt from '../components/shell/SoundPrompt.vue'
import { playTone } from '../lib/tone'
import { t } from '../lib/i18n'
import { useToast } from '../stores/toast'
import { money } from '../lib/format'
import { useAuth } from '../stores/auth'
import { useBoard } from '../stores/board'
import { useBot } from '../stores/bot'
import { useInbox } from '../stores/inbox'
import { useSlot } from '../stores/slot'
import { useWallet } from '../stores/wallet'
import { useBroadcast } from '../stores/broadcast'
import { DOCK, DOCK_OUTSIDE, MORE_ALWAYS, MORE_IN_SLOT, SECTIONS, type Section } from './nav'

const route = useRoute()
const broadcast = useBroadcast()
const auth = useAuth()
const initial = computed(() => auth.user?.name.trim().charAt(0) ?? '')
// The unread messages on the inbox's entry [Sprint 22].
const inbox = useInbox()
watch(() => auth.user?.id ?? null, (id) => inbox.follow(id), { immediate: true })
// The coins balance on the shell [Sprint 34].
const wallet = useWallet()
watch(() => auth.user?.id ?? null, (id) => id && wallet.load(), { immediate: true })
// The slot the coach is in: its club heads the dock.
const slot = useSlot()
// Fetched again on a new account and on the home screen (a club claimed or left since), else only re-picked.
watch(() => [auth.user?.id ?? 0, route.fullPath] as const, ([id], before) => id && slot.load(id, !before || before[0] !== id || route.name === 'home'), { immediate: true })

// "الدوري والكأس" is the slot's own league page, and the media live under the league.
// Before the slots come, the league remembered on this device stands in [Sprint 21 E3.3].
const remembered = (() => { try { return Number(localStorage.getItem('legends.league')) || null } catch { return null } })()
const pathOf = (s: Section) => {
  const league = slot.current?.league?.id ?? (slot.slots.length ? null : remembered)
  if (s.name === 'league' && league) return `/leagues/${league}`
  if (s.inLeague) return league ? `/leagues/${league}${s.path}` : '/leagues'
  return s.path
}
const clubSections = computed(() => SECTIONS.filter((s) => s.club && (!s.dev || auth.user?.role === 'admin')))
const byName = (n: string) => clubSections.value.find((s) => s.name === n)
// '/league' must not light up on '/leagues': a section owns its path and what is under it.
const active = (path: string) => (path === '/' ? route.path === '/' : route.path === path || route.path.startsWith(path + '/'))
const inSlot = computed(() => clubSections.value.some((s) => active(pathOf(s))))
const unread = computed(() => (inbox.unread > 99 ? '99+' : inbox.unread ? String(inbox.unread) : ''))
// [Sprint 20 B1] The board of the slot: the money, the timers and the to-do list.
const board = useBoard()
watch(() => [inSlot.value, slot.current?.league?.id ?? null, route.fullPath] as const, ([inside, league]) => inside && board.load(league ?? null), { immediate: true })

// [Sprint 55 W1, D2] The dock's sections: in a club the six (each lit when one of its pages is open), outside the five.
const entries = computed<DockEntry[]>(() => {
  if (!inSlot.value) return DOCK_OUTSIDE.map((d) => ({ key: d.path, label: d.label, icon: d.icon, active: route.path === d.path, links: [{ to: d.path, label: d.label, icon: d.icon, active: route.path === d.path }], badge: d.path === '/inbox' ? unread.value : null }))
  return DOCK.map((d) => {
    const links = d.items.map(byName).filter((s): s is Section => !!s).map((s) => ({ to: pathOf(s), label: s.label, icon: s.icon, active: active(pathOf(s)) }))
    return { key: d.key, label: d.label, icon: d.icon, links, active: links.some((l) => l.active), badge: d.key === 'office' && board.board?.pending.length ? board.board.pending.length : d.key === 'match' && board.board?.match?.status === 'live' ? '●' : null }
  })
})
const more = computed<MoreGroup[]>(() => {
  const groups: MoreGroup[] = []
  if (inSlot.value) groups.push({ label: 'الدوري', links: MORE_IN_SLOT.map(byName).filter((s): s is Section => !!s).map((s) => ({ to: pathOf(s), label: s.label, icon: s.icon, active: active(pathOf(s)) })) })
  groups.push({ label: 'المجتمع', links: MORE_ALWAYS.map((l) => ({ to: l.path, label: l.label, icon: l.icon, active: route.path === l.path })) })
  const admin = auth.user?.role === 'admin'
  if (admin) groups.push({ label: 'إدارة اللعبة', links: [{ to: '/admin', label: 'لوحة الإدارة', icon: 'staff' }, ...SECTIONS.filter((s) => s.dev).map((s) => ({ to: s.path, label: s.label, icon: s.icon }))] })
  return groups
})
// The screen's name on the bar: its section's page, else the dock's or «المزيد»'s link that is open.
const title = computed(() => {
  const s = SECTIONS.find((x) => (x.club || x.path !== '/') && active(pathOf(x)) && (x.path !== '/leagues' || route.path === '/leagues'))
  if (s) return s.label
  return [...DOCK_OUTSIDE, ...MORE_ALWAYS].find((l) => route.path === l.path)?.label ?? ''
})

// The screen scrolls inside the frame: back to its top on a new page.
const main = ref<HTMLElement | null>(null)
watch(() => route.path, () => main.value?.scrollTo({ top: 0 }))

// [X85] The screens where the club's money matters (spent or earned there): the money shows on the bar only on them.
const MONEY_PAGES = new Set(['club', 'team', 'market', 'training', 'specialists', 'stadium', 'finance', 'scout', 'friendlies'])
const cash = computed(() => (inSlot.value && MONEY_PAGES.has(String(route.name)) && board.board
  ? { value: board.board.money.cash, title: t('أموال {v0}', { v0: board.board.club.name }), label: t('أموال {v0}: {v1}', { v0: board.board.club.name, v1: money(board.board.money.cash) }) }
  : null))
const next = computed(() => {
  const m = board.board?.match
  if (!inSlot.value || !m) return null
  return { at: m.scheduled_at, live: m.status === 'live', opponent: m.opponent?.name ?? '' }
})

// [Sprint 55 W2] The Assistant Coach answers from the dock; the dock's own dot greets once a day until it is opened.
const bot = useBot()
const HELLO = 'glm.bot.hello'
const today = new Date().toDateString()
const hello = ref((() => { try { return localStorage.getItem(HELLO) !== today } catch { return false } })())
watch(() => bot.open, (o) => { if (o) hello.value = false })

// [Sprint 39 N1] The tone when the coach's next match kicks off while the game is open (its end comes as the match
// report's message, stores/inbox.ts). Only within the next hours; a new board moves the timer.
const toast = useToast()
let kickoff = 0
watch(() => board.board?.match && board.board.match.status !== 'live' ? board.board.match.scheduled_at : null, (at) => {
  window.clearTimeout(kickoff)
  const wait = at ? new Date(at).getTime() - Date.now() : -1
  if (wait > 0 && wait < 6 * 3600_000) {
    kickoff = window.setTimeout(() => { playTone(); toast.show(t('بدأت مباراتك الآن')) }, wait)
  }
}, { immediate: true })
onBeforeUnmount(() => window.clearTimeout(kickoff))
</script>

<template>
  <!-- The coach's frame. -->
  <div v-if="auth.user" class="shell" :class="route.meta.wide ? 'is-wide' : ''">
    <ToastHost />
    <!-- [Sprint 39 N1] Asked once a device: the game's sound and notifications. -->
    <SoundPrompt />
    <ShellDock :entries="entries" :more="more" :in-slot="inSlot" :bot-open="bot.open" :bot-dot="hello && !bot.open" @bot="bot.open = !bot.open" />
    <ShellBar :title="title" :in-slot="inSlot" :next="next" :coins="wallet.view?.balance ?? 0" :cash="cash" :unread="unread" :avatar="auth.user.avatar_url" :initial="initial" :unverified="!auth.user.verification?.verified" />

    <main ref="main" class="shell-main">
      <!-- [X41] The match plays on behind this screen: its score and minute, back to it, or mute it. -->
      <div v-if="broadcast.away && broadcast.path" class="on-air flex items-center gap-2 px-3 py-1.5" role="status">
        <RouterLink :to="broadcast.path" class="flex min-h-touch min-w-0 flex-1 items-center gap-2 font-bold" :aria-label="$t('العودة إلى المباراة')">
          <span class="flex shrink-0 items-center gap-1.5 rounded-pill bg-live px-2 py-0.5 text-xs text-white"><span class="size-1.5 animate-pulse rounded-full bg-white" />{{ broadcast.live ? $t('على الهواء') : $t('انتهت') }}</span>
          <span class="min-w-0 truncate text-sm">{{ $t(broadcast.title) }}</span>
          <b class="shrink-0 font-numbers text-lg" dir="ltr">{{ broadcast.score }}</b>
          <span class="shrink-0 font-numbers text-xs text-text-soft" dir="ltr">{{ broadcast.minute }}</span>
        </RouterLink>
        <button type="button" class="flex size-touch shrink-0 items-center justify-center rounded-full bg-text/10" :aria-label="$t('كتم صوت المباراة')" @click="broadcast.muteAsk++">🔇</button>
        <!-- [X74] Close the broadcast: the match page behind is let go, its sound and commentary with it. -->
        <button type="button" class="flex size-touch shrink-0 items-center justify-center rounded-full bg-text/10" :aria-label="$t('أغلق البث')" :title="$t('أغلق البث')" @click="broadcast.close()">✕</button>
      </div>
      <!-- [Sprint 21 E7.3] A suspended account: why, and the way to ask the developers. -->
      <RouterLink v-if="auth.user.suspended" to="/support" class="flex min-h-touch items-center justify-center bg-live/25 px-4 py-2 text-center text-sm font-bold" role="alert">
        {{ $t('حسابك معلّق من فريق التطوير') }}<template v-if="auth.user.suspended.reason">: {{ auth.user.suspended.reason }}</template>. <span class="text-gold">{{ $t('راسل الفريق') }}</span>
      </RouterLink>
      <!-- [Sprint 56] A screen built to fit (route meta `fit`) fills what is left of the frame and scrolls inside its own
           lists; the older screens scroll inside the frame with the footer at their end. -->
      <div class="shell-page mx-auto w-full max-w-7xl" :class="[route.meta.wide ? 'xl:max-w-[96rem]' : '', route.meta.fit ? 'is-fit' : '']">
        <RouterView v-slot="{ Component, route: r }">
          <Transition name="page">
            <component :is="Component" :key="r.path" />
          </Transition>
        </RouterView>
      </div>
      <!-- [X90] The game's footer, at the end of every screen that scrolls. -->
      <PublicFooter v-if="!route.meta.fit" />
    </main>

    <!-- [W7] The matches missed since the last visit: one window, once. -->
    <AfterRound v-if="inSlot && board.board?.missed && board.league" :league-id="board.league" />
    <!-- [Sprint 22, Sprint 55 W2] The Assistant Coach, opened from the dock, its window beside it. -->
    <ManagerBot docked />
  </div>

  <!-- Signed out: the brand, the two doors, the page and the footer. -->
  <div v-else class="min-h-dvh overflow-x-clip">
    <ToastHost />
    <header class="public-bar sticky top-0 z-30 border-b border-text/10">
      <div class="mx-auto flex max-w-7xl items-center gap-2 px-3 py-1.5 md:px-6">
        <RouterLink to="/" :aria-label="$t('الرئيسية')" class="flex min-h-touch shrink-0 items-center"><BrandMark size="sm" /></RouterLink>
        <span class="flex-1" />
        <template v-if="auth.loaded">
          <UiButton to="/login" size="sm">{{ $t('دخول') }}</UiButton>
          <UiButton to="/register" size="sm" variant="outline" class="max-sm:hidden">{{ $t('إنشاء حساب') }}</UiButton>
        </template>
      </div>
    </header>
    <main class="mx-auto w-full max-w-7xl px-3 py-5 pb-10 md:px-6" :class="route.meta.wide ? 'xl:max-w-[96rem]' : ''">
      <RouterView v-slot="{ Component, route: r }">
        <Transition name="page">
          <component :is="Component" :key="r.path" />
        </Transition>
      </RouterView>
    </main>
    <PublicFooter />
  </div>
</template>

<style>
/* [Sprint 55 W1] The frame (LandscapeShell.html): a grid of the dock at the line's start, the bar above the screen, and
   the screen scrolling inside itself. Global, because the dock's lists and the bar's windows are carried to the body. */
:root { --bar-h: 42px; }
.shell {
  --dock-w: 72px;
  display: grid;
  grid-template-columns: var(--dock-w) minmax(0, 1fr);
  grid-template-rows: var(--bar-h) minmax(0, 1fr);
  height: 100dvh;
  overflow: hidden;
}
@media (min-width: 1200px) { .shell { --dock-w: 200px; } }

.shell-dock {
  grid-row: 1 / 3;
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-height: 0;
  padding: var(--space-xs);
  overflow-y: auto;
  scrollbar-width: none;
  background: var(--color-bg-deep);
  border-inline-end: 1px solid color-mix(in srgb, var(--color-text) 8%, transparent);
}
.shell-dock::-webkit-scrollbar { display: none; }
.dock-crest { display: flex; flex: none; align-items: center; justify-content: center; gap: var(--space-sm); min-height: var(--spacing-touch); margin-bottom: var(--space-xs); border-radius: var(--radius-lg); }
.dock-crest:hover { background: color-mix(in srgb, var(--color-text) 6%, transparent); }
.dock-wide-only, .dock-brand .brand-words { display: none; }
.dock-item {
  position: relative;
  display: flex;
  flex: none;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1px;
  min-height: var(--spacing-touch);
  border-radius: var(--radius-lg);
  font-size: var(--text-caption);
  font-weight: 700;
  line-height: 1.2;
  color: var(--color-text-soft);
  transition: color var(--duration-fast) var(--ease-soft), background-color var(--duration-fast) var(--ease-soft);
}
.dock-item:hover { color: var(--color-text); background: color-mix(in srgb, var(--color-text) 6%, transparent); }
.dock-item:focus-visible { outline: 2px solid var(--color-ring); outline-offset: -2px; }
.dock-item.is-active { color: var(--color-gold-light); background: color-mix(in srgb, var(--color-gold) 14%, transparent); }
html.light .dock-item.is-active { color: var(--color-text); background: color-mix(in srgb, var(--color-gold) 30%, transparent); }
.dock-item.is-active::before { content: ""; position: absolute; inset-block: 10px; inset-inline-start: calc(-1 * var(--space-xs)); width: 3px; border-radius: 3px; background: var(--color-gold); }
.dock-label { max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; padding-inline: 2px; }
.dock-badge { position: absolute; top: 4px; inset-inline-end: 10px; min-width: 16px; height: 16px; padding: 0 4px; border-radius: 99px; font-family: var(--font-numbers); font-size: 11px; line-height: 16px; text-align: center; color: var(--color-broadcast-white); background: var(--color-live); }
.dock-dot { min-width: 10px; width: 10px; height: 10px; padding: 0; background: var(--color-ring); }
.dock-bot { color: var(--color-brand-light); }
/* A phone held sideways is short: six sections, «المزيد» and the assistant (8 × 44px) fit 375px only without the
   crest's margin. */
@media (max-height: 440px) { .shell-dock { gap: 0; padding-block: 2px; } .dock-crest { margin-bottom: 0; } }
/* Under 400px of height the eight don't fit with the club too: the club goes to the bar's start (as the approved
   draft). */
.bar-club { display: none; }
.bar-club .dock-crest { min-height: 2.125rem; margin: 0; padding: 0; }
.bar-club .dock-crest img { width: 1.75rem; height: 1.75rem; }
@media (max-height: 400px) and (orientation: landscape) { .shell-dock > .dock-crest { display: none; } .bar-club { display: flex; } }
/* The computer (option A): the names beside the icons. */
@media (min-width: 1200px) {
  .shell-dock { padding: var(--space-sm); }
  .dock-item { flex-direction: row; justify-content: flex-start; gap: var(--space-md); padding-inline: var(--space-md); font-size: var(--text-body); }
  .dock-item.is-active::before { inset-inline-start: calc(-1 * var(--space-sm)); }
  .dock-badge { position: static; margin-inline-start: auto; }
  .dock-crest { justify-content: flex-start; padding-inline: var(--space-sm); }
  .dock-wide-only { display: block; }
  .dock-brand .brand-words { display: flex; }
}

.shell-bar {
  position: relative;
  z-index: 30;
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  min-width: 0;
  padding-inline: var(--space-md);
  background: color-mix(in srgb, var(--color-bg-deep) 70%, var(--color-bg));
  border-bottom: 1px solid color-mix(in srgb, var(--color-text) 8%, transparent);
}
.shell-title { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: var(--text-body-lg); font-weight: 800; }
.bar-next { display: flex; align-items: center; gap: var(--space-xs); max-width: 14rem; height: 2.125rem; padding: 0 var(--space-md); border-radius: 99px; font-size: var(--text-caption); font-weight: 700; background: color-mix(in srgb, var(--color-text) 8%, transparent); }
.bar-live { padding: 2px 8px; border-radius: 99px; color: var(--color-broadcast-white); background: var(--color-live); }
@media (max-width: 760px) { .bar-wide { display: none !important; } }
/* The money's caption is the bar's title's job (and the pill's label for a screen reader): the value alone here. */
.shell-bar .ui-money-pill .text-caption { display: none !important; }
/* The bar is 42px: its buttons are drawn 34px, and each still answers a 44px touch. */
.shell-bar .bar-icon, .bar-avatar { position: relative; width: 2.125rem; height: 2.125rem; }
.shell-bar .bar-icon::after, .bar-avatar::after, .shell-bar .ui-money-pill::after, .bar-next::after { content: ""; position: absolute; inset: -5px; }
.shell-bar .ui-money-pill, .bar-next { position: relative; min-height: 2.125rem; white-space: nowrap; }
/* A phone upright is narrow: the countdown leaves the bar (the office and the dock's «المباراة» keep it). */
@media (max-width: 480px) { .bar-next { display: none; } .shell-bar { gap: var(--space-xs); padding-inline: var(--space-sm); } }
.bar-avatar { display: grid; flex: none; place-items: center; border-radius: 99px; font-weight: 800; color: var(--color-broadcast-white); background: var(--color-brand); box-shadow: 0 0 0 2px var(--color-gold); }
.bar-avatar-dot { position: absolute; top: -2px; inset-inline-end: -2px; width: 10px; height: 10px; border-radius: 99px; background: var(--color-warning); box-shadow: 0 0 0 2px var(--color-bg-deep); }

.shell-main { position: relative; min-height: 0; overflow-x: clip; overflow-y: auto; overscroll-behavior: contain; --shell-header: 0px; }
.shell-page { padding: var(--space-sm) var(--space-sm) var(--space-xl); }
.shell-page.is-fit { display: flex; flex-direction: column; height: 100%; padding-bottom: var(--space-sm); }
.shell-page.is-fit > * { flex: 1; min-height: 0; }
@media (min-width: 900px) { .shell-page { padding: var(--space-md) var(--space-lg) var(--space-xl); } .shell-page.is-fit { padding-bottom: var(--space-md); } }
@media (min-width: 1200px) { .shell-page { padding: var(--space-lg) var(--space-xl) var(--space-xxl); } .shell-page.is-fit { padding-bottom: var(--space-lg); } }

/* [Sprint 55 W4] Held upright on a phone (the coach chose to follow upright): the same dock, along the bottom. */
@media (orientation: portrait) and (max-width: 820px) {
  .shell { grid-template-columns: minmax(0, 1fr); grid-template-rows: var(--bar-h) minmax(0, 1fr) auto; }
  .shell-dock { grid-row: 3; flex-direction: row; gap: 0; padding: 2px 2px max(2px, env(safe-area-inset-bottom)); overflow-x: auto; overflow-y: hidden; border-inline-end: 0; border-top: 1px solid color-mix(in srgb, var(--color-text) 8%, transparent); }
  .shell-dock > .flex-1 { display: none; }
  .dock-crest { display: none; }
  .dock-item { flex: 1 0 3.5rem; }
  .dock-item.is-active::before { inset: auto 10px -2px; width: auto; height: 3px; }
}

/* [Sprint 51 W1] The bar's round buttons and their counts. */
.bar-icon {
  position: relative;
  display: flex;
  width: 2.75rem;
  height: 2.75rem;
  flex: none;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  background: color-mix(in srgb, var(--color-text) 10%, transparent);
}
.bar-icon:hover { background: color-mix(in srgb, var(--color-text) 20%, transparent); }
.bar-badge {
  position: absolute;
  top: -0.15rem;
  inset-inline-end: -0.15rem;
  min-width: 1.25rem;
  padding: 0 0.25rem;
  border-radius: 999px;
  font-family: var(--font-numbers);
  font-size: var(--text-caption);
  text-align: center;
}
/* [Sprint 54 W4] A section's list beside the dock and «المزيد»: placed by reka-ui and carried to the body. */
.nav-panel {
  z-index: 40;
  display: flex;
  min-width: 14rem;
  flex-direction: column;
  gap: 0.15rem;
  padding: 0.4rem;
  border-radius: 0.9rem;
  background: var(--color-surface);
  border: 1px solid color-mix(in srgb, var(--color-gold) 30%, transparent);
  box-shadow: var(--shadow-overlay);
}
.nav-link {
  display: flex;
  min-height: 2.75rem;
  align-items: center;
  gap: 0.6rem;
  padding: 0 0.7rem;
  border-radius: 0.6rem;
  font-weight: 700;
  color: var(--color-text-soft);
  outline: none;
}
.nav-link:hover, .nav-link[data-highlighted] { background: color-mix(in srgb, var(--color-text) 7%, transparent); color: var(--color-text); }
.nav-link.is-active { color: var(--color-broadcast-white); background: var(--color-brand); }
.on-air {
  background: linear-gradient(90deg, color-mix(in srgb, var(--color-live) 25%, var(--color-panel)), var(--color-panel));
  border-bottom: 1px solid color-mix(in srgb, var(--color-live) 40%, transparent);
}
.public-bar { background: color-mix(in srgb, var(--color-bg-deep) 85%, transparent); backdrop-filter: blur(8px); }
</style>
