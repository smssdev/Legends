<script setup lang="ts">
// The specialists (Sprint 31 W1, docs/features/specialists.md): four cards, each with what it does, its price and
// the contract working now with a countdown on the server's clock. No draft of its own: the stadium's cards.
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
const INFO: Record<string, { title: string; effect: string; icon: string }> = {
  doctor: { title: 'الطبيب', effect: 'كل مباراة تُنقص غياب المصابين مباراتين بدل واحدة.', icon: 'M12 5v14M5 12h14' },
  lawyer: { title: 'المحامي', effect: 'نصف البطاقات الحمراء الجديدة تقريباً بلا إيقاف.', icon: 'M12 3v18M5 7h14M7 7l-3 7h6zM17 7l-3 7h6zM8 21h8' },
  keeper_coach: { title: 'مدرب الحراس', effect: 'الحارس +2 في القوة وخصائص الحارس في كل مباراة.', icon: 'M6 10V6a2 2 0 0 1 4 0v4M10 9V5a2 2 0 0 1 4 0v4M14 9V6a2 2 0 0 1 4 0v8a6 6 0 0 1-12 0v-4' },
  physio: { title: 'المعالج البدني', effect: 'من يرتاح في مباراة ناديه يستعيد 15 لياقة فوق المعتاد.', icon: 'M3 12h4l2-5 4 10 2-5h6' },
}
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
    const { data } = await api.POST('/leagues/{league}/specialists', { params: { path: { league: leagueId.value! } }, body: { type: s.type, idempotency_key: crypto.randomUUID() } })
    v.value = data!
    useWallet().load()
    notice.value = `تعاقدت مع ${INFO[s.type]!.title} لمدة ${data!.days} أيام.`
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
        <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">الأخصائيون</h1><HelpTip :text="g.specialists" label="الأخصائيون" /></span>
        <p class="mt-1 text-sm text-text-muted">عقد كل أخصائي {{ v?.days ?? 7 }} أيام، يُدفع عند التوقيع، وتجدده بنفسك بعد أن ينتهي</p>
      </div>
      <div v-if="v" class="rounded-lg bg-surface px-4 py-2 text-end">
        <span class="block text-xs text-text-muted">أموال النادي</span>
        <b class="font-numbers text-xl" dir="ltr">{{ money(v.balance) }}</b>
      </div>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!loaded" class="text-text-muted">جارٍ التحميل...</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>

    <section v-else-if="v" aria-label="الأخصائيون" class="grid gap-3 sm:grid-cols-2">
      <article v-for="s in v.specialists" :key="s.type" class="flex flex-col gap-3 rounded-xl bg-surface p-4" :class="s.ends_at ? 'border border-success/50' : ''">
        <div class="flex items-start gap-3">
          <span class="grid size-11 shrink-0 place-items-center rounded-lg bg-gold/15 text-gold">
            <svg viewBox="0 0 24 24" class="size-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path :d="INFO[s.type]!.icon" /></svg>
          </span>
          <span><b class="block font-display text-lg">{{ INFO[s.type]!.title }}</b><span class="text-sm text-text-muted">{{ INFO[s.type]!.effect }}</span></span>
        </div>
        <div v-if="s.ends_at" class="mt-auto flex items-center justify-between rounded-lg bg-success/15 px-3 py-2">
          <span class="text-sm font-bold text-success">يعمل الآن</span>
          <span class="text-sm text-text-muted">ينتهي بعد <b class="font-numbers text-text">{{ left(s.ends_at) }}</b></span>
        </div>
        <button v-else type="button" class="mt-auto h-12 rounded-md bg-gold px-4 font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy || (s.currency === 'money' && s.cost > v.balance)" @click="hire(s)">
          تعاقد · <PriceTag :amount="s.cost" :currency="s.currency" /></button>
      </article>
    </section>
  </div>
</template>
