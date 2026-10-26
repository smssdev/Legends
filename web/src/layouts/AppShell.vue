<script setup lang="ts">
// The frame around every game screen (Sprint 9 W1, X29, and redrawn by X32 after the owner's review of OSM, 2026-10-25):
// - On the computer a header of two rows over the blurred stadium: ivory tabs with the club (crest, name, league and
//   place) on one side and the coach (avatar, name, level) on the other, the mark between them; under it, inside a
//   slot, the club's sections in one row of icons, the side bar gone, so the screen has the full width.
// - On the phone a compact bar (back to the slots, the club, coins, messages, account) and, inside a slot, a bottom
//   bar of four sections with "المزيد".
// - Outside a slot (the home screen, my leagues, the account, the inbox) no sections, only the header.
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import Icon from '../components/Icon.vue'
import { useAuth } from '../stores/auth'
import { useInbox } from '../stores/inbox'
import { useSlot } from '../stores/slot'
import { useWallet } from '../stores/wallet'
import { useBroadcast } from '../stores/broadcast'
import { SECTIONS, TABS, type Section } from './nav'

const route = useRoute()
const broadcast = useBroadcast()
const auth = useAuth()
const initial = computed(() => auth.user?.name.trim().charAt(0) ?? '')
const more = ref(false)
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

// "الدوري والكأس" is the slot's own league page.
const pathOf = (s: Section) => (s.name === 'league' && slot.current?.league ? `/leagues/${slot.current.league.id}` : s.path)
const clubSections = computed(() => SECTIONS.filter((s) => s.club && (!s.dev || auth.user?.role === 'admin')))
// '/league' must not light up on '/leagues': a section owns its path and what is under it.
const active = (path: string) => (path === '/' ? route.path === '/' : route.path === path || route.path.startsWith(path + '/'))
const inSlot = computed(() => clubSections.value.some((s) => active(pathOf(s))))
const tabs = computed(() => TABS.map((n) => clubSections.value.find((s) => s.name === n)!))
const rest = computed(() => clubSections.value.filter((s) => !TABS.includes(s.name)))
const moreActive = computed(() => rest.value.some((s) => active(pathOf(s))))
const level = computed(() => slot.coach?.level ?? null)
const unread = computed(() => (inbox.unread > 99 ? '99+' : inbox.unread ? String(inbox.unread) : ''))
watch(() => route.fullPath, () => (more.value = false))
</script>

<template>
  <div class="min-h-dvh">
    <header class="sticky top-0 z-30">
      <!-- Row one: the club's tab, the mark, the coach's tab. -->
      <div class="shell-top relative border-b border-black/30">
        <div class="mx-auto flex max-w-7xl items-center gap-2 px-3 py-2 md:gap-4 md:px-6 md:py-0">
          <RouterLink v-if="inSlot" to="/" class="flex size-touch shrink-0 items-center justify-center rounded-full bg-white/10 md:hidden" aria-label="العودة إلى فتحات المدرب">
            <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6" /></svg>
          </RouterLink>

          <!-- The club's tab (inside a slot), the brand's tab outside. -->
          <RouterLink v-if="inSlot && slot.current?.club" :to="pathOf(clubSections[0])" class="chrome-tab chrome-start min-w-0 flex-1 md:w-80 md:flex-none" :aria-label="`نادي ${slot.current.club.name}`">
            <img :src="slot.current.club.crest_url" alt="" class="size-9 shrink-0 drop-shadow md:size-11" />
            <span class="min-w-0 flex-1 leading-tight">
              <b class="block truncate font-display text-base md:text-lg">{{ $nm(slot.current.club.name) }}</b>
              <span class="flex items-center gap-1.5 truncate text-xs font-semibold opacity-75">
                <span class="truncate">{{ $nm(slot.current.league?.name) }}</span>
                <span v-if="slot.current.position" class="shrink-0 rounded bg-brand px-1.5 font-numbers text-white" dir="ltr">{{ slot.current.position }}/{{ slot.current.teams }}</span>
              </span>
            </span>
          </RouterLink>
          <RouterLink v-else to="/" aria-label="الرئيسية" class="shrink-0 md:py-2"><BrandMark size="sm" /></RouterLink>

          <div v-if="inSlot" class="hidden flex-1 justify-center md:flex">
            <RouterLink to="/" aria-label="الرئيسية" class="py-2"><BrandMark size="sm" /></RouterLink>
          </div>
          <div v-if="!inSlot" class="flex-1" />

          <template v-if="auth.user">
            <div class="flex shrink-0 items-center gap-1.5 md:gap-2">
              <RouterLink v-if="auth.user.role === 'admin'" to="/admin" class="hidden h-9 items-center rounded-pill bg-white/10 px-3 text-xs font-bold hover:bg-white/20 lg:flex">لوحة الإدارة</RouterLink>
              <RouterLink to="/leagues" class="hidden h-9 items-center gap-1.5 rounded-pill bg-white/10 px-3 text-xs font-bold hover:bg-white/20 lg:flex"><Icon name="leagues" :size="16" />دورياتي</RouterLink>
              <RouterLink to="/wallet" class="pill-coins" aria-label="المحفظة">
                <img src="/brand/coin.svg" alt="" class="size-5" /><b class="font-numbers text-base" dir="ltr">{{ wallet.view?.balance ?? 0 }}</b>
              </RouterLink>
              <RouterLink to="/inbox" class="relative flex size-touch items-center justify-center rounded-full bg-white/10 hover:bg-white/20" :aria-label="unread ? `الرسائل: ${inbox.unread} غير مقروءة` : 'الرسائل'">
                <Icon name="inbox" /><span v-if="unread" class="absolute -end-0.5 -top-0.5 min-w-5 rounded-pill bg-live px-1 text-center font-numbers text-xs text-white">{{ unread }}</span>
              </RouterLink>
            </div>
            <!-- The coach's tab. -->
            <RouterLink to="/profile" class="coach-tab chrome-end shrink-0" aria-label="حسابي">
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
            <RouterLink to="/login" class="flex h-touch items-center rounded-lg bg-gold px-4 font-bold text-on-gold">دخول</RouterLink>
            <RouterLink to="/register" class="hidden h-touch items-center rounded-lg border border-white/25 px-4 font-bold sm:flex">إنشاء حساب</RouterLink>
          </template>
        </div>
      </div>

      <!-- Row two, inside a slot on the computer: the club's sections in one row of icons. -->
      <nav v-if="inSlot" class="shell-nav hidden md:block" aria-label="أقسام النادي">
        <div class="mx-auto flex max-w-7xl items-stretch gap-0.5 overflow-x-auto px-3 md:px-6">
          <RouterLink to="/" class="nav-item" aria-label="العودة إلى فتحات المدرب">
            <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6" /></svg><span>الفتحات</span>
          </RouterLink>
          <span class="my-2 w-px shrink-0 bg-white/15" aria-hidden="true" />
          <RouterLink
            v-for="s in clubSections"
            :key="s.name"
            :to="pathOf(s)"
            class="nav-item"
            :class="active(pathOf(s)) ? 'is-active' : ''"
            :aria-current="active(pathOf(s)) ? 'page' : undefined"
          >
            <Icon :name="s.icon" /><span>{{ s.label }}</span>
          </RouterLink>
          <div class="flex-1" />
          <RouterLink v-if="slot.current?.next_match" to="/match" class="my-2 hidden shrink-0 items-center gap-2 self-center rounded-pill px-3 py-1.5 text-xs font-bold lg:flex" :class="slot.current.next_match.live ? 'bg-live text-white' : 'bg-black/25 text-white'">
            <span v-if="slot.current.next_match.live" class="size-2 animate-pulse rounded-full bg-white" />{{ slot.current.next_match.live ? 'مباشر الآن' : 'القادمة' }}: {{ $nm(slot.current.next_match.opponent) }}
          </RouterLink>
        </div>
      </nav>
    </header>

    <!-- [X41] The match plays on behind this screen: its score and minute, back to it, or mute it. -->
    <div v-if="broadcast.away && broadcast.path" class="on-air flex items-center gap-2 px-3 py-2 md:px-6" role="status">
      <RouterLink :to="broadcast.path" class="flex min-h-touch min-w-0 flex-1 items-center gap-2 font-bold" aria-label="العودة إلى المباراة">
        <span class="flex shrink-0 items-center gap-1.5 rounded-pill bg-live px-2 py-0.5 text-xs text-white"><span class="size-1.5 animate-pulse rounded-full bg-white" />{{ broadcast.live ? 'على الهواء' : 'انتهت' }}</span>
        <span class="min-w-0 truncate text-sm">{{ broadcast.title }}</span>
        <b class="shrink-0 font-numbers text-lg" dir="ltr">{{ broadcast.score }}</b>
        <span class="shrink-0 font-numbers text-xs text-text-soft" dir="ltr">{{ broadcast.minute }}</span>
      </RouterLink>
      <button type="button" class="flex size-touch shrink-0 items-center justify-center rounded-full bg-white/10" aria-label="كتم صوت المباراة" @click="broadcast.muteAsk++">🔇</button>
    </div>
    <RouterLink v-if="auth.user && !auth.user.verification?.verified && route.name !== 'profile'" to="/profile" class="block bg-warning/20 px-4 py-2 text-center text-sm">
      مكافأة {{ auth.user.verification?.welcome_coins }} كوينز تنتظرك. <span class="font-bold text-gold">وثّق حسابك من صفحة حسابي</span>
    </RouterLink>
    <main class="mx-auto w-full max-w-7xl px-3 py-5 md:px-6 md:pb-10" :class="inSlot ? 'pb-28' : 'pb-10'">
      <RouterView />
    </main>

    <!-- Inside a slot on the phone: four of the club's sections and the rest under "المزيد". -->
    <template v-if="inSlot">
      <nav class="shell-tabs fixed inset-x-0 bottom-0 z-30 grid grid-cols-5 gap-1 px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-1.5 md:hidden" aria-label="أقسام النادي">
        <RouterLink
          v-for="s in tabs"
          :key="s.name"
          :to="pathOf(s)"
          class="tab-item"
          :class="active(pathOf(s)) ? 'is-active' : ''"
          :aria-current="active(pathOf(s)) ? 'page' : undefined"
        >
          <Icon :name="s.icon" />{{ s.label }}
        </RouterLink>
        <button type="button" class="tab-item" :class="more || moreActive ? 'is-active' : ''" :aria-expanded="more" aria-controls="more-sheet" @click="more = !more">
          <Icon name="more" />المزيد
        </button>
      </nav>

      <div v-if="more" class="fixed inset-0 z-20 bg-black/60 md:hidden" @click="more = false" />
      <section v-if="more" id="more-sheet" class="fixed inset-x-0 bottom-0 z-25 rounded-t-xxl bg-surface p-4 pb-28 shadow-2xl md:hidden" aria-label="باقي أقسام النادي">
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-display text-lg font-extrabold">باقي الأقسام</h2>
          <button type="button" class="flex size-touch items-center justify-center rounded-md" aria-label="إغلاق" @click="more = false"><Icon name="close" /></button>
        </div>
        <div class="grid grid-cols-3 gap-2">
          <RouterLink
            v-for="s in rest"
            :key="s.name"
            :to="pathOf(s)"
            class="flex min-h-20 flex-col items-center justify-center gap-2 rounded-xl text-sm font-semibold"
            :class="active(pathOf(s)) ? 'bg-brand text-white' : 'bg-surface-sunk text-text-soft'"
          >
            <Icon :name="s.icon" />{{ s.label }}
          </RouterLink>
        </div>
      </section>
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
