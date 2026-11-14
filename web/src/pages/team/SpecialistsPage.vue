<script setup lang="ts">
import SpendNote from '../../components/ui/SpendNote.vue'
import Icon from '../../components/Icon.vue'
// The staff (Sprint 31 W1, docs/features/specialists.md, X20): the line coaches, then the medical and the admin staff,
// each with 1 to 5 stars to choose (the price and the effect from the server), the contract working now with a countdown
// on the server's clock, and the renewal in its last day. No draft of its own: the stadium's cards.
import UiButton from '../../components/ui/UiButton.vue'
import { nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { uuid } from '../../lib/uuid'
import { useRoute } from 'vue-router'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import PriceTag from '../../components/ui/PriceTag.vue'
import { act, busy as isBusy } from '../../lib/action'
import { t } from '../../lib/i18n'

import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'

type View = components['schemas']['SpecialistsView']
type Spec = View['specialists'][number]
// The "?" texts [X19].
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const loaded = ref(false)
const error = ref('')
const now = ref(Date.now())
let skew = 0
let tick = 0
const ICON: Record<string, string> = {
  att_coach: 'M12 3l2.5 5 5.5.8-4 3.9.9 5.5L12 15.8 7.1 18.2l.9-5.5-4-3.9 5.5-.8z',
  mid_coach: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm0 5 3.8 2.8-1.5 4.4H9.7l-1.5-4.4Z',
  def_coach: 'M12 3 4 6v5c0 5 3.4 8.6 8 10 4.6-1.4 8-5 8-10V6l-8-3Z',
  keeper_coach: 'M6 10V6a2 2 0 0 1 4 0v4M10 9V5a2 2 0 0 1 4 0v4M14 9V6a2 2 0 0 1 4 0v8a6 6 0 0 1-12 0v-4',
  physio: 'M3 12h4l2-5 4 10 2-5h6',
  doctor: 'M12 5v14M5 12h14',
  lawyer: 'M12 3v18M5 7h14M7 7l-3 7h6zM17 7l-3 7h6zM8 21h8',
  mental_coach: 'M9 18h6M10 21h4M12 3a6 6 0 0 0-4 10.5c.8.8 1 1.5 1 2.5h6c0-1 .2-1.7 1-2.5A6 6 0 0 0 12 3Z',
}
const GROUPS = [
  { title: 'مدربو الخطوط', hint: 'كل مدرب يسرّع تدريب لاعبي خطه', types: ['att_coach', 'mid_coach', 'def_coach', 'keeper_coach'] },
  { title: 'الجهاز الطبي والإداري', hint: 'اللياقة والإصابات والإيقافات والمعنويات', types: ['physio', 'doctor', 'mental_coach', 'lawyer'] },
]
// The stars chosen on each card before signing (3 by default).
const pick = ref<Record<string, number>>({})
const chosen = (s: Spec) => pick.value[s.type] ?? (s.stars || 3)
const offer = (s: Spec) => s.offers.find((o) => o.stars === chosen(s))!
const renewable = (s: Spec) => !!s.ends_at && !s.renewed && new Date(s.ends_at).getTime() - now.value < 86400000 * ((v.value?.days ?? 7) / 7)
function left(iso: string) {
  const s = Math.max(0, Math.floor((new Date(iso).getTime() - now.value) / 1000))
  const d = Math.floor(s / 86400)
  const hms = [Math.floor((s % 86400) / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
  return d ? `${d} يوم و ${hms}` : hms
}

async function load() {
  try {
    leagueId.value ??= await currentLeague()
    if (leagueId.value) {
      const { data } = await api.GET('/leagues/{league}/specialists', { params: { path: { league: leagueId.value } } })
      v.value = data!
      skew = new Date(data!.now).getTime() - Date.now()
      now.value = Date.now() + skew
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

// [X87] Through lib/action: only this card's button waits, the result in a toast, coins asked once from 10 up.
function hire(s: Spec) {
  const stars = chosen(s)
  const renewing = !!s.ends_at
  const o = offer(s)
  return act(`hire:${s.type}`, () => api.POST('/leagues/{league}/specialists', { params: { path: { league: leagueId.value! } }, body: { type: s.type, stars, idempotency_key: uuid() } }), {
    coins: o.currency === 'coins' ? o.cost : undefined, onError: (m) => (error.value = m),
    success: (r) => renewing ? t('جدّدت عقد {v0} ({v1} نجوم)، ويبدأ حين ينتهي الحالي.', { v0: t(s.name), v1: stars }) : t('تعاقدت مع {v0} ({v1} نجوم) لمدة {v2} أيام.', { v0: t(s.name), v1: stars, v2: r.data!.days }),
  }).then((r) => { if (r?.data) { v.value = r.data; useWallet().load() } })
}

// [X61] From training («تعاقد مع مدرب الآن»): ?line=gk|def|mid|att opens on that line's coach, lit for a moment.
const route = useRoute()
const LINE_COACH: Record<string, string> = { gk: 'keeper_coach', def: 'def_coach', mid: 'mid_coach', att: 'att_coach' }
const focus = ref(LINE_COACH[String(route.query.line)] ?? '')

onMounted(async () => {
  await load()
  if (focus.value) {
    await nextTick()
    document.getElementById(`spec-${focus.value}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' })
    setTimeout(() => (focus.value = ''), 2400)
  }
  tick = window.setInterval(() => {
    now.value = Date.now() + skew
    if (v.value?.specialists.some((s) => s.ends_at && new Date(s.ends_at).getTime() <= now.value - 2000)) load()
  }, 1000)
})
onBeforeUnmount(() => clearInterval(tick))
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-end gap-3">
      <div class="flex-1">
        <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">{{ $t('الجهاز الفني') }}</h1></span>
      </div>
      <!-- [X85] The club's money is on the top bar, for this slot's club only. -->
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-if="!loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <p v-else-if="!leagueId" class="rounded-xl ui-card p-6 text-text-muted">{{ $t('ليس لديك فريق بعد.') }} <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink></p>

    <template v-else-if="v">
      <section v-for="grp in GROUPS" :key="grp.title" :aria-label="grp.title" class="flex flex-col gap-3">
        <div class="flex items-baseline gap-2"><h2 class="font-display text-xl font-extrabold">{{ $t(grp.title) }}</h2><span class="text-sm text-text-muted">{{ $t(grp.hint) }}</span></div>
        <div class="grid gap-3 sm:grid-cols-2">
          <article v-for="s in v.specialists.filter((x) => grp.types.includes(x.type))" :id="`spec-${s.type}`" :key="s.type" class="flex flex-col gap-3 rounded-xl ui-card p-4 transition-shadow duration-500" :class="focus === s.type ? 'ring-2 ring-gold pulse-ring' : s.ends_at ? 'ring-1 ring-success/50' : ''">
            <div class="flex items-start gap-3">
              <span class="grid size-12 shrink-0 place-items-center rounded-xl" :class="s.ends_at ? 'bg-success/20 text-success' : 'bg-gold/15 text-gold'">
                <svg viewBox="0 0 24 24" class="size-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path :d="ICON[s.type]" /></svg>
              </span>
              <span class="min-w-0 flex-1">
                <b class="block font-display text-lg">{{ s.name }}</b>
                <span v-if="s.stars" class="text-sm text-gold" :aria-label="$t('{v0} نجوم', { v0: s.stars })"><Icon v-for="k in s.stars" :key="k" name="star" :size="14" class="inline-block" /><span class="text-text/20"><Icon v-for="k in 5 - s.stars" :key="k" name="star" :size="14" class="inline-block" /></span></span>
                <span class="block text-sm text-text-muted">{{ offer(s).effect }}</span>
              </span>
            </div>
            <div v-if="s.ends_at" class="flex items-center justify-between rounded-lg bg-success/15 px-3 py-2">
              <span class="text-sm font-bold text-success">{{ s.renewed ? $t('يعمل، والعقد مجدَّد') : $t('يعمل الآن') }}</span>
              <span class="text-sm text-text-muted">{{ $t('ينتهي بعد') }} <b class="font-numbers text-text">{{ left(s.ends_at) }}</b></span>
            </div>
            <template v-if="!s.ends_at || renewable(s)">
              <!-- Five stars to choose: the price and the effect follow. -->
              <div class="flex items-center gap-1" role="radiogroup" :aria-label="$t('نجوم {v0}', { v0: s.name })">
                <button v-for="n in 5" :key="n" type="button" role="radio" :aria-checked="chosen(s) === n" :aria-label="$t('{v0} نجوم', { v0: n })" class="grid h-touch flex-1 place-items-center rounded-lg text-xl transition-colors" :class="n <= chosen(s) ? 'bg-gold/15 text-gold' : 'bg-surface-sunk text-text/25'" @click="pick[s.type] = n"><Icon name="star" :size="16" /></button>
              </div>
              <UiButton variant="brand" :disabled="isBusy(`hire:${s.type}`) || (offer(s).currency === 'money' && offer(s).cost > v.balance)" @click="hire(s)">
                {{ s.ends_at ? $t('جدّد العقد') : $t('تعاقد') }} · {{ chosen(s) }} <Icon name="star" :size="14" class="inline-block align-[-2px]" /> · <PriceTag :amount="offer(s).cost" :currency="offer(s).currency" /></UiButton>
              <SpendNote v-if="offer(s).quote" :quote="offer(s).quote!" />
            </template>
          </article>
        </div>
      </section>
    </template>
  </div>
</template>
