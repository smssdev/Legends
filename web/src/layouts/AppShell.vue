<script setup lang="ts">
// The navigation around every game screen (Sprint 9 W1), after the design drafts
// (docs/design/legends-ui: WebHome, MobileHome): a side bar on the computer, and on the
// phone a bottom bar of four sections with "المزيد" for the rest.
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import Icon from '../components/Icon.vue'
import { useAuth } from '../stores/auth'
import { useInbox } from '../stores/inbox'
import { SECTIONS, TABS } from './nav'

const route = useRoute()
const auth = useAuth()
const initial = computed(() => auth.user?.name.trim().charAt(0) ?? '')
const more = ref(false)
// The unread messages on the inbox's entry, and on "المزيد" on the phone where the inbox sits [Sprint 22].
const inbox = useInbox()
watch(() => auth.user?.id ?? null, (id) => inbox.follow(id), { immediate: true })
const badge = (name: string) => (name === 'inbox' && inbox.unread ? (inbox.unread > 99 ? '99+' : String(inbox.unread)) : '')
const sections = computed(() => SECTIONS)
const tabs = computed(() => TABS.map((n) => SECTIONS.find((s) => s.name === n)!))
const rest = computed(() => SECTIONS.filter((s) => !TABS.includes(s.name)))
// '/league' must not light up on '/leagues': a section owns its path and what is under it.
const active = (path: string) => (path === '/' ? route.path === '/' : route.path === path || route.path.startsWith(path + '/'))
const moreActive = computed(() => rest.value.some((s) => active(s.path)))
watch(() => route.fullPath, () => (more.value = false))
</script>

<template>
  <div class="min-h-dvh md:flex">
    <aside class="sticky top-0 hidden h-dvh w-64 shrink-0 flex-col gap-2 border-s border-text/5 bg-bg-deep p-4 md:flex" aria-label="الأقسام">
      <RouterLink to="/" class="mb-4 flex items-center gap-3 px-2">
        <BrandMark />
      </RouterLink>
      <nav class="flex flex-1 flex-col gap-1 overflow-y-auto">
        <RouterLink
          v-for="s in sections"
          :key="s.name"
          :to="s.path"
          class="flex min-h-touch items-center gap-3 rounded-lg px-3 font-semibold"
          :class="active(s.path) ? 'bg-surface-raised text-gold' : 'text-text-soft hover:bg-surface'"
          :aria-current="active(s.path) ? 'page' : undefined"
        >
          <Icon :name="s.icon" />
          <span class="flex-1">{{ s.label }}</span>
          <span v-if="badge(s.name)" class="min-w-6 rounded-pill bg-gold px-2 text-center font-numbers text-sm text-on-gold" :aria-label="`${inbox.unread} رسالة غير مقروءة`">{{ badge(s.name) }}</span>
          <span v-if="s.dev" class="rounded-pill bg-gold/15 px-2 text-xs text-gold">للمطور</span>
        </RouterLink>
      </nav>
      <RouterLink v-if="auth.user" to="/profile" class="flex min-h-touch items-center gap-3 rounded-xl bg-surface p-3 hover:bg-surface-raised">
        <span class="flex size-10 items-center justify-center rounded-full bg-gold font-display text-lg font-extrabold text-on-gold">{{ initial }}</span>
        <span class="min-w-0 flex-1">
          <span class="block truncate font-bold">{{ auth.user.name }}</span>
          <span class="block text-xs text-text-muted">حسابي</span>
        </span>
      </RouterLink>
      <div v-else class="flex flex-col gap-2">
        <RouterLink to="/login" class="flex h-touch items-center justify-center rounded-lg bg-gold font-bold text-on-gold">دخول</RouterLink>
        <RouterLink to="/register" class="flex h-touch items-center justify-center rounded-lg border border-text/15 font-bold">إنشاء حساب</RouterLink>
      </div>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <header class="sticky top-0 z-20 flex items-center gap-3 border-b border-text/5 bg-bg/95 px-4 py-3 backdrop-blur md:hidden">
        <BrandMark size="sm" />
        <RouterLink v-if="auth.user" to="/profile" class="ms-auto flex size-touch items-center justify-center rounded-full bg-gold font-display text-lg font-extrabold text-on-gold" aria-label="حسابي">{{ initial }}</RouterLink>
        <RouterLink v-else-if="auth.loaded" to="/login" class="ms-auto flex h-touch items-center rounded-lg bg-gold px-4 font-bold text-on-gold">دخول</RouterLink>
      </header>
      <RouterLink v-if="auth.user && !auth.user.email_verified && route.name !== 'profile'" to="/profile" class="block bg-warning/15 px-4 py-2 text-center text-sm">
        بريدك غير مؤكد بعد. <span class="font-bold text-gold">أكّده من صفحة حسابي</span>
      </RouterLink>
      <main class="mx-auto w-full max-w-6xl flex-1 px-4 py-5 pb-28 md:px-8 md:pb-8">
        <RouterView />
      </main>
    </div>

    <nav class="fixed inset-x-0 bottom-0 z-30 grid grid-cols-5 gap-1 border-t border-text/10 bg-bg-deep/95 px-2 pb-[max(0.5rem,env(safe-area-inset-bottom))] pt-2 backdrop-blur md:hidden" aria-label="الأقسام">
      <RouterLink
        v-for="s in tabs"
        :key="s.name"
        :to="s.path"
        class="flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl text-xs font-semibold"
        :class="active(s.path) ? 'bg-surface-raised text-gold' : 'text-text-soft'"
        :aria-current="active(s.path) ? 'page' : undefined"
      >
        <Icon :name="s.icon" />{{ s.label }}
      </RouterLink>
      <button
        type="button"
        class="flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl text-xs font-semibold"
        :class="more || moreActive ? 'bg-surface-raised text-gold' : 'text-text-soft'"
        :aria-expanded="more"
        aria-controls="more-sheet"
        @click="more = !more"
      >
        <span class="relative"><Icon name="more" /><span v-if="inbox.unread" class="absolute -end-2 -top-1 size-2.5 rounded-full bg-gold" :aria-label="`${inbox.unread} رسالة غير مقروءة`" /></span>المزيد
      </button>
    </nav>

    <div v-if="more" class="fixed inset-0 z-20 bg-black/50 md:hidden" @click="more = false" />
    <section v-if="more" id="more-sheet" class="fixed inset-x-0 bottom-0 z-25 rounded-t-xxl bg-surface p-4 pb-28 md:hidden" aria-label="باقي الأقسام">
      <div class="mb-3 flex items-center justify-between">
        <h2 class="font-display text-lg font-extrabold">باقي الأقسام</h2>
        <button type="button" class="flex size-touch items-center justify-center rounded-md" aria-label="إغلاق" @click="more = false"><Icon name="close" /></button>
      </div>
      <div class="grid grid-cols-3 gap-2">
        <RouterLink
          v-for="s in rest"
          :key="s.name"
          :to="s.path"
          class="flex min-h-20 flex-col items-center justify-center gap-2 rounded-xl text-sm font-semibold"
          :class="active(s.path) ? 'bg-gold/15 text-gold' : 'bg-surface-sunk text-text-soft'"
        >
          <span class="relative"><Icon :name="s.icon" /><span v-if="badge(s.name)" class="absolute -end-3 -top-2 min-w-5 rounded-pill bg-gold px-1 text-center font-numbers text-xs text-on-gold">{{ badge(s.name) }}</span></span>{{ s.label }}
        </RouterLink>
      </div>
    </section>
  </div>
</template>
