<script setup lang="ts">
// The staff (Sprint 31 W1, docs/features/specialists.md, X20): the line coaches, then the medical and the admin staff,
// each with 1 to 5 stars to choose (the price and the effect from the server), the contract working now with a countdown
// on the server's clock, and the renewal in its last day. No draft of its own: the stadium's cards.
import { useGlossary } from '../../lib/glossary'
import HelpTip from '../../components/ui/HelpTip.vue'
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import PriceTag from '../../components/ui/PriceTag.vue'
import { money } from '../../lib/format'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'

type View = components['schemas']['SpecialistsView']
type Spec = View['specialists'][number]
// The "?" texts [X19].
const g = useGlossary()
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const loaded = ref(false)
const error = ref('')
const notice = ref('')
const busy = ref(false)
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
  { title: 'الطاقم الطبي والإداري', hint: 'اللياقة والإصابات والإيقافات والمعنويات', types: ['physio', 'doctor', 'mental_coach', 'lawyer'] },
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

async function hire(s: Spec) {
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    const stars = chosen(s)
    const renewing = !!s.ends_at
    const { data } = await api.POST('/leagues/{league}/specialists', { params: { path: { league: leagueId.value! } }, body: { type: s.type, stars, idempotency_key: crypto.randomUUID() } })
    v.value = data!
    useWallet().load()
    notice.value = renewing ? `جدّدت عقد ${s.name} (${stars} نجوم)، ويبدأ حين ينتهي الحالي.` : `تعاقدت مع ${s.name} (${stars} نجوم) لمدة ${data!.days} أيام.`
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

onMounted(() => {
  load()
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
        <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">الطاقم</h1><HelpTip :text="g.specialists" label="الطاقم" /></span>
        <p class="mt-1 text-sm text-text-muted">عقود مؤقتة {{ v?.days ?? 7 }} أيام بنجوم من 1 إلى 5: نجوم أكثر، أثر أكبر وسعر أعلى. يُجدَّد العقد في آخر يوم منه، وإلا يستقيل صاحبه</p>
      </div>
      <div v-if="v" class="money-box px-4 py-2 text-end">
        <span class="block text-xs text-text-muted">أموال النادي</span>
        <b class="font-numbers text-xl" dir="ltr">{{ money(v.balance) }}</b>
      </div>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!loaded" class="text-text-muted">جارٍ التحميل...</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>

    <template v-else-if="v">
      <section v-for="grp in GROUPS" :key="grp.title" :aria-label="grp.title" class="flex flex-col gap-3">
        <div class="flex items-baseline gap-2"><h2 class="font-display text-xl font-extrabold">{{ grp.title }}</h2><span class="text-sm text-text-muted">{{ grp.hint }}</span></div>
        <div class="grid gap-3 sm:grid-cols-2">
          <article v-for="s in v.specialists.filter((x) => grp.types.includes(x.type))" :key="s.type" class="flex flex-col gap-3 rounded-xl bg-surface p-4" :class="s.ends_at ? 'ring-1 ring-success/50' : ''">
            <div class="flex items-start gap-3">
              <span class="grid size-12 shrink-0 place-items-center rounded-xl" :class="s.ends_at ? 'bg-success/20 text-success' : 'bg-gold/15 text-gold'">
                <svg viewBox="0 0 24 24" class="size-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path :d="ICON[s.type]" /></svg>
              </span>
              <span class="min-w-0 flex-1">
                <b class="block font-display text-lg">{{ s.name }}</b>
                <span v-if="s.stars" class="text-sm text-gold" :aria-label="`${s.stars} نجوم`">{{ '★'.repeat(s.stars) }}<span class="text-text/20">{{ '★'.repeat(5 - s.stars) }}</span></span>
                <span class="block text-sm text-text-muted">{{ offer(s).effect }}</span>
              </span>
            </div>
            <div v-if="s.ends_at" class="flex items-center justify-between rounded-lg bg-success/15 px-3 py-2">
              <span class="text-sm font-bold text-success">{{ s.renewed ? 'يعمل، والعقد مجدَّد' : 'يعمل الآن' }}</span>
              <span class="text-sm text-text-muted">ينتهي بعد <b class="font-numbers text-text">{{ left(s.ends_at) }}</b></span>
            </div>
            <template v-if="!s.ends_at || renewable(s)">
              <!-- Five stars to choose: the price and the effect follow. -->
              <div class="flex items-center gap-1" role="radiogroup" :aria-label="`نجوم ${s.name}`">
                <button v-for="n in 5" :key="n" type="button" role="radio" :aria-checked="chosen(s) === n" :aria-label="`${n} نجوم`" class="grid h-touch flex-1 place-items-center rounded-lg text-xl transition-colors" :class="n <= chosen(s) ? 'bg-gold/15 text-gold' : 'bg-surface-sunk text-text/25'" @click="pick[s.type] = n">★</button>
              </div>
              <button type="button" class="h-12 rounded-md bg-brand px-4 font-display font-bold disabled:opacity-40" :disabled="busy || (offer(s).currency === 'money' && offer(s).cost > v.balance)" @click="hire(s)">
                {{ s.ends_at ? 'جدّد العقد' : 'تعاقد' }} · {{ chosen(s) }} ★ · <PriceTag :amount="offer(s).cost" :currency="offer(s).currency" /></button>
            </template>
          </article>
        </div>
      </section>
    </template>
  </div>
</template>
