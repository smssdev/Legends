<script setup lang="ts">
// The frame around every game screen (Sprint 9 W1, reshaped by X29 at the owner's request, 2026-10-25):
// - Outside a slot (the home screen, my leagues, the account, the inbox): no menu, only a slim top bar, so the
//   screen holds what it is for.
// - Inside a slot (a club's sections): the club's own menu, a side bar on the computer and a bottom bar of four
//   sections with "المزيد" on the phone, headed by the club and a way back to the slots.
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import Icon from '../components/Icon.vue'
import { useAuth } from '../stores/auth'
import { useInbox } from '../stores/inbox'
import { useSlot } from '../stores/slot'
import { useWallet } from '../stores/wallet'
import { SECTIONS, TABS, type Section } from './nav'

const route = useRoute()
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
const unread = computed(() => (inbox.unread > 99 ? '99+' : inbox.unread ? String(inbox.unread) : ''))
watch(() => route.fullPath, () => (more.value = false))
</script>

<template>
  <div class="min-h-dvh md:flex">
    <!-- Inside a slot: the club's menu on the computer. -->
    <aside v-if="inSlot" class="sticky top-0 hidden h-dvh w-64 shrink-0 flex-col gap-2 border-s border-text/5 bg-bg-deep/90 p-4 backdrop-blur md:flex" aria-label="أقسام النادي">
      <RouterLink to="/" class="mb-1 flex min-h-touch items-center gap-2 rounded-lg px-2 text-sm font-bold text-text-soft hover:text-gold" aria-label="العودة إلى فتحات المدرب">
        <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6" /></svg>الفتحات
      </RouterLink>
      <nav class="flex flex-1 flex-col gap-0.5 overflow-y-auto">
        <RouterLink
          v-for="s in clubSections"
          :key="s.name"
          :to="pathOf(s)"
          class="group relative flex min-h-touch items-center gap-3 rounded-lg px-2 font-semibold transition-colors"
          :class="active(pathOf(s)) ? 'bg-gold/15 text-gold' : 'text-text-soft hover:bg-surface hover:text-text'"
          :aria-current="active(pathOf(s)) ? 'page' : undefined"
        >
          <span v-if="active(pathOf(s))" class="absolute inset-y-2 start-0 w-1 rounded-pill bg-gold" aria-hidden="true" />
          <span class="grid size-9 place-items-center rounded-lg transition-colors" :class="active(pathOf(s)) ? 'bg-gold text-on-gold shadow-md shadow-gold/30' : 'bg-surface/70 group-hover:bg-surface-raised'"><Icon :name="s.icon" /></span>
          <span class="flex-1">{{ s.label }}</span>
          <span v-if="s.dev" class="rounded-pill bg-gold/15 px-2 text-xs text-gold">للمطور</span>
        </RouterLink>
      </nav>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <!-- The top bar: everywhere, slim. -->
      <header class="sticky top-0 z-20 flex items-center gap-2 border-b border-text/5 bg-bg/80 px-4 py-2.5 backdrop-blur-md md:px-8">
        <RouterLink v-if="inSlot" to="/" class="flex size-touch items-center justify-center rounded-full bg-surface md:hidden" aria-label="العودة إلى فتحات المدرب">
          <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6" /></svg>
        </RouterLink>
        <RouterLink to="/" aria-label="الرئيسية" :class="inSlot ? 'hidden md:block' : ''"><BrandMark size="sm" /></RouterLink>
        <div class="flex-1" />
        <template v-if="auth.user">
          <RouterLink v-if="auth.user.role === 'admin'" to="/admin" class="hidden h-touch items-center rounded-pill px-3 text-sm font-bold text-text-soft hover:bg-surface md:flex">لوحة الإدارة</RouterLink>
          <RouterLink to="/leagues" class="hidden h-touch items-center gap-2 rounded-pill px-3 text-sm font-bold text-text-soft hover:bg-surface sm:flex"><Icon name="leagues" />دورياتي</RouterLink>
          <RouterLink to="/wallet" class="flex h-touch items-center gap-1 rounded-pill bg-surface px-3" aria-label="المحفظة">
            <img src="/brand/coin.svg" alt="" class="size-5" /><b class="font-numbers text-gold" dir="ltr">{{ wallet.view?.balance ?? 0 }}</b>
          </RouterLink>
          <RouterLink to="/inbox" class="relative flex size-touch items-center justify-center rounded-full bg-surface" :aria-label="unread ? `الرسائل: ${inbox.unread} غير مقروءة` : 'الرسائل'">
            <Icon name="inbox" /><span v-if="unread" class="absolute -end-1 -top-1 min-w-5 rounded-pill bg-gold px-1 text-center font-numbers text-xs text-on-gold">{{ unread }}</span>
          </RouterLink>
          <RouterLink to="/profile" class="flex size-touch items-center justify-center overflow-hidden rounded-full bg-gold font-display text-lg font-extrabold text-on-gold ring-2 ring-gold/30" aria-label="حسابي">
            <img v-if="auth.user.avatar_url" :src="auth.user.avatar_url" alt="" class="size-full object-cover" /><template v-else>{{ initial }}</template>
          </RouterLink>
        </template>
        <template v-else-if="auth.loaded">
          <RouterLink to="/login" class="flex h-touch items-center rounded-lg bg-gold px-4 font-bold text-on-gold">دخول</RouterLink>
          <RouterLink to="/register" class="hidden h-touch items-center rounded-lg border border-text/15 px-4 font-bold sm:flex">إنشاء حساب</RouterLink>
        </template>
      </header>
      <RouterLink v-if="auth.user && !auth.user.email_verified && route.name !== 'profile'" to="/profile" class="block bg-warning/15 px-4 py-2 text-center text-sm">
        بريدك غير مؤكد بعد. <span class="font-bold text-gold">أكّده من صفحة حسابي</span>
      </RouterLink>
      <main class="mx-auto w-full flex-1 px-4 py-5 md:px-8 md:pb-8" :class="[inSlot ? 'max-w-6xl pb-28' : 'max-w-7xl pb-10']">
        <!-- [X29] Inside a slot every screen opens under the club's banner: where you are, in whose colours. -->
        <div v-if="inSlot && slot.current?.club" class="relative isolate mb-5 flex items-center gap-3 overflow-hidden rounded-2xl border border-gold/15 px-4 py-3 shadow-lg shadow-black/30 md:px-5">
          <div class="absolute inset-0 -z-10 bg-gradient-to-l from-gold/20 via-surface/90 to-pitch/25" aria-hidden="true" />
          <div class="absolute inset-0 -z-10 bg-[url(/art/pitch-lines.svg)] bg-[length:520px_auto] bg-[position:left_center] bg-no-repeat opacity-[0.12]" aria-hidden="true" />
          <img :src="slot.current.club.crest_url" alt="" class="size-12 shrink-0 drop-shadow-[0_6px_12px_rgba(0,0,0,0.5)]" />
          <div class="min-w-0 flex-1">
            <b class="block truncate font-display text-lg leading-tight md:text-xl">{{ slot.current.club.name }}</b>
            <span class="flex flex-wrap items-center gap-x-2 text-xs text-text-muted">
              <span>{{ slot.current.league?.name }}</span>
              <span v-if="slot.current.position" class="rounded-pill bg-bg/50 px-2 py-0.5 font-bold text-gold">المركز {{ slot.current.position }}/{{ slot.current.teams }}</span>
            </span>
          </div>
          <RouterLink v-if="slot.current.next_match" to="/match" class="hidden shrink-0 items-center gap-2 rounded-pill px-3 py-1.5 text-xs font-bold sm:flex" :class="slot.current.next_match.live ? 'bg-live/20 text-[#FF8A8A]' : 'bg-bg/60 text-text-soft'">
            <span v-if="slot.current.next_match.live" class="size-2 animate-pulse rounded-full bg-live" />{{ slot.current.next_match.live ? 'مباشر الآن' : 'القادمة' }}: {{ slot.current.next_match.opponent }}
          </RouterLink>
        </div>
        <RouterView />
      </main>
    </div>

    <!-- Inside a slot on the phone: four of the club's sections and the rest under "المزيد". -->
    <template v-if="inSlot">
      <nav class="fixed inset-x-0 bottom-0 z-30 grid grid-cols-5 gap-1 border-t border-text/10 bg-bg-deep/90 px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-2 backdrop-blur-md md:hidden" aria-label="أقسام النادي">
        <RouterLink
          v-for="s in tabs"
          :key="s.name"
          :to="pathOf(s)"
          class="flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl text-xs font-semibold transition-colors"
          :class="active(pathOf(s)) ? 'bg-gold/15 text-gold' : 'text-text-soft'"
          :aria-current="active(pathOf(s)) ? 'page' : undefined"
        >
          <Icon :name="s.icon" />{{ s.label }}
        </RouterLink>
        <button
          type="button"
          class="flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl text-xs font-semibold"
          :class="more || moreActive ? 'bg-gold/15 text-gold' : 'text-text-soft'"
          :aria-expanded="more"
          aria-controls="more-sheet"
          @click="more = !more"
        >
          <Icon name="more" />المزيد
        </button>
      </nav>

      <div v-if="more" class="fixed inset-0 z-20 bg-black/50 backdrop-blur-sm md:hidden" @click="more = false" />
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
            :class="active(pathOf(s)) ? 'bg-gold/15 text-gold' : 'bg-surface-sunk text-text-soft'"
          >
            <Icon :name="s.icon" />{{ s.label }}
          </RouterLink>
        </div>
      </section>
    </template>
  </div>
</template>
