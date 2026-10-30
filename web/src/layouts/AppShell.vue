<script setup lang="ts">
// The frame around every game screen (Sprint 9 W1, X29, X32, UP7; rebuilt by Sprint 20 W2 and W6, the owner's approved
// drafts, docs/design/legends-ui/Sprint20Drafts.html):
// - The top bar, one in every screen: inside a slot the club (a tap opens the club switcher), the coins and the
//   club's money, the timers and what waits for the coach (each opening its window), and the messages; the coach's tab.
// - Inside a slot, on the computer, a fixed side menu with every section; on the phone a bottom bar: «النادي» (the
//   club board) first, then the four portals, each opening its short list. One way to each place, no duplicate menu.
// - [Sprint 22] The Assistant Coach's button on every screen, fixed on the left in Arabic and the right in English (above the bottom bar inside a slot).
// - Outside a slot (the home screen, my leagues, the account, the inbox) only the top bar.
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import Icon from '../components/Icon.vue'
import ClubSwitcher from '../components/shell/ClubSwitcher.vue'
import AgendaPanel from '../components/shell/AgendaPanel.vue'
import ToastHost from '../components/shell/ToastHost.vue'
import { Popover, PopoverButton, PopoverPanel } from '@headlessui/vue'
import CountUp from '../components/ui/CountUp.vue'
import AfterRound from '../components/shell/AfterRound.vue'
import ManagerBot from '../components/assistant/ManagerBot.vue'
import { money } from '../lib/format'
import { useAuth } from '../stores/auth'
import { useBoard } from '../stores/board'
import { useInbox } from '../stores/inbox'
import { useSlot } from '../stores/slot'
import { useWallet } from '../stores/wallet'
import { useBroadcast } from '../stores/broadcast'
import { GROUPS, SECTIONS, type Group, type Section } from './nav'

const route = useRoute()
const broadcast = useBroadcast()
const auth = useAuth()
const initial = computed(() => auth.user?.name.trim().charAt(0) ?? '')
// The portal whose list is open (phone), and the top bar's open window.
const portal = ref<Group | null>(null)
// The unread messages on the inbox's entry [Sprint 22].
const inbox = useInbox()
watch(() => auth.user?.id ?? null, (id) => inbox.follow(id), { immediate: true })
// The coins balance on the shell [Sprint 34].
const wallet = useWallet()
watch(() => auth.user?.id ?? null, (id) => id && wallet.load(), { immediate: true })
// The slot the coach is in: its club heads the menu.
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
// '/league' must not light up on '/leagues': a section owns its path and what is under it.
const active = (path: string) => (path === '/' ? route.path === '/' : route.path === path || route.path.startsWith(path + '/'))
const inSlot = computed(() => clubSections.value.some((s) => active(pathOf(s))))
const groups = computed(() => GROUPS.map((g) => ({ ...g, items: clubSections.value.filter((s) => s.group === g.key) })))
const groupActive = (g: Group) => clubSections.value.some((s) => s.group === g && route.path === pathOf(s))
const openGroup = computed(() => groups.value.find((g) => g.key === portal.value) ?? null)
const togglePortal = (g: Group) => (portal.value = portal.value === g ? null : g)
const level = computed(() => slot.coach?.level ?? null)
const unread = computed(() => (inbox.unread > 99 ? '99+' : inbox.unread ? String(inbox.unread) : ''))
// [Sprint 20 B1] The board of the slot: the money, the timers and the to-do list on the top bar.
const board = useBoard()
watch(() => [inSlot.value, slot.current?.league?.id ?? null, route.fullPath] as const, ([inside, league]) => inside && board.load(league ?? null), { immediate: true })
const running = computed(() => board.board?.timers.filter((t) => ['training', 'stadium', 'scout'].includes(t.kind)).length ?? 0)
const waiting = computed(() => (board.board?.pending.length ?? 0) + (inbox.unread ? 1 : 0))
watch(() => route.fullPath, () => { portal.value = null })
</script>

<template>
  <div class="min-h-dvh">
    <ToastHost />
    <header class="sticky top-0 z-30">
      <div class="shell-top relative border-b border-shade/30">
        <div class="relative mx-auto flex max-w-7xl items-center gap-1.5 px-3 py-2 md:gap-3 md:px-6 md:py-0" :class="inSlot ? 'md:max-w-none' : route.meta.wide ? 'xl:max-w-[96rem]' : ''">
          <!-- The club (inside a slot: a tap switches clubs), the brand outside. -->
          <ClubSwitcher v-if="inSlot" />
          <RouterLink v-else to="/" :aria-label="$t('الرئيسية')" class="shrink-0 md:py-2"><BrandMark size="sm" /></RouterLink>
          <div class="flex-1" />

          <template v-if="auth.user">
            <div class="flex shrink-0 items-center gap-1 md:gap-2">
              <RouterLink v-if="auth.user.role === 'admin'" to="/admin" class="hidden h-9 items-center rounded-pill bg-text/10 px-3 text-xs font-bold hover:bg-text/20 xl:flex">{{ $t('لوحة الإدارة') }}</RouterLink>
              <RouterLink v-if="!inSlot" to="/leagues" class="hidden h-9 items-center gap-1.5 rounded-pill bg-text/10 px-3 text-xs font-bold hover:bg-text/20 lg:flex"><Icon name="leagues" :size="16" />{{ $t('دورياتي') }}</RouterLink>
              <RouterLink to="/wallet" class="pill-coins" :aria-label="$t('المحفظة')">
                <img src="/brand/coin.svg" alt="" class="size-5" /><b class="font-numbers text-base" dir="ltr"><CountUp :value="wallet.view?.balance ?? 0" /></b>
              </RouterLink>
              <!-- [W2] The club's money beside the coins, always in sight inside a slot. -->
              <RouterLink v-if="inSlot && board.board" to="/finance" class="pill-money" :aria-label="$t('أموال النادي: {v0}', { v0: money(board.board.money.cash) })">
                <b class="font-numbers text-base" dir="ltr"><CountUp :value="board.board.money.cash" :format="money" /></b>
              </RouterLink>
              <template v-if="inSlot">
                <!-- [X61] Headless UI's Popover: the panel drops from the top bar under its button (Esc and the tap
                     outside close it); not relative itself, so the panel spans the bar on a phone. -->
                <Popover v-for="k in (['timers', 'pending'] as const)" :key="k">
                  <PopoverButton class="bar-icon" :aria-label="k === 'timers' ? $t('المؤقتات') : waiting ? $t('ما ينتظرك: {n}', { n: waiting }) : $t('ما ينتظرك')">
                    <template v-if="k === 'timers'"><Icon name="clock" /><span v-if="running" class="bar-badge bg-gold text-on-gold">{{ running }}</span></template>
                    <template v-else><Icon name="todo" /><span v-if="waiting" class="bar-badge animate-pulse-ring bg-live text-white">{{ waiting }}</span></template>
                  </PopoverButton>
                  <Transition name="drop">
                    <PopoverPanel v-slot="{ close }" class="contents">
                      <AgendaPanel :kind="k" @close="close()" />
                    </PopoverPanel>
                  </Transition>
                </Popover>
              </template>
              <!-- Inside a slot on a narrow phone the messages sit in «ما ينتظرك», so the club keeps its room. -->
              <RouterLink to="/inbox" class="bar-icon" :class="inSlot ? 'max-sm:hidden' : ''" :aria-label="unread ? $t('الرسائل: {n} غير مقروءة', { n: inbox.unread }) : $t('الرسائل')">
                <Icon name="inbox" /><span v-if="unread" class="bar-badge bg-live text-white">{{ unread }}</span>
              </RouterLink>
            </div>
            <!-- The coach's tab. -->
            <RouterLink to="/profile" class="coach-tab chrome-end shrink-0" :class="inSlot ? 'in-slot' : ''" :aria-label="$t('حسابي')">
              <span class="relative grid size-9 place-items-center overflow-hidden rounded-full bg-brand font-display text-lg font-extrabold text-white ring-2 ring-gold/70 md:size-10">
                <img v-if="auth.user.avatar_url" :src="auth.user.avatar_url" alt="" class="size-full object-cover" /><template v-else>{{ initial }}</template>
              </span>
              <span class="hidden leading-tight md:block">
                <b class="block max-w-32 truncate text-sm">{{ auth.user.name }}</b>
                <span v-if="level" class="flex items-center gap-1.5 text-xs font-semibold">
                  <span class="rounded bg-gold px-1.5 font-numbers text-on-gold">{{ level.level }}</span>
                  <span class="h-1.5 w-14 overflow-hidden rounded-full bg-surface-sunk" aria-hidden="true"><span class="block h-full bg-brand" :style="{ width: `${level.progress_bp / 100}%` }" /></span>
                </span>
              </span>
            </RouterLink>
          </template>
          <template v-else-if="auth.loaded">
            <RouterLink to="/login" class="flex h-touch items-center rounded-lg bg-gold px-4 font-bold text-on-gold">{{ $t('دخول') }}</RouterLink>
            <RouterLink to="/register" class="hidden h-touch items-center rounded-lg border border-text/25 px-4 font-bold sm:flex">{{ $t('إنشاء حساب') }}</RouterLink>
          </template>
        </div>
      </div>

      <!-- A portal's list on the phone: a sheet over the bottom bar. -->
      <div v-if="inSlot && openGroup" class="fixed inset-0 z-20 bg-black/50 md:hidden" @click="portal = null" />
      <section v-if="inSlot && openGroup" id="portal-list" class="portal-list md:hidden" :aria-label="$t(openGroup.label)">
        <h2 class="mb-2 flex items-center gap-2 font-display text-base font-extrabold"><Icon :name="openGroup.icon" :size="18" />{{ $t(openGroup.label) }}</h2>
        <div class="grid grid-cols-3 gap-2">
          <RouterLink v-for="s in openGroup.items" :key="s.name" :to="pathOf(s)" class="portal-item" :class="route.path === pathOf(s) ? 'is-active' : ''" :aria-current="route.path === pathOf(s) ? 'page' : undefined">
            <Icon :name="s.icon" />{{ $t(s.label) }}
          </RouterLink>
        </div>
      </section>
    </header>

    <!-- [X41] The match plays on behind this screen: its score and minute, back to it, or mute it. -->
    <div v-if="broadcast.away && broadcast.path" class="on-air flex items-center gap-2 px-3 py-2 md:px-6" role="status">
      <RouterLink :to="broadcast.path" class="flex min-h-touch min-w-0 flex-1 items-center gap-2 font-bold" :aria-label="$t('العودة إلى المباراة')">
        <span class="flex shrink-0 items-center gap-1.5 rounded-pill bg-live px-2 py-0.5 text-xs text-white"><span class="size-1.5 animate-pulse rounded-full bg-white" />{{ $t(broadcast.live ? $t('على الهواء') : $t('انتهت')) }}</span>
        <span class="min-w-0 truncate text-sm">{{ $t(broadcast.title) }}</span>
        <b class="shrink-0 font-numbers text-lg" dir="ltr">{{ broadcast.score }}</b>
        <span class="shrink-0 font-numbers text-xs text-text-soft" dir="ltr">{{ broadcast.minute }}</span>
      </RouterLink>
      <button type="button" class="flex size-touch shrink-0 items-center justify-center rounded-full bg-text/10" :aria-label="$t('كتم صوت المباراة')" @click="broadcast.muteAsk++">🔇</button>
    </div>
    <!-- [Sprint 21 E7.3] A suspended account: why, and the way to ask the developers. -->
    <RouterLink v-if="auth.user?.suspended" to="/support" class="block bg-live/25 px-4 py-2 text-center text-sm font-bold" role="alert">
      {{ $t('حسابك معلّق من فريق التطوير') }}<template v-if="auth.user.suspended.reason">: {{ auth.user.suspended.reason }}</template>. <span class="text-gold">{{ $t('راسل الفريق') }}</span>
    </RouterLink>
    <RouterLink v-else-if="auth.user && !auth.user.verification?.verified && route.name !== 'profile'" to="/profile" class="block bg-warning/20 px-4 py-2 text-center text-sm">
      {{ $t('مكافأة {n} كوينز تنتظرك.', { n: auth.user.verification?.welcome_coins ?? 0 }) }} <span class="font-bold text-gold">{{ $t('وثّق حسابك من صفحة حسابي') }}</span>
    </RouterLink>

    <div :class="inSlot ? 'md:grid md:grid-cols-[15rem_minmax(0,1fr)]' : ''">
      <!-- [W6] Inside a slot on the computer: every section, always in sight. -->
      <nav v-if="inSlot" class="side-nav hidden md:flex" :aria-label="$t('أقسام النادي')">
        <RouterLink v-for="s in clubSections.filter((x) => !x.group)" :key="s.name" :to="pathOf(s)" class="side-item" :class="active(pathOf(s)) ? 'is-active' : ''" :aria-current="active(pathOf(s)) ? 'page' : undefined">
          <Icon :name="s.icon" :size="18" />{{ $t(s.label) }}
        </RouterLink>
        <div v-for="g in groups" :key="g.key" class="flex flex-col">
          <h3 class="px-2 pb-1 pt-3 text-xs font-bold text-text-muted">{{ $t(g.label) }}</h3>
          <RouterLink v-for="s in g.items" :key="s.name" :to="pathOf(s)" class="side-item" :class="route.path === pathOf(s) ? 'is-active' : ''" :aria-current="route.path === pathOf(s) ? 'page' : undefined">
            <Icon :name="s.icon" :size="18" />{{ $t(s.label) }}
          </RouterLink>
        </div>
        <h3 class="px-2 pb-1 pt-3 text-xs font-bold text-text-muted">{{ $t('حسابي') }}</h3>
        <RouterLink to="/" class="side-item"><Icon name="home" :size="18" />{{ $t('فرقي') }}</RouterLink>
        <RouterLink to="/leagues" class="side-item"><Icon name="leagues" :size="18" />{{ $t('دورياتي') }}</RouterLink>
        <RouterLink to="/profile" class="side-item"><Icon name="team" :size="18" />{{ $t('حسابي') }}</RouterLink>
        <RouterLink to="/ideas" class="side-item"><Icon name="idea" :size="18" />{{ $t('اقتراحات التطوير') }}</RouterLink>
      </nav>
      <main class="mx-auto w-full max-w-7xl px-3 py-5 md:px-6 md:pb-10" :class="[inSlot ? 'pb-28' : 'pb-10', route.meta.wide ? 'xl:max-w-[96rem]' : '']">
        <RouterView v-slot="{ Component, route: r }">
          <Transition name="page">
            <component :is="Component" :key="r.path" />
          </Transition>
        </RouterView>
      </main>
    </div>

    <!-- [W6] Inside a slot on the phone: «النادي» first, then the four portals. -->
    <nav v-if="inSlot" class="shell-tabs fixed inset-x-0 bottom-0 z-30 grid grid-cols-5 gap-1 px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-1.5 md:hidden" :aria-label="$t('أقسام النادي')">
      <RouterLink to="/club" class="tab-item" :class="route.path === '/club' && !portal ? 'is-active' : ''" :aria-current="route.path === '/club' ? 'page' : undefined">
        <Icon name="club" /><span class="leading-tight">{{ $t('النادي') }}</span>
      </RouterLink>
      <button v-for="g in groups" :key="g.key" type="button" class="tab-item" :class="groupActive(g.key) || portal === g.key ? 'is-active' : ''" :aria-expanded="portal === g.key" aria-controls="portal-list" @click="togglePortal(g.key)">
        <Icon :name="g.icon" /><span class="leading-tight">{{ $t(g.label) }}</span>
      </button>
    </nav>

    <!-- [W7] The matches missed since the last visit: one window, once. -->
    <AfterRound v-if="inSlot && board.board?.missed && board.league" :league-id="board.league" />

    <!-- [Sprint 22] The Assistant Coach: every explanation of the game, on every screen. -->
    <ManagerBot v-if="auth.user" :raised="inSlot" />
  </div>
</template>

<style scoped>
/* [X32] The header's first row: night ink lit from above with Legends' star lattice faint over it, and under it the
   signature seam, emerald fading into gold. */
.shell-top {
  background:
    url("/art/pattern-star.svg") center / 40px 40px repeat,
    linear-gradient(180deg, color-mix(in srgb, var(--color-brand) 22%, var(--color-panel)) 0%, var(--color-panel) 55%, var(--color-bg-deep) 100%);
  background-blend-mode: soft-light, normal;
}
.shell-top::after {
  content: "";
  position: absolute;
  inset-inline: 0;
  bottom: -1px;
  height: 2px;
  background: linear-gradient(90deg, transparent, var(--color-brand-light) 25%, var(--color-gold) 75%, transparent);
  opacity: 0.85;
}
/* [Sprint 21 E3.4] The club's and the coach's tabs: modern glass cards on the night bar (they were ivory tabs cut at an
   angle), the same look as every card under them. */
:global(.chrome-tab),
.coach-tab {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  min-height: 2.75rem;
  padding: 0.3rem 0.75rem;
  border-radius: 0.9rem;
  color: var(--color-text);
  background: color-mix(in srgb, var(--color-surface-raised) 70%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-text) 8%, transparent);
  box-shadow: 0 6px 18px -10px color-mix(in srgb, var(--color-shade) 80%, transparent);
  transition: background-color 0.15s ease, border-color 0.15s ease;
}
.coach-tab { padding: 0.25rem; border-radius: 999px; }
/* [Sprint 20 W2] Inside a slot the phone's bar keeps its room for the club: the account is on the home screen. */
@media (max-width: 767px) { .coach-tab.in-slot { display: none; } }
@media (min-width: 768px) {
  :global(.chrome-tab) { min-height: 3.25rem; margin-block: 0.5rem; padding: 0.35rem 1rem; }
  .coach-tab { min-height: 3.25rem; margin-block: 0.5rem; padding: 0.3rem 1rem 0.3rem 0.35rem; border-radius: 999px; }
}
:global(.chrome-tab:hover),
.coach-tab:hover { border-color: color-mix(in srgb, var(--color-gold) 45%, transparent); background: color-mix(in srgb, var(--color-surface-raised) 90%, transparent); }
/* The coins: an orange pill as in every manager game's corner. */
.pill-coins {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  height: 2.25rem;
  padding: 0 0.7rem 0 0.4rem;
  border-radius: 999px;
  color: var(--color-on-gold);
  background: linear-gradient(180deg, var(--color-gold-light), var(--color-gold) 60%, var(--color-gold-dark));
  box-shadow: 0 1px 0 rgb(255 255 255 / 0.45) inset, 0 4px 12px -6px color-mix(in srgb, var(--color-shade) 60%, transparent);
}
/* [Sprint 20 W2] The club's money: an emerald pill beside the coins; the timers', to-do and messages' icons. */
.pill-money {
  display: flex;
  align-items: center;
  height: 2.25rem;
  padding: 0 0.7rem;
  border-radius: 999px;
  color: var(--color-success);
  background: color-mix(in srgb, var(--color-success) 18%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-success) 35%, transparent);
}
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
  font-size: 0.75rem;
  text-align: center;
}
@media (max-width: 380px) { .pill-money { display: none } }
/* [Sprint 20 W6] The computer's fixed side menu inside a slot. */
.side-nav {
  position: sticky;
  top: 4.25rem;
  height: calc(100dvh - 4.25rem);
  flex-direction: column;
  gap: 0.1rem;
  overflow-y: auto;
  padding: 1rem 0.75rem;
  background: linear-gradient(180deg, var(--color-panel), var(--color-bg-deep));
  border-inline-end: 1px solid color-mix(in srgb, var(--color-text) 6%, transparent);
}
/* [UP7] A portal's list: a sheet above the phone's bottom bar, a panel under the portals on the computer. */
.portal-list {
  position: fixed;
  inset-inline: 0;
  bottom: 4.6rem;
  z-index: 25;
  margin: 0 0.5rem;
  padding: 0.85rem;
  border-radius: 1rem;
  background: var(--color-surface);
  border: 1px solid color-mix(in srgb, var(--color-brand-light) 30%, transparent);
  box-shadow: 0 12px 28px -14px color-mix(in srgb, var(--color-shade) 80%, transparent);
}
.portal-item {
  display: flex;
  min-height: 4.25rem;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  border-radius: 0.75rem;
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--color-text-soft);
  background: var(--color-surface-sunk);
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}
.portal-item:hover { transform: scale(1.03); box-shadow: 0 6px 16px -10px color-mix(in srgb, var(--color-shade) 70%, transparent); color: var(--color-text); }
.portal-item.is-active { color: #fff; background: linear-gradient(180deg, var(--color-brand-light), var(--color-brand)); }
.side-item {
  display: flex;
  min-height: 2.75rem;
  align-items: center;
  gap: 0.6rem;
  padding: 0 0.6rem;
  border-radius: 0.6rem;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text-soft);
}
.side-item:hover { background: color-mix(in srgb, var(--color-text) 7%, transparent); color: var(--color-text); }
.side-item.is-active { color: #fff; background: var(--color-brand); }
/* [X41] The broadcast's bar: a strip in the emerald of the shell, under the header. */
.on-air {
  background: linear-gradient(90deg, color-mix(in srgb, var(--color-live) 25%, var(--color-panel)), var(--color-panel));
  border-bottom: 1px solid color-mix(in srgb, var(--color-live) 40%, transparent);
}
/* The phone's bottom bar: night ink, the current tab in emerald with a gold mark. */
.shell-tabs {
  background: linear-gradient(180deg, var(--color-panel), var(--color-bg-deep));
  border-top: 1px solid color-mix(in srgb, var(--color-brand-light) 30%, transparent);
}
.tab-item {
  display: flex;
  min-height: 3.5rem;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.2rem;
  border-radius: 0.75rem;
  font-size: 0.72rem;
  font-weight: 700;
  color: var(--color-text-soft);
}
.tab-item.is-active {
  position: relative;
  color: #fff;
  background: linear-gradient(180deg, var(--color-brand-light), var(--color-brand));
  box-shadow: 0 6px 14px -8px var(--color-brand);
}
.tab-item.is-active::before {
  content: "";
  position: absolute;
  top: -0.4rem;
  width: 1.5rem;
  height: 3px;
  border-radius: 3px;
  background: var(--color-gold);
}
</style>
