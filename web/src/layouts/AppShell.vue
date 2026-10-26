<script setup lang="ts">
// The frame around every game screen (Sprint 9 W1, X29, X32, and rebuilt by updates1 UP7 after the spec, 2026-10-26):
// - A header with the club (crest, name, league and place) on one side and the coach on the other, the mark between.
// - Inside a slot a hamburger opens the side menu with every section; and four portals (the team, the club and its
//   money, the competitions, the media) each open their own short list: under the header on the computer, from the
//   bottom bar on the phone.
// - Outside a slot (the home screen, my leagues, the account, the inbox) no sections, only the header.
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import Icon from '../components/Icon.vue'
import { useAuth } from '../stores/auth'
import { useInbox } from '../stores/inbox'
import { useSlot } from '../stores/slot'
import { useWallet } from '../stores/wallet'
import { useBroadcast } from '../stores/broadcast'
import { GROUPS, SECTIONS, type Group, type Section } from './nav'

const route = useRoute()
const broadcast = useBroadcast()
const auth = useAuth()
const initial = computed(() => auth.user?.name.trim().charAt(0) ?? '')
// The side menu, and the portal whose list is open.
const drawer = ref(false)
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
const pathOf = (s: Section) => {
  const league = slot.current?.league?.id
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
watch(() => route.fullPath, () => { drawer.value = false; portal.value = null })
</script>

<template>
  <div class="min-h-dvh">
    <header class="sticky top-0 z-30">
      <!-- Row one: the club's tab, the mark, the coach's tab. -->
      <div class="shell-top relative border-b border-black/30">
        <div class="mx-auto flex max-w-7xl items-center gap-2 px-3 py-2 md:gap-4 md:px-6 md:py-0">
          <button v-if="inSlot" type="button" class="flex size-touch shrink-0 items-center justify-center rounded-full bg-white/10 hover:bg-white/20" :aria-label="$t('القائمة')" :aria-expanded="drawer" aria-controls="side-menu" @click="drawer = true">
            <Icon name="menu" />
          </button>

          <!-- The club's tab (inside a slot), the brand's tab outside. -->
          <RouterLink v-if="inSlot && slot.current?.club" :to="pathOf(clubSections[0])" class="chrome-tab chrome-start min-w-0 flex-1 md:w-80 md:flex-none" :aria-label="$t('نادي {name}', { name: slot.current.club.name })">
            <img :src="slot.current.club.crest_url" alt="" class="size-9 shrink-0 drop-shadow md:size-11" />
            <span class="min-w-0 flex-1 leading-tight">
              <b class="block truncate font-display text-base md:text-lg">{{ $nm(slot.current.club.name) }}</b>
              <span class="flex items-center gap-1.5 truncate text-xs font-semibold opacity-75">
                <span class="truncate">{{ $nm(slot.current.league?.name) }}</span>
                <span v-if="slot.current.position" class="shrink-0 rounded bg-brand px-1.5 font-numbers text-white" dir="ltr">{{ slot.current.position }}/{{ slot.current.teams }}</span>
              </span>
            </span>
          </RouterLink>
          <RouterLink v-else to="/" :aria-label="$t('الرئيسية')" class="shrink-0 md:py-2"><BrandMark size="sm" /></RouterLink>

          <div v-if="inSlot" class="hidden flex-1 justify-center md:flex">
            <RouterLink to="/" :aria-label="$t('الرئيسية')" class="py-2"><BrandMark size="sm" /></RouterLink>
          </div>
          <div v-if="!inSlot" class="flex-1" />

          <template v-if="auth.user">
            <div class="flex shrink-0 items-center gap-1.5 md:gap-2">
              <RouterLink v-if="auth.user.role === 'admin'" to="/admin" class="hidden h-9 items-center rounded-pill bg-white/10 px-3 text-xs font-bold hover:bg-white/20 lg:flex">{{ $t('لوحة الإدارة') }}</RouterLink>
              <RouterLink to="/leagues" class="hidden h-9 items-center gap-1.5 rounded-pill bg-white/10 px-3 text-xs font-bold hover:bg-white/20 lg:flex"><Icon name="leagues" :size="16" />{{ $t('دورياتي') }}</RouterLink>
              <RouterLink to="/wallet" class="pill-coins" :aria-label="$t('المحفظة')">
                <img src="/brand/coin.svg" alt="" class="size-5" /><b class="font-numbers text-base" dir="ltr">{{ wallet.view?.balance ?? 0 }}</b>
              </RouterLink>
              <RouterLink to="/inbox" class="relative flex size-touch items-center justify-center rounded-full bg-white/10 hover:bg-white/20" :aria-label="unread ? $t('الرسائل: {n} غير مقروءة', { n: inbox.unread }) : $t('الرسائل')">
                <Icon name="inbox" /><span v-if="unread" class="absolute -end-0.5 -top-0.5 min-w-5 rounded-pill bg-live px-1 text-center font-numbers text-xs text-white">{{ unread }}</span>
              </RouterLink>
            </div>
            <!-- The coach's tab. -->
            <RouterLink to="/profile" class="coach-tab chrome-end shrink-0" :aria-label="$t('حسابي')">
              <span class="relative grid size-9 place-items-center overflow-hidden rounded-full bg-brand font-display text-lg font-extrabold text-white ring-2 ring-white md:size-11">
                <img v-if="auth.user.avatar_url" :src="auth.user.avatar_url" alt="" class="size-full object-cover" /><template v-else>{{ initial }}</template>
              </span>
              <span class="hidden leading-tight md:block">
                <b class="block max-w-32 truncate text-sm">{{ auth.user.name }}</b>
                <span v-if="level" class="flex items-center gap-1.5 text-xs font-semibold">
                  <span class="rounded bg-on-chrome px-1.5 font-numbers text-chrome">{{ level.level }}</span>
                  <span class="h-1.5 w-14 overflow-hidden rounded-full bg-chrome-dark" aria-hidden="true"><span class="block h-full bg-brand" :style="{ width: `${level.progress_bp / 100}%` }" /></span>
                </span>
              </span>
            </RouterLink>
          </template>
          <template v-else-if="auth.loaded">
            <RouterLink to="/login" class="flex h-touch items-center rounded-lg bg-gold px-4 font-bold text-on-gold">{{ $t('دخول') }}</RouterLink>
            <RouterLink to="/register" class="hidden h-touch items-center rounded-lg border border-white/25 px-4 font-bold sm:flex">{{ $t('إنشاء حساب') }}</RouterLink>
          </template>
        </div>
      </div>

      <!-- Row two, inside a slot on the computer: the four portals, each opening its list under it [UP7]. -->
      <nav v-if="inSlot" class="shell-nav relative hidden md:block" :aria-label="$t('أقسام النادي')">
        <div class="mx-auto flex max-w-7xl items-stretch gap-1 px-3 md:px-6">
          <button
            v-for="g in groups"
            :key="g.key"
            type="button"
            class="nav-item"
            :class="groupActive(g.key) || portal === g.key ? 'is-active' : ''"
            :aria-expanded="portal === g.key"
            aria-controls="portal-list"
            @click="togglePortal(g.key)"
          >
            <Icon :name="g.icon" /><span>{{ $t(g.label) }}</span>
          </button>
          <div class="flex-1" />
          <RouterLink v-if="slot.current?.next_match" to="/match" class="my-2 hidden shrink-0 items-center gap-2 self-center rounded-pill px-3 py-1.5 text-xs font-bold lg:flex" :class="slot.current.next_match.live ? 'bg-live text-white' : 'bg-black/25 text-white'">
            <span v-if="slot.current.next_match.live" class="size-2 animate-pulse rounded-full bg-white" />{{ $t(slot.current.next_match.live ? $t('مباشر الآن') : $t('القادمة')) }}: {{ $nm(slot.current.next_match.opponent) }}
          </RouterLink>
        </div>
      </nav>

    <!-- A portal's list: a sheet over the bottom bar on the phone, a panel under the portals on the computer (inside
       the header, so it hangs from it). -->
    <div v-if="inSlot && openGroup" class="fixed inset-0 z-20 bg-black/50 md:bg-transparent" @click="portal = null" />
    <section v-if="inSlot && openGroup" id="portal-list" class="portal-list" :aria-label="$t(openGroup.label)">
      <h2 class="mb-2 flex items-center gap-2 font-display text-base font-extrabold"><Icon :name="openGroup.icon" :size="18" />{{ $t(openGroup.label) }}</h2>
      <div class="grid grid-cols-3 gap-2 md:grid-cols-4">
        <RouterLink
          v-for="s in openGroup.items"
          :key="s.name"
          :to="pathOf(s)"
          class="portal-item"
          :class="route.path === pathOf(s) ? 'is-active' : ''"
          :aria-current="route.path === pathOf(s) ? 'page' : undefined"
        >
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
      <button type="button" class="flex size-touch shrink-0 items-center justify-center rounded-full bg-white/10" :aria-label="$t('كتم صوت المباراة')" @click="broadcast.muteAsk++">🔇</button>
    </div>
    <RouterLink v-if="auth.user && !auth.user.verification?.verified && route.name !== 'profile'" to="/profile" class="block bg-warning/20 px-4 py-2 text-center text-sm">
      {{ $t('مكافأة {n} كوينز تنتظرك.', { n: auth.user.verification?.welcome_coins ?? 0 }) }} <span class="font-bold text-gold">{{ $t('وثّق حسابك من صفحة حسابي') }}</span>
    </RouterLink>
    <main class="mx-auto w-full max-w-7xl px-3 py-5 md:px-6 md:pb-10" :class="inSlot ? 'pb-28' : 'pb-10'">
      <RouterView />
    </main>

    <!-- Inside a slot on the phone: the four portals and the menu at the bottom [UP7]. -->
    <template v-if="inSlot">
      <nav class="shell-tabs fixed inset-x-0 bottom-0 z-30 grid grid-cols-5 gap-1 px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-1.5 md:hidden" :aria-label="$t('أقسام النادي')">
        <button
          v-for="g in groups"
          :key="g.key"
          type="button"
          class="tab-item"
          :class="groupActive(g.key) || portal === g.key ? 'is-active' : ''"
          :aria-expanded="portal === g.key"
          aria-controls="portal-list"
          @click="togglePortal(g.key)"
        >
          <Icon :name="g.icon" /><span class="leading-tight">{{ $t(g.label) }}</span>
        </button>
        <button type="button" class="tab-item" :aria-expanded="drawer" aria-controls="side-menu" @click="drawer = true">
          <Icon name="menu" />{{ $t('القائمة') }}
        </button>
      </nav>

    </template>

    <!-- The side menu: every section in its portal, and the coach's own pages [UP7]. -->
    <template v-if="drawer">
      <div class="fixed inset-0 z-40 bg-black/60" @click="drawer = false" />
      <aside id="side-menu" class="side-menu" :aria-label="$t('القائمة')" @keydown.esc="drawer = false">
        <div class="flex items-center gap-2 border-b border-white/10 pb-2">
          <BrandMark size="sm" />
          <span class="flex-1" />
          <button type="button" class="flex size-touch items-center justify-center rounded-md hover:bg-white/10" :aria-label="$t('إغلاق القائمة')" @click="drawer = false"><Icon name="close" /></button>
        </div>
        <RouterLink to="/" class="side-item"><Icon name="home" :size="18" />{{ $t('فتحات المدرب') }}</RouterLink>
        <template v-if="inSlot">
          <div v-for="g in groups" :key="g.key" class="flex flex-col">
            <h3 class="px-2 pb-1 pt-3 text-xs font-bold text-text-muted">{{ $t(g.label) }}</h3>
            <RouterLink v-for="s in g.items" :key="s.name" :to="pathOf(s)" class="side-item" :class="route.path === pathOf(s) ? 'is-active' : ''"><Icon :name="s.icon" :size="18" />{{ $t(s.label) }}</RouterLink>
          </div>
        </template>
        <h3 class="px-2 pb-1 pt-3 text-xs font-bold text-text-muted">{{ $t('حسابي') }}</h3>
        <RouterLink to="/leagues" class="side-item"><Icon name="leagues" :size="18" />{{ $t('دورياتي') }}</RouterLink>
        <RouterLink to="/wallet" class="side-item"><img src="/brand/coin.svg" alt="" class="size-[18px]" />{{ $t('المحفظة') }}</RouterLink>
        <RouterLink to="/inbox" class="side-item"><Icon name="inbox" :size="18" />{{ $t('الرسائل') }}</RouterLink>
        <RouterLink to="/profile" class="side-item"><Icon name="team" :size="18" />{{ $t('حسابي') }}</RouterLink>
        <RouterLink to="/developers" class="side-item"><Icon name="sim" :size="18" />{{ $t('المطورون') }}</RouterLink>
        <RouterLink v-if="auth.user?.role === 'admin'" to="/admin" class="side-item"><Icon name="staff" :size="18" />{{ $t('لوحة الإدارة') }}</RouterLink>
      </aside>
    </template>
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
/* The ivory tabs: the club and the coach, cut at an angle toward the middle like a broadcast graphic. */
.chrome-tab {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  min-height: 2.75rem;
  padding: 0.3rem 0.75rem;
  border-radius: 0.6rem;
  color: var(--color-on-chrome);
  background: linear-gradient(180deg, #ffffff 0%, var(--color-chrome) 55%, var(--color-chrome-dark) 100%);
  box-shadow: 0 1px 0 #fff inset, 0 6px 16px -8px rgb(0 0 0 / 0.7);
}
@media (min-width: 768px) {
  .chrome-tab {
    min-height: 3.75rem;
    border-radius: 0 0 0.9rem 0.9rem;
    padding: 0.4rem 1.1rem;
  }
  /* RTL: the start is on the right, so the club's tab leans its left edge in, the coach's its right edge. */
  .chrome-start { clip-path: polygon(0 0, 100% 0, 100% 100%, 1.1rem 100%); padding-inline-end: 1.6rem; }
  .chrome-end { clip-path: polygon(0 0, 100% 0, calc(100% - 1.1rem) 100%, 0 100%); padding-inline-start: 1.6rem; }
}
.chrome-tab:hover { filter: brightness(1.04); }
/* The coach's tab: only the avatar on the phone, where the club's tab needs the width. */
@media (min-width: 768px) {
  .coach-tab {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    min-height: 3.75rem;
    padding: 0.4rem 1.1rem 0.4rem 1.6rem;
    border-radius: 0 0 0.9rem 0.9rem;
    color: var(--color-on-chrome);
    background: linear-gradient(180deg, #ffffff 0%, var(--color-chrome) 55%, var(--color-chrome-dark) 100%);
    box-shadow: 0 1px 0 #fff inset, 0 6px 16px -8px rgb(0 0 0 / 0.7);
  }
}
/* The coins: an orange pill as in every manager game's corner. */
.pill-coins {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  height: 2.25rem;
  padding: 0 0.7rem 0 0.4rem;
  border-radius: 999px;
  color: #2a1300;
  background: linear-gradient(180deg, var(--color-gold-light), var(--color-gold) 60%, var(--color-gold-dark));
  box-shadow: 0 1px 0 rgb(255 255 255 / 0.45) inset, 0 4px 12px -6px rgb(0 0 0 / 0.6);
}
/* Row two: Legends' emerald, each section an icon over its name, the current one lifted in ivory with a gold mark. */
.shell-nav {
  background:
    url("/art/pattern-star.svg") center / 40px 40px repeat,
    linear-gradient(180deg, var(--color-brand) 0%, var(--color-brand-dark) 100%);
  background-blend-mode: soft-light, normal;
  box-shadow: 0 8px 20px -12px rgb(0 0 0 / 0.8);
}
.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.15rem;
  min-width: 4.75rem;
  padding: 0.45rem 0.5rem 0.4rem;
  font-size: 0.72rem;
  font-weight: 700;
  color: rgb(255 255 255 / 0.85);
  white-space: nowrap;
  border-radius: 0.5rem 0.5rem 0 0;
  margin-top: 0.3rem;
}
.nav-item:hover { background: rgb(255 255 255 / 0.12); color: #fff; }
.nav-item { min-width: 7rem; flex-direction: row; gap: 0.45rem; font-size: 0.8rem; }
.nav-item {
  position: relative;
}
.nav-item.is-active {
  color: var(--color-brand-dark);
  background: linear-gradient(180deg, #ffffff, var(--color-chrome));
}
.nav-item.is-active::after {
  content: "";
  position: absolute;
  bottom: 0;
  inset-inline: 30%;
  height: 3px;
  border-radius: 3px 3px 0 0;
  background: var(--color-gold);
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
  box-shadow: 0 12px 28px -14px rgb(0 0 0 / 0.8);
}
@media (min-width: 768px) {
  .portal-list { position: absolute; top: 100%; bottom: auto; inset-inline-start: max(1.5rem, calc((100% - 80rem) / 2 + 1.5rem)); inset-inline-end: auto; width: 32rem; margin: 0.4rem 0 0; }
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
.portal-item:hover { transform: scale(1.03); box-shadow: 0 6px 16px -10px rgb(0 0 0 / 0.7); color: var(--color-text); }
.portal-item.is-active { color: #fff; background: linear-gradient(180deg, var(--color-brand-light), var(--color-brand)); }
/* [UP7] The side menu slides in from the start (the right in Arabic). */
.side-menu {
  position: fixed;
  inset-block: 0;
  inset-inline-start: 0;
  z-index: 45;
  display: flex;
  width: min(18rem, 85vw);
  flex-direction: column;
  gap: 0.1rem;
  overflow-y: auto;
  padding: 0.75rem;
  background: linear-gradient(180deg, var(--color-panel), var(--color-bg-deep));
  border-inline-end: 1px solid color-mix(in srgb, var(--color-brand-light) 30%, transparent);
  animation: side-in 0.18s ease-out;
}
@keyframes side-in { from { transform: translateX(var(--side-from, 100%)); } to { transform: none; } }
:global([dir="ltr"]) .side-menu { --side-from: -100%; }
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
.side-item:hover { background: rgb(255 255 255 / 0.07); color: var(--color-text); }
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
