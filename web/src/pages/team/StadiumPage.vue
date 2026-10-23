<script setup lang="ts">
// The stadium (Sprint 29 W1, PLAN 2.9), per the WebStadium and MobileStadium drafts: the facts on top, then the
// three sections with their 3 × 5 parts (done gold, building green), each stage's effect, and the next part's
// start with its price. One part at a time; the countdown runs on the server's clock.
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import { count, money } from '../../lib/format'
import { currentLeague } from '../../lib/currentLeague'

type View = components['schemas']['StadiumView']
type Section = View['sections'][number]
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
  seats: { title: 'التذاكر والمقاعد', effect: 'مقاعد أكثر ودخل أعلى من كل مباراة على أرضك', icon: 'M4 18V9l8-5 8 5v9M8 18v-5h8v5M4 18h16' },
  pitch: { title: 'أرضية الملعب', effect: 'فوق ميزة الأرض الأساسية لكل مباراة على أرضك', icon: 'M3 6h18v12H3zM12 6v12M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5' },
  training: { title: 'منشأة التدريب', effect: 'كل جلسة تدريب ومعسكر أسرع بنسبة عشوائية', icon: 'M6 7v10M3 9v6M18 7v10M21 9v6M6 12h12' },
}
const pct = (bp: number) => `+${(bp / 100).toLocaleString('ar-EG-u-nu-latn', { maximumFractionDigits: 1 })}%`
function effect(s: Section, stage: number) {
  // Seats: the extra tickets of a home match; pitch: the extra home advantage; training: the most a session speeds up.
  if (s.section === 'seats') return `+${count(s.effects[stage]! - s.effects[0]!)}`
  return pct(s.effects[stage]!)
}
const left = computed(() => {
  if (!v.value?.building) return ''
  const sec = Math.max(0, Math.floor((new Date(v.value.building.ends_at).getTime() - now.value) / 1000))
  return [Math.floor(sec / 3600), Math.floor((sec % 3600) / 60), sec % 60].map((n) => String(n).padStart(2, '0')).join(':')
})
// Part n of a section (0..14): done, building, or empty.
function part(s: Section, n: number) {
  if (n < s.done) return 'bg-gold'
  if (v.value?.building?.section === s.section && n === s.done) return 'bg-success animate-pulse'
  return 'bg-white/10'
}

async function load() {
  try {
    leagueId.value ??= await currentLeague()
    if (leagueId.value) {
      const { data } = await api.GET('/leagues/{league}/stadium', { params: { path: { league: leagueId.value } } })
      v.value = data!
      skew = new Date(data!.now).getTime() - Date.now()
      now.value = Date.now() + skew
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

async function start(s: Section) {
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.POST('/leagues/{league}/stadium', { params: { path: { league: leagueId.value! } }, body: { section: s.section, idempotency_key: crypto.randomUUID() } })
    v.value = data!
    notice.value = `بدأ الجزء ${s.next!.part} من المرحلة ${s.next!.stage} في ${INFO[s.section]!.title}.`
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

onMounted(() => {
  load()
  tick = window.setInterval(() => {
    now.value = Date.now() + skew
    if (v.value?.building && new Date(v.value.building.ends_at).getTime() <= now.value - 2000) load()
  }, 1000)
})
onBeforeUnmount(() => clearInterval(tick))
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-end gap-3">
      <div class="flex-1">
        <h1 class="font-display text-3xl font-extrabold">الملعب</h1>
        <p class="mt-1 text-sm text-text-muted">جزء واحد في كل مرة · كل جزء {{ v ? Math.round(v.part_minutes / 60) : 18 }} ساعة · تبدأ كل جزء بنفسك</p>
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

    <template v-else-if="v">
      <section aria-label="الملعب الآن" class="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <div class="rounded-xl bg-surface p-3"><span class="block text-xs text-text-muted">السعة</span><b class="font-numbers text-2xl" dir="ltr">{{ count(v.facts.capacity) }}</b></div>
        <div class="rounded-xl bg-surface p-3"><span class="block text-xs text-text-muted">ميزة الأرض</span><b class="font-numbers text-2xl text-success" dir="ltr">{{ pct(v.facts.home_bp) }}</b></div>
        <div class="rounded-xl bg-surface p-3"><span class="block text-xs text-text-muted">دخل التذاكر للمباراة</span><b class="font-numbers text-2xl" dir="ltr">{{ money(v.facts.tickets_per_match) }}</b></div>
        <div class="rounded-xl bg-surface p-3"><span class="block text-xs text-text-muted">الأجزاء المكتملة</span><b class="font-numbers text-2xl text-gold" dir="ltr">{{ v.facts.parts_done }} / {{ v.parts_total }}</b></div>
      </section>

      <section v-if="v.building" aria-label="يُبنى الآن" class="flex flex-wrap items-center gap-3 rounded-xl border border-success/40 bg-surface p-4">
        <span class="flex-1"><b class="block">يُبنى الآن: {{ INFO[v.building.section]!.title }}</b>
          <span class="text-sm text-text-muted">الجزء {{ v.building.part }} من 5 في المرحلة {{ v.building.stage }}</span></span>
        <span class="text-end"><span class="block text-xs text-text-muted">يكتمل بعد</span><b class="font-numbers text-2xl text-success" dir="ltr">{{ left }}</b></span>
      </section>

      <section aria-label="أقسام الملعب" class="grid gap-3 lg:grid-cols-3">
        <article v-for="s in v.sections" :key="s.section" class="flex flex-col gap-3 rounded-xl bg-surface p-4"
          :class="v.building?.section === s.section ? 'border border-success/50' : ''">
          <div class="flex items-start gap-3">
            <span class="grid size-10 shrink-0 place-items-center rounded-lg bg-gold/15 text-gold">
              <svg viewBox="0 0 24 24" class="size-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path :d="INFO[s.section]!.icon" /></svg>
            </span>
            <span><b class="block font-display text-lg">{{ INFO[s.section]!.title }}</b><span class="text-sm text-text-muted">{{ INFO[s.section]!.effect }}</span></span>
          </div>
          <div v-for="st in [1, 2, 3]" :key="st" class="flex items-center gap-3">
            <span class="w-16 text-xs text-text-muted">المرحلة {{ st }}</span>
            <span class="flex flex-1 gap-1" :aria-label="`المرحلة ${st}: ${Math.max(0, Math.min(5, s.done - (st - 1) * 5))} من 5`">
              <span v-for="p in 5" :key="p" class="h-2.5 flex-1 rounded-full" :class="part(s, (st - 1) * 5 + p - 1)" />
            </span>
            <span class="w-20 text-end font-numbers text-sm" :class="s.stage >= st ? 'text-gold' : 'text-text-muted'" dir="ltr">{{ effect(s, st) }}</span>
          </div>
          <p class="text-sm text-text-muted">{{ s.stage }} من 3 مراحل · {{ s.done }} من 15 جزءاً</p>
          <button v-if="s.next" type="button" class="mt-auto h-12 rounded-md bg-gold px-4 font-display font-bold text-on-gold disabled:opacity-40"
            :disabled="busy || !!v.building || s.next.cost > v.balance" @click="start(s)">
            ابدأ الجزء التالي · <span class="font-numbers" dir="ltr">{{ money(s.next.cost) }}</span></button>
          <p v-else class="mt-auto rounded-md bg-gold/15 py-3 text-center font-bold text-gold">القسم مكتمل</p>
        </article>
      </section>

      <p class="rounded-xl bg-surface p-4 text-sm text-text-muted">الملعب كاملاً {{ v.parts_total }} جزءاً، أي حوالي 91% من الموسم. اختر أولوياتك: الدخل، أو ميزة الأرض، أو سرعة التدريب.</p>
    </template>
  </div>
</template>
