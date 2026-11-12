<script setup lang="ts">
// [Sprint 28] The development ideas, three tabs: a suggestion to the developers (and the team's answer to each of
// mine, with its reward), the polls on what to build next (one vote, the counts after voting or at the end, the
// winner), and the honour roll of the coaches whose suggestions the team liked. The rules are the server's.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import Icon from '../components/Icon.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
import { stamp } from '../lib/dates'
import { intlLocale } from '../lib/i18n'

type S = components['schemas']
type Tab = 'suggest' | 'polls' | 'honours'
const page = ref<{ suggestions: S['Suggestion'][]; per_day: number; left_today: number; polls: S['Poll'][]; honours: S['HonourContributor'][] } | null>(null)
const tab = ref<Tab>('suggest')
const title = ref('')
const body = ref('')
const busy = ref(false)
const error = ref('')
const notice = ref('')
const when = stamp
const until = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))
const openPolls = computed(() => page.value?.polls.filter((p) => p.state === 'open' && p.my_vote === null).length ?? 0)
const STATUS: Record<S['Suggestion']['status'], { label: string; tone: string }> = {
  pending: { label: 'ينتظر رد الفريق', tone: 'bg-text/10 text-text-muted' },
  accepted: { label: 'أعجب الفريق', tone: 'bg-gold/15 text-gold' },
  built: { label: 'نُفّذ في اللعبة', tone: 'bg-success/15 text-success' },
  rejected: { label: 'لم يُعتمد', tone: 'bg-live/15 text-danger' },
}
const TABS: [Tab, string][] = [['suggest', 'اقترح'], ['polls', 'التصويت'], ['honours', 'قائمة الشرف']]
const share = (p: S['Poll'], votes: number | null) => (p.total ? Math.round(((votes ?? 0) * 100) / p.total) : 0)

onMounted(async () => {
  try {
    page.value = (await api.GET('/ideas')).data!
    if (openPolls.value) tab.value = 'polls'
  } catch (e) {
    error.value = asApiError(e).message
  }
})

async function run(fn: () => Promise<void>) {
  busy.value = true
  error.value = ''
  notice.value = ''
  try {
    await ensureCsrf()
    await fn()
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}
const send = () => run(async () => {
  const s = (await api.POST('/ideas/suggestions', { body: { title: title.value.trim(), body: body.value.trim() } })).data!.suggestion
  page.value!.suggestions.unshift(s)
  page.value!.left_today = Math.max(0, page.value!.left_today - 1)
  title.value = ''
  body.value = ''
  notice.value = 'وصل اقتراحك لفريق التطوير. شكراً لك! يصلك ردهم في رسائلك.'
})
const vote = (p: S['Poll'], option: number) => run(async () => {
  const fresh = (await api.POST('/ideas/polls/{poll}/vote', { params: { path: { poll: p.id } }, body: { option_id: option } })).data!.poll
  page.value!.polls = page.value!.polls.map((x) => (x.id === fresh.id ? fresh : x))
})
</script>

<template>
  <div class="mx-auto flex w-full max-w-3xl flex-col gap-4">
    <header class="flex flex-col gap-1">
      <h1 class="flex items-center gap-2 font-display text-3xl font-extrabold"><Icon name="idea" :size="30" class="text-gold" />{{ $t('اقتراحات التطوير') }}</h1>
      <p class="text-text-soft">{{ $t('شاركنا في بناء اللعبة: اقترح، وصوّت على الميزة القادمة، وادخل قائمة الشرف.') }}</p>
    </header>

    <div class="flex gap-1 self-start rounded-xl bg-surface p-1" role="tablist">
      <button v-for="[k, l] in TABS" :key="k" type="button" role="tab" :aria-selected="tab === k" class="flex h-touch items-center gap-1.5 rounded-lg px-4 text-sm font-bold"
        :class="tab === k ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="tab = k">
        {{ $t(l) }}<span v-if="k === 'polls' && openPolls" class="rounded-pill bg-live px-1.5 font-numbers text-xs text-white">{{ openPolls }}</span>
      </button>
    </div>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">{{ $t(notice) }}</p>
    <div v-if="!page && !error" class="h-60 animate-pulse rounded-2xl bg-surface" aria-hidden="true" />

    <template v-if="page && tab === 'suggest'">
      <form class="flex flex-col gap-3 rounded-2xl bg-surface p-4" @submit.prevent="send">
        <label class="flex flex-col gap-1 text-sm font-bold">{{ $t('عنوان الاقتراح') }}
          <input v-model="title" maxlength="120" :placeholder="$t('مثلاً: وضع الليل في شاشة المباراة')" class="h-touch rounded-lg bg-surface-sunk px-3 font-normal" /></label>
        <label class="flex flex-col gap-1 text-sm font-bold">{{ $t('اشرح فكرتك') }}
          <textarea v-model="body" rows="5" maxlength="2000" :placeholder="$t('ما الذي تقترحه؟ ولماذا يجعل اللعبة أفضل؟')" class="rounded-lg bg-surface-sunk p-3 font-normal" /></label>
        <div class="flex flex-wrap items-center gap-3">
          <button type="submit" class="h-12 rounded-lg bg-gold px-6 font-bold text-on-gold disabled:opacity-40"
            :disabled="busy || title.trim().length < 4 || body.trim().length < 10 || !page.left_today">{{ $t('أرسل الاقتراح') }}</button>
          <span class="text-xs text-text-muted">{{ $t('باقٍ لك {v0} من {v1} اقتراحات في 24 ساعة', { v0: page.left_today, v1: page.per_day }) }}</span>
        </div>
        <p class="text-xs text-text-muted">{{ $t('الاقتراح الذي يعجب الفريق قد يأخذ مكافأة كوينز ويضع اسمك في قائمة الشرف.') }}</p>
      </form>

      <section class="flex flex-col gap-2" :aria-label="$t('اقتراحاتي')">
        <h2 class="font-display text-xl font-bold">{{ $t('اقتراحاتي') }}</h2>
        <p v-if="!page.suggestions.length" class="rounded-xl bg-surface p-4 text-sm text-text-muted">{{ $t('لم ترسل اقتراحاً بعد.') }}</p>
        <article v-for="s in page.suggestions" :key="s.id" class="flex flex-col gap-1.5 rounded-xl bg-surface p-4">
          <div class="flex flex-wrap items-center gap-2">
            <b class="min-w-0 flex-1">{{ s.title }}</b>
            <span class="rounded-pill px-2 py-0.5 text-xs font-bold" :class="STATUS[s.status].tone">{{ $t(STATUS[s.status].label) }}</span>
          </div>
          <p class="line-clamp-3 whitespace-pre-line text-sm text-text-soft">{{ s.body }}</p>
          <p v-if="s.reply" class="rounded-lg bg-gold/10 px-3 py-2 text-sm"><b class="text-gold">{{ $t('رد الفريق:') }}</b> {{ s.reply }}</p>
          <p class="flex items-center gap-2 text-xs text-text-muted"><span dir="ltr">{{ when(s.at) }}</span>
            <span v-if="s.coins" class="font-bold text-gold">+{{ s.coins }} {{ $t('كوينز') }}</span></p>
        </article>
      </section>
    </template>

    <template v-if="page && tab === 'polls'">
      <p v-if="!page.polls.length" class="rounded-xl bg-surface p-6 text-center text-text-muted">{{ $t('لا تصويت مفتوح الآن. حين يفتح الفريق تصويتاً تراه هنا.') }}</p>
      <article v-for="p in page.polls" :key="p.id" class="flex flex-col gap-3 rounded-2xl bg-surface p-4" :aria-label="p.question">
        <div class="flex flex-wrap items-start gap-2">
          <h2 class="min-w-0 flex-1 font-display text-lg font-bold">{{ p.question }}</h2>
          <span class="rounded-pill px-2 py-0.5 text-xs font-bold" :class="p.state === 'open' ? 'bg-success/15 text-success' : 'bg-text/10 text-text-muted'">
            {{ p.state === 'open' ? $t('مفتوح حتى {v0}', { v0: until(p.ends_at) }) : $t('انتهى') }}</span>
        </div>
        <p v-if="p.body" class="whitespace-pre-line text-sm text-text-soft">{{ p.body }}</p>
        <ul class="flex flex-col gap-2">
          <li v-for="o in p.options" :key="o.id">
            <button type="button" class="poll-option relative flex min-h-touch w-full items-center gap-2 overflow-hidden rounded-lg border px-3 py-2 text-start disabled:cursor-default"
              :class="[p.my_vote === o.id ? 'border-gold' : 'border-text/10', p.winners.includes(o.id) ? 'bg-gold/10' : 'bg-surface-sunk']"
              :disabled="busy || p.state !== 'open' || p.my_vote === o.id" :aria-pressed="p.my_vote === o.id" @click="vote(p, o.id)">
              <span v-if="o.votes !== null" class="absolute inset-y-0 start-0 bg-gold/20" :style="{ width: share(p, o.votes) + '%' }" aria-hidden="true" />
              <span class="relative min-w-0 flex-1 font-bold">{{ o.label }}<span v-if="p.my_vote === o.id" class="ms-1 text-gold">✓</span><span v-if="p.winners.includes(o.id)" class="ms-1">🏆</span></span>
              <span v-if="o.votes !== null" class="relative font-numbers text-sm" dir="ltr">{{ share(p, o.votes) }}%</span>
            </button>
          </li>
        </ul>
        <p class="text-xs text-text-muted">
          <template v-if="p.total !== null">{{ $t('{v0} صوتاً', { v0: p.total }) }}</template>
          <template v-if="p.state === 'open'"> · {{ p.my_vote === null ? $t('صوّت لترى النتائج. لك صوت واحد.') : $t('يمكنك تغيير صوتك حتى ينتهي التصويت.') }}</template>
          <template v-else-if="p.winners.length"> · {{ $t('الأعلى أصواتاً يأخذ أولوية التطوير.') }}</template>
        </p>
      </article>
    </template>

    <template v-if="page && tab === 'honours'">
      <section class="flex flex-col gap-2 rounded-2xl border border-gold/30 bg-surface p-4" :aria-label="$t('قائمة الشرف')">
        <h2 class="font-display text-xl font-bold">{{ $t('ساهموا في تطوير اللعبة وتحسينها') }}</h2>
        <p v-if="!page.honours.length" class="text-sm text-text-muted">{{ $t('القائمة تنتظر أول اسم. اقترح فكرة تعجب الفريق وكن الأول!') }}</p>
        <ol class="flex flex-col gap-2">
          <li v-for="h in page.honours" :key="h.user.id" class="flex items-center gap-3 rounded-xl bg-surface-sunk p-3">
            <span class="w-7 shrink-0 text-center font-numbers text-lg font-extrabold" :class="h.rank <= 3 ? 'text-gold' : 'text-text-muted'">{{ h.rank }}</span>
            <AppImage v-if="h.user.avatar_url" :src="h.user.avatar_url" alt="" class="size-10 shrink-0 rounded-full object-cover" :size="40" />
            <span v-else class="flex size-10 shrink-0 items-center justify-center rounded-full bg-gold font-bold text-on-gold" aria-hidden="true">{{ h.user.name.slice(0, 1) }}</span>
            <div class="min-w-0 flex-1">
              <RouterLink :to="{ name: 'coach', params: { id: h.user.id } }" class="flex items-center gap-1 font-bold">{{ h.user.name }} <OfficialBadge v-if="h.user.official" /></RouterLink>
              <p class="truncate text-xs text-text-muted">{{ h.latest.title }}</p>
            </div>
            <div class="shrink-0 text-end text-xs">
              <b class="block font-numbers text-base">{{ h.count }}</b>{{ $t('اقتراح مقبول') }}
              <span v-if="h.coins" class="block font-bold text-gold">+{{ h.coins }}</span>
            </div>
          </li>
        </ol>
      </section>
    </template>
  </div>
</template>

<style scoped>
.poll-option span[aria-hidden] { transition: width 0.5s ease }
@media (prefers-reduced-motion: reduce) { .poll-option span[aria-hidden] { transition: none } }
</style>
