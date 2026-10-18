<template>
  <main class="mx-auto flex min-h-dvh max-w-[1500px] flex-col gap-3 px-3 py-3 md:px-5">
    <header class="flex flex-wrap items-center gap-2">
      <RouterLink to="/sim" class="flex items-center gap-2">
        <img src="/icon-192.png" alt="" class="size-9 rounded-md" />
        <span class="font-display text-lg font-extrabold tracking-wide text-gold" dir="ltr">LEGENDS</span>
      </RouterLink>
      <span class="rounded-pill bg-gold/15 px-3 py-1 text-xs font-bold text-gold">المحاكي · بذرة <span class="font-numbers">{{ view?.seed }}</span></span>
      <div class="flex-1" />
      <template v-if="live">
        <span class="flex h-touch items-center gap-2 rounded-md bg-live/15 px-3 text-sm font-bold text-[#FF8A8A]"><span class="size-2 rounded-full bg-live" />مباشر · تدير {{ mine ? view?.clubs[mine].name : '' }}</span>
        <button type="button" class="h-touch rounded-md bg-surface px-3 text-sm" @click="share">{{ copied ? 'نُسخ الرابط' : 'رابط الصديق' }}</button>
      </template>
      <div v-else class="flex items-center gap-1 rounded-lg bg-surface p-1" role="group" aria-label="سرعة المحاكاة">
        <button type="button" class="size-10 rounded-sm bg-surface-raised" :aria-label="playing ? 'إيقاف مؤقت' : 'تشغيل'" @click="togglePlay">
          <svg v-if="playing" viewBox="0 0 24 24" class="mx-auto size-4" fill="currentColor" aria-hidden="true"><rect x="6" y="5" width="4" height="14" rx="1" /><rect x="14" y="5" width="4" height="14" rx="1" /></svg>
          <svg v-else viewBox="0 0 24 24" class="mx-auto size-4" fill="currentColor" aria-hidden="true"><path d="M7 5l12 7-12 7z" /></svg>
        </button>
        <button v-for="s in [1, 2, 4]" :key="s" type="button" class="h-10 min-w-11 rounded-sm font-numbers text-lg" :class="speed === s ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="speed === s" dir="ltr" @click="speed = s">×{{ s }}</button>
        <button type="button" class="h-10 rounded-sm px-3 text-sm text-text-soft" :disabled="skipping" @click="skip">{{ skipping ? '...' : 'تخطٍّ للنهاية' }}</button>
      </div>
      <button type="button" class="h-touch rounded-md bg-surface px-3 text-sm" :aria-pressed="soundOn" @click="toggleSound">{{ soundOn ? 'الصوت: يعمل' : 'تشغيل الصوت' }}</button>
      <button type="button" class="h-touch rounded-md bg-surface px-3 text-sm text-text-muted" :aria-pressed="dev" @click="dev = !dev">لوحة المطور</button>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-[#FF8A8A]">{{ error }}</p>

    <div v-if="view" class="grid items-start gap-3 lg:grid-cols-[minmax(0,1fr)_360px]">
      <div class="flex min-w-0 flex-col gap-3 lg:col-start-1">
        <section v-if="live && !started" aria-label="بدء المباراة المباشرة" class="flex flex-col items-center gap-3 rounded-xl border border-gold/40 bg-surface p-4 text-center">
          <span class="font-display text-2xl font-extrabold">مباراة مباشرة مع صديق</span>
          <p class="max-w-md text-sm text-text-soft">أرسل الرابط لصديقك ليدير {{ view?.clubs[other].name }} من جهازه، ثم ابدأ حين يكون جاهزاً.</p>
          <div class="flex w-full max-w-md gap-2">
            <input :value="friendLink" readonly dir="ltr" aria-label="رابط الصديق" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3 text-xs" @focus="($event.target as HTMLInputElement).select()" />
            <button type="button" class="h-touch rounded-md bg-surface-raised px-4 text-sm" @click="share">{{ copied ? 'نُسخ' : 'نسخ' }}</button>
          </div>
          <button type="button" class="h-12 rounded-md bg-gold px-8 font-display font-bold text-on-gold disabled:opacity-50" :disabled="starting" @click="startLive">{{ starting ? '...' : 'ابدأ المباراة' }}</button>
          <span class="text-xs text-text-muted">أي من المدربين يستطيع البدء.</span>
        </section>

        <section class="relative w-full overflow-hidden rounded-xl border border-text/10 bg-bg-deep" style="aspect-ratio: 1000 / 560" aria-label="الملعب" dir="ltr">
          <PitchCanvas ref="pitch" :players="pitchPlayers" :kits="kits" />

          <div dir="rtl" class="absolute end-3 top-3 flex items-stretch overflow-hidden rounded-md shadow-lg" aria-live="polite">
            <span class="flex items-center px-3 font-display text-sm font-bold" :style="{ background: kits.home, color: kits.homeText }">{{ view.clubs.home.name }}</span>
            <span class="flex items-center bg-bg-deep px-3 py-1 font-numbers text-2xl" dir="ltr">{{ score.away }} – {{ score.home }}</span>
            <span class="flex items-center px-3 font-display text-sm font-bold" :style="{ background: kits.away, color: kits.awayText }">{{ view.clubs.away.name }}</span>
            <span class="flex items-center gap-1.5 bg-surface px-3 font-numbers text-xl text-gold"><span class="size-1.5 rounded-full bg-live" />{{ minuteText }}</span>
          </div>

          <span v-if="phaseText" dir="rtl" class="absolute start-3 top-12 rounded-pill md:top-3 bg-bg-deep/80 px-3 py-1 text-xs text-text-soft">{{ phaseText }}</span>

          <div v-if="live && countdown > 0" dir="rtl" class="pointer-events-none absolute inset-0 flex items-center justify-center">
            <span class="font-numbers text-8xl text-gold drop-shadow-lg">{{ countdown }}</span>
          </div>

          <div v-if="goal" dir="rtl" class="absolute inset-0 flex flex-col items-center justify-center gap-3" :style="{ background: `radial-gradient(circle at 50% 45%, ${goal.color}99, rgba(4,12,30,0.4) 62%)` }">
            <span class="font-display text-6xl font-extrabold drop-shadow-lg md:text-7xl">هدف!</span>
            <span class="rounded-pill bg-bg-deep/90 px-4 py-2 text-base font-semibold">{{ goal.text }}</span>
          </div>

          <div v-if="halftime || finished" dir="rtl" class="absolute inset-0 flex flex-col items-center justify-center gap-4 bg-bg-deep/85 p-4 text-center">
            <span class="text-sm font-bold text-gold">{{ finished ? 'نهاية المباراة' : 'الاستراحة' }}</span>
            <span class="font-numbers text-6xl" dir="ltr">{{ score.away }} – {{ score.home }}</span>
            <span v-if="shootout" class="text-sm text-text-soft">ركلات الترجيح: {{ shootout.home }} - {{ shootout.away }}</span>
            <div class="flex flex-wrap justify-center gap-2">
              <span v-if="halftime && live" class="text-sm text-text-soft">الشوط الثاني بعد <b class="font-numbers text-lg text-gold">{{ halftimeLeft }}</b> ثانية · غيّر خطتك الآن</span>
              <button v-if="halftime && !live" type="button" class="h-12 rounded-md bg-gold px-6 font-display font-bold text-on-gold" @click="endHalftime">ابدأ الشوط الثاني <span class="font-numbers">({{ halftimeLeft }})</span></button>
              <RouterLink v-if="finished" :to="{ name: 'sim-report', params: { id }, query: mine ? { side: mine } : {} }" class="flex h-12 items-center rounded-md bg-gold px-6 font-display font-bold text-on-gold">تقرير المباراة</RouterLink>
              <RouterLink v-if="finished" to="/sim" class="flex h-12 items-center rounded-md bg-surface-raised px-5">مباراة جديدة</RouterLink>
            </div>
          </div>

          <div dir="rtl" class="absolute inset-x-3 bottom-3 flex items-center gap-3 rounded-lg bg-bg-deep/85 px-4 py-2">
            <span class="font-numbers text-lg text-gold">{{ minuteText }}</span>
            <span class="flex-1 text-sm font-semibold md:text-base">{{ feed[0]?.text ?? 'صافرة البداية...' }}</span>
          </div>
        </section>
      </div>

      <div class="flex min-w-0 flex-col gap-3 lg:col-start-1 lg:row-start-2">
        <section class="rounded-xl bg-surface px-4 py-3" aria-label="الزخم">
          <div class="mb-1 flex justify-between text-xs text-text-muted"><span class="font-display text-sm font-bold text-text">الزخم</span><span>أعلى: {{ view.clubs.home.name }} · أسفل: {{ view.clubs.away.name }}</span></div>
          <div class="h-20"><Momentum :values="momentum" :home-color="kits.home" /></div>
        </section>

        <section class="rounded-xl bg-surface p-4" aria-label="الإحصائيات">
          <StatsGrid :home="teams.home.stats" :away="teams.away.stats" :home-color="kits.home" />
        </section>

        <section v-if="dev" class="rounded-xl border border-gold/40 bg-surface-sunk p-4 font-mono text-xs leading-6" dir="ltr" aria-label="لوحة المطور">
          <div>tick {{ last?.tick }} · period {{ last?.period }} · danger {{ last?.danger }} · rate {{ last?.debug?.initiative?.rate }} · home share {{ last?.debug?.initiative?.home_share }}</div>
          <div v-for="(a, i) in lastAttacks" :key="i">{{ a.team }} {{ a.plan }}{{ a.counter ? ' (counter)' : '' }} → {{ a.result }} · {{ a.phases.map((p: any) => `${p.n}:${p.p ?? '-'}${p.ok ? '✓' : '✗'}`).join(' ') }}</div>
          <div>home tactics {{ JSON.stringify(teams.home.tactics) }}</div>
          <div>away tactics {{ JSON.stringify(teams.away.tactics) }}</div>
        </section>
      </div>

      <aside class="row-start-2 flex min-w-0 flex-col gap-3 lg:col-start-2 lg:row-span-2 lg:row-start-1">
        <section class="flex flex-col gap-3 rounded-xl bg-surface p-3" aria-label="لوحة المدرب">
          <div class="flex items-center gap-2">
            <h2 class="flex-1 font-display text-base font-bold">لوحة المدرب<span v-if="mine"> · {{ view.clubs[mine].name }}</span></h2>
            <div v-if="!live && view.control.home === 'me' && view.control.away === 'me'" class="flex gap-1 rounded-md bg-surface-sunk p-1">
              <button v-for="s in (['home', 'away'] as const)" :key="s" type="button" class="h-9 rounded-sm px-2 text-xs font-bold" :class="mine === s ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="chosen = s">{{ view.clubs[s].code }}</button>
            </div>
            <span v-if="mine" class="text-xs text-text-muted">التبديلات <b class="font-numbers text-base text-text" dir="ltr">{{ teams[mine].subs_used }}/{{ teams[mine].subs_max }}</b></span>
          </div>

          <p v-if="!mine" class="text-sm text-text-muted">الحاسوب يدير الفريقين. اختر "أنا" لأحدهما في شاشة الإعداد لتديره.</p>

          <template v-else>
            <div role="tablist" class="grid grid-cols-4 gap-1 rounded-md bg-surface-sunk p-1">
              <button v-for="t in tabs" :key="t.id" type="button" role="tab" :aria-selected="tab === t.id" class="h-10 rounded-sm text-sm font-bold" :class="tab === t.id ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="tab = t.id">{{ t.label }}</button>
            </div>

            <div v-if="tab === 'quick'" class="grid grid-cols-2 gap-2">
              <button v-for="q in quickOrders" :key="q.label" type="button" class="flex min-h-16 flex-col gap-0.5 rounded-md border border-text/10 bg-surface-sunk px-3 py-2 text-start hover:border-gold" :disabled="finished" @click="sendTactics(q.label, q.tactics)">
                <span class="font-display text-sm font-bold">{{ q.label }}</span>
                <span class="text-xs leading-5 text-text-muted">{{ q.hint }}</span>
              </button>
            </div>

            <div v-if="tab === 'subs'" class="flex flex-col gap-2">
              <span class="text-xs text-text-muted">{{ subOut ? 'اختر البديل' : 'اختر من يخرج (الأقل لياقة أولاً)' }}</span>
              <button v-for="p in subOut ? bench : onPitch" :key="p.id" type="button" class="flex min-h-11 items-center gap-2 rounded-md px-2" :class="subOut?.id === p.id ? 'bg-warning/15' : 'bg-surface-sunk hover:bg-surface-raised'" @click="subOut ? sendSub(p) : (subOut = p)">
                <span class="w-8 rounded-sm px-1 text-center text-xs font-bold" :class="lineClass(p.line)">{{ p.pos }}</span>
                <span class="flex-1 truncate text-start text-sm">{{ p.name }}</span>
                <span v-if="p.yc" class="h-3.5 w-2.5 rounded-[2px] bg-[#F5D90A]" aria-label="بطاقة صفراء" />
                <span class="w-12 text-start font-numbers" :class="fitClass(p.fit)">{{ subOut ? p.ovr : p.fit + '%' }}</span>
              </button>
              <button v-if="subOut" type="button" class="h-10 rounded-md bg-surface-raised text-sm" @click="subOut = null">رجوع</button>
            </div>

            <div v-if="tab === 'tactics'" class="flex flex-col gap-3 text-sm">
              <label class="flex items-center justify-between gap-2">خطة اللعب
                <select v-model="draft.plan" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="p in plans" :key="p.v" :value="p.v">{{ p.label }}</option></select>
              </label>
              <label class="flex items-center justify-between gap-2">قطع الكرة
                <select v-model.number="draft.tackling" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="(t, i) in tackles" :key="t" :value="i">{{ t }}</option></select>
              </label>
              <label v-for="k in (['pressing', 'style', 'tempo'] as const)" :key="k" class="flex flex-col gap-1">
                <span class="flex justify-between"><span>{{ sliderLabels[k] }}</span><b class="font-numbers text-gold">{{ draft[k] }}</b></span>
                <input v-model.number="draft[k]" type="range" min="0" max="100" class="accent-gold" />
              </label>
              <label v-for="l in (['att', 'mid', 'def'] as const)" :key="l" class="flex items-center justify-between gap-2">{{ lineNames[l] }}
                <select v-model="draft[l]" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="o in positioning[l]" :key="o.v" :value="o.v">{{ o.label }}</option></select>
              </label>
              <div class="flex gap-2">
                <label class="flex flex-1 items-center gap-2"><input v-model="draftTrap" type="checkbox" class="size-5 accent-gold" /> مصيدة التسلل</label>
                <label class="flex flex-1 items-center gap-2"><input v-model="draftMan" type="checkbox" class="size-5 accent-gold" /> رقابة رجل لرجل</label>
              </div>
              <button type="button" class="h-11 rounded-md bg-gold font-display font-bold text-on-gold" :disabled="finished" @click="applyDraft">طبّق في الدقيقة التالية</button>
            </div>

            <div v-if="tab === 'shape'" class="flex flex-wrap gap-2">
              <button v-for="f in view.formations" :key="f" type="button" class="h-11 rounded-md border px-3 font-numbers text-lg" :class="teams[mine].formation === f ? 'border-gold bg-gold/15 text-gold' : 'border-text/10 bg-surface-sunk'" dir="ltr" :disabled="finished" @click="sendFormation(f)">{{ f }}</button>
            </div>

            <div v-for="o in pending" :key="o.key" class="flex items-center gap-3 rounded-lg border border-gold/45 bg-gold/10 px-3 py-2 text-sm">
              <span class="flex-1"><b>{{ o.label }}</b></span><span class="text-gold">يُطبق في الدقيقة القادمة</span>
            </div>
            <div v-for="o in applied" :key="o.key" class="rounded-lg border border-success/50 bg-success/15 px-3 py-2 text-sm"><b>{{ o.label }}</b> طُبّق في الدقيقة {{ o.minute }}</div>
            <div v-for="r in rejected" :key="r" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-[#FF8A8A]">{{ r }}</div>
          </template>
        </section>

        <section class="flex max-h-[420px] flex-col gap-1 overflow-y-auto rounded-xl bg-surface p-3" aria-label="مجريات المباراة">
          <h2 class="mb-1 font-display text-base font-bold">مجريات المباراة</h2>
          <div v-for="(f, i) in feed" :key="i" class="flex gap-3 border-b border-text/5 py-2 text-sm">
            <span class="w-10 shrink-0 font-numbers text-base" :class="f.important ? 'text-gold' : 'text-text-muted'">{{ f.minute }}</span>
            <span :class="f.important ? 'font-bold' : ''">{{ f.text }}</span>
          </div>
        </section>
      </aside>
    </div>
  </main>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref, shallowRef } from 'vue'
import { useRoute } from 'vue-router'
import PitchCanvas from '../match/PitchCanvas.vue'
import Momentum from '../components/Momentum.vue'
import StatsGrid from '../components/StatsGrid.vue'
import { clubColors, sim, type MatchView, type Side, type TeamPlayer, type TeamSnapshot, type Tick, type Tactics } from '../api/sim'
import { line } from '../match/commentary'
import { MatchSound } from '../match/sound'

const props = defineProps<{ id: string }>()
const route = useRoute()

const view = ref<MatchView | null>(null)
const teams = ref<Record<Side, TeamSnapshot>>({} as any)
const score = ref({ home: 0, away: 0 })
const shootout = ref<{ home: number; away: number } | null>(null)
const minute = ref<[number, number]>([0, 0])
const last = shallowRef<Tick | null>(null)
const momentum = ref<number[]>([])
const feed = ref<{ minute: string; text: string; important: boolean }[]>([])
const goal = ref<{ text: string; color: string } | null>(null)
const phaseText = ref('')
const error = ref('')
const playing = ref(true)
const speed = ref(Number(route.query.speed) || 1)
const halftime = ref(false)
const halftimeLeft = ref(30)
const finished = ref(false)
const skipping = ref(false)
const dev = ref(false)
const soundOn = ref(false)
const pitch = ref<InstanceType<typeof PitchCanvas>>()
const sound = new MatchSound()

const buffer: Tick[] = []
let fetching = false
let timer = 0
let htTimer = 0

const minuteText = computed(() => (minute.value[1] ? `${minute.value[0]}+${minute.value[1]}'` : `${minute.value[0]}'`))
const kits = computed(() => {
  const h = clubColors(view.value?.clubs.home ?? ({} as any))
  const a = clubColors(view.value?.clubs.away ?? ({} as any))
  const clash = h.primary.toLowerCase() === a.primary.toLowerCase()
  const textOn = (hex: string) => (parseInt(hex.slice(1, 3), 16) * 299 + parseInt(hex.slice(3, 5), 16) * 587 + parseInt(hex.slice(5, 7), 16) * 114) / 1000 > 150 ? '#0A1F42' : '#FFFFFF'
  const away = clash ? a.secondary : a.primary
  return { home: h.primary, homeText: textOn(h.primary), away, awayText: textOn(away) }
})
const pitchPlayers = computed(() => {
  const out: Record<string, { no: number; side: Side; gk: boolean }> = {}
  for (const side of ['home', 'away'] as Side[]) for (const p of teams.value[side]?.players ?? []) out[p.id] = { no: p.no, side, gk: p.slot_line === 'gk' }
  return out
})
const nameOf = (side: Side, id?: number) => teams.value[side]?.players.find((p) => p.id === id)?.name ?? ''
const clubName = (side: Side) => view.value?.clubs[side].name ?? ''

// ---------------------------------------------------------------- coach
const chosen = ref<Side | null>(null)
const mine = computed<Side | null>(() => {
  const c = view.value?.control
  if (!c) return null
  if (view.value?.mode === 'live') return route.query.side === 'away' ? 'away' : 'home'
  if (c.home === 'me' && c.away === 'me') return chosen.value ?? 'home'
  return c.home === 'me' ? 'home' : c.away === 'me' ? 'away' : null
})
const tabs = [{ id: 'quick', label: 'سريع' }, { id: 'subs', label: 'تبديل' }, { id: 'tactics', label: 'تكتيك' }, { id: 'shape', label: 'الطريقة' }] as const
const tab = ref<(typeof tabs)[number]['id']>('quick')
const plans = [{ v: 'passing', label: 'تمريرات' }, { v: 'wings', label: 'الأجنحة' }, { v: 'counter', label: 'هجوم مرتد' }, { v: 'long', label: 'كرات طويلة' }, { v: 'shots', label: 'تسديد من بعيد' }]
const tackles = ['قانوني', 'عادي', 'حماس', 'خشونة']
const sliderLabels = { pressing: 'الضغط على الخصم', style: 'الأسلوب (دفاعي إلى هجومي)', tempo: 'إيقاع اللعب' }
const lineNames = { att: 'المهاجمون', mid: 'الوسط', def: 'المدافعون' }
const positioning = {
  att: [{ v: 'back', label: 'ارتداد' }, { v: 'support', label: 'مساندة الوسط' }, { v: 'only', label: 'هجوم فقط' }],
  mid: [{ v: 'def', label: 'مساندة الدفاع' }, { v: 'stay', label: 'بقاء' }, { v: 'push', label: 'اندفاع' }],
  def: [{ v: 'stay', label: 'بقاء' }, { v: 'fullbacks', label: 'هجوم الظهيرين' }, { v: 'mid', label: 'مساندة الوسط' }],
}
const initial = ref<Tactics | null>(null)
const quickOrders = computed<{ label: string; hint: string; tactics: Partial<Tactics> }[]>(() => [
  { label: 'هجوم كامل', hint: 'أسلوب هجومي، إيقاع عالٍ، الظهيران يتقدمان', tactics: { style: 85, tempo: 70, def: 'fullbacks', att: 'only' } },
  { label: 'تأمين النتيجة', hint: 'دفاع متأخر، إيقاع هادئ، مهاجمون يرتدون', tactics: { style: 25, tempo: 30, mid: 'def', att: 'back', def: 'stay' } },
  { label: 'ضغط عالٍ', hint: 'الضغط 85 ومصيدة التسلل: لياقة أسرع', tactics: { pressing: 85, trap: 1 } },
  { label: 'إبطاء اللعب', hint: 'إيقاع 25 وتمريرات: نحتفظ بالكرة', tactics: { tempo: 25, plan: 'passing' } },
  { label: 'استغلال الأطراف', hint: 'خطة الأجنحة وهجوم الظهيرين', tactics: { plan: 'wings', def: 'fullbacks' } },
  { label: 'عودة للخطة', hint: 'تكتيك ما قبل المباراة', tactics: initial.value ?? {} },
])
const draft = reactive<Tactics>({} as Tactics)
const draftTrap = computed({ get: () => draft.trap === 1, set: (v) => (draft.trap = v ? 1 : 0) })
const draftMan = computed({ get: () => draft.marking === 'man', set: (v) => (draft.marking = v ? 'man' : 'zone') })
const onPitch = computed(() => (mine.value ? [...teams.value[mine.value].players].filter((p) => p.on).sort((a, b) => a.fit - b.fit) : []))
const bench = computed(() => (mine.value ? teams.value[mine.value].players.filter((p) => !p.on && p.out === '' && p.slot === null) : []))
const subOut = ref<TeamPlayer | null>(null)
const pending = ref<{ key: string; label: string; target: number }[]>([])
const applied = ref<{ key: string; label: string; minute: string }[]>([])
const rejected = ref<string[]>([])

const lineClass = (l: string) => ({ gk: 'bg-line-gk text-line-gk-fg', def: 'bg-line-def text-line-def-fg', mid: 'bg-line-mid text-line-mid-fg', att: 'bg-line-att text-line-att-fg' })[l] ?? ''
const fitClass = (f: number) => (f >= 75 ? 'text-success' : f >= 60 ? 'text-gold' : 'text-warning')

async function order(label: string, body: Record<string, unknown>) {
  if (!mine.value || finished.value) return
  try {
    const r = await sim.order(props.id, { team: mine.value, ...body })
    pending.value.push({ key: crypto.randomUUID(), label, target: r.target_tick })
  } catch (e: any) {
    error.value = e.message
  }
}
const sendTactics = (label: string, tactics: Partial<Tactics>) => order(label, { type: 'tactics', tactics })
const sendFormation = (f: string) => order(`الطريقة ${f}`, { type: 'formation', formation: f })
function sendSub(p: TeamPlayer) {
  const out = subOut.value!
  subOut.value = null
  order(`${p.name} بدلاً من ${out.name}`, { type: 'sub', out: out.id, in: p.id })
}
function applyDraft() {
  const cur = teams.value[mine.value!].tactics as any
  const changes = Object.fromEntries(Object.entries(draft).filter(([k, v]) => cur[k] !== v))
  if (Object.keys(changes).length) sendTactics('تعديل التكتيك', changes as Partial<Tactics>)
}

// ---------------------------------------------------------------- clock
function tickMs(t?: Tick) {
  const timing = view.value!.timing
  return ((t && t.period >= 3 ? timing.extra_time_tick_ms : timing.tick_ms) || 3000) / (live.value ? 1 : speed.value)
}

async function fetchNext(count = 1) {
  if (fetching || finished.value) return
  fetching = true
  try {
    const res = await sim.ticks(props.id, count)
    buffer.push(...res.ticks)
  } catch (e: any) {
    error.value = e.message
  } finally {
    fetching = false
  }
}

function schedule(ms: number) {
  clearTimeout(timer)
  timer = window.setTimeout(step, ms)
}

async function step() {
  if (!playing.value || halftime.value || finished.value) return
  if (!buffer.length) {
    await fetchNext()
    if (!buffer.length) return schedule(500)
  }
  const t = buffer.shift()!
  show(t)
  if (!t.finished && buffer.length === 0) fetchNext()
  if (!halftime.value && !finished.value) schedule(tickMs(t))
}

function show(t: Tick, animate = true) {
  last.value = t
  minute.value = t.minute
  score.value = t.score
  if (t.teams) teams.value = t.teams
  momentum.value = [...momentum.value, t.danger]
  if (animate) pitch.value?.play(t.frames, tickMs(t) * 0.95)
  sound.danger(t.danger)
  const att = [...t.events].reverse().find((e) => e.type === 'attack')
  phaseText.value = att ? `هجمة ${clubName(att.team as Side)}${att.counter ? ' مرتدة' : ''}` : ''

  for (const e of t.events) {
    const text = line(e, nameOf, clubName)
    const important = ['goal', 'card', 'penalty', 'period', 'sub'].includes(e.type)
    if (text) feed.value.unshift({ minute: minuteText.value, text, important })
    if (e.type === 'goal') {
      const color = e.team === 'home' ? kits.value.home : kits.value.away
      goal.value = { text: `${nameOf(e.team as Side, e.scorer)} ${minuteText.value}${e.assist ? ` · صناعة ${nameOf(e.team as Side, e.assist)}` : ''}`, color }
      window.setTimeout(() => (goal.value = null), Math.max(1200, 2600 / speed.value))
      sound.kick(true)
      sound.roar()
    } else if (e.type === 'attack' && ['saved', 'missed'].includes(e.result)) {
      sound.kick(true)
      sound.groan()
    } else if (e.type === 'card' || e.type === 'foul' || (e.type === 'attack' && e.result === 'offside')) {
      sound.whistle()
    } else if (e.type === 'period') {
      sound.whistle(e.name === 'fulltime' ? 3 : 2)
      if (e.name === 'halftime' && animate) startHalftime()
    } else if (e.type === 'shootout') {
      shootout.value = e.score
    }
  }
  for (const p of pending.value.filter((o) => t.tick >= o.target)) {
    applied.value.unshift({ key: p.key, label: p.label, minute: minuteText.value })
    window.setTimeout(() => (applied.value = applied.value.filter((a) => a.key !== p.key)), 4000)
  }
  pending.value = pending.value.filter((o) => t.tick < o.target)
  rejected.value = t.rejected.map((r) => `رُفض الأمر: ${({ no_subs_left: 'لا تبديلات متبقية', bad_players: 'اللاعب غير متاح', bad_tactics: 'تكتيك غير صالح', bad_formation: 'طريقة غير صالحة' } as Record<string, string>)[r.reason] ?? r.reason}`)
  if (t.finished) finished.value = true
  if (draft.plan === undefined && mine.value && teams.value[mine.value]) {
    Object.assign(draft, teams.value[mine.value].tactics)
    initial.value ??= { ...teams.value[mine.value].tactics }
  }
}

function startHalftime() {
  halftime.value = true
  if (live.value) {
    clearInterval(htTimer)
    htTimer = window.setInterval(() => (halftimeLeft.value = Math.max(0, halftimeLeft.value - 1)), 1000)
    return
  }
  halftimeLeft.value = Math.round((view.value!.timing.halftime_seconds || 30) / speed.value)
  clearInterval(htTimer)
  htTimer = window.setInterval(() => {
    halftimeLeft.value--
    if (halftimeLeft.value <= 0) endHalftime()
  }, 1000)
}

function endHalftime() {
  clearInterval(htTimer)
  halftime.value = false
  schedule(200)
}

function togglePlay() {
  playing.value = !playing.value
  if (playing.value) schedule(100)
  else clearTimeout(timer)
}

async function skip() {
  skipping.value = true
  clearTimeout(timer)
  halftime.value = false
  clearInterval(htTimer)
  try {
    while (!finished.value) {
      const res = await sim.ticks(props.id, 200)
      buffer.push(...res.ticks)
      while (buffer.length) show(buffer.shift()!, false)
      if (!res.ticks.length) break
    }
  } catch (e: any) {
    error.value = e.message
  } finally {
    skipping.value = false
  }
}

// ---------------------------------------------------------------- live (two devices)
// The server keeps the clock; each screen polls it and plays the minutes as they come.
const live = computed(() => view.value?.mode === 'live')
const started = ref(true)
const starting = ref(false)
const countdown = ref(0)
const copied = ref(false)
const other = computed<Side>(() => (mine.value === 'away' ? 'home' : 'away'))
const friendLink = computed(() => `${location.origin}/sim/${props.id}?side=${other.value}`)
let seen = 0
let pollTimer = 0

async function share() {
  try {
    if (navigator.share) await navigator.share({ title: 'Legends', text: 'أدر فريقك في مباراتنا', url: friendLink.value })
    else await navigator.clipboard.writeText(friendLink.value)
    copied.value = true
    window.setTimeout(() => (copied.value = false), 2000)
  } catch {
    /* the user closed the share sheet */
  }
}

async function startLive() {
  starting.value = true
  try {
    handleSync(await sim.start(props.id))
  } catch (e: any) {
    error.value = e.message
  } finally {
    starting.value = false
  }
}

async function poll() {
  clearTimeout(pollTimer)
  if (finished.value) return
  let wait = 1500
  try {
    wait = handleSync(await sim.live(props.id, seen))
  } catch (e: any) {
    error.value = e.message
  }
  if (!finished.value) pollTimer = window.setTimeout(poll, wait)
}

/** Plays new minutes and returns how long to wait before asking again. */
function handleSync(r: import('../api/sim').LiveSync): number {
  started.value = r.started
  const fresh = r.ticks.filter((t) => t.tick > seen)
  // Behind (a slow phone, a locked screen): jump without animation, play only the last minute.
  fresh.forEach((t, i) => {
    show(t, i === fresh.length - 1)
    seen = t.tick
  })
  if (r.tick > seen) seen = r.tick
  if (fresh.length && halftime.value && !fresh.some((t) => t.events.some((e) => e.type === 'period' && e.name === 'halftime'))) {
    halftime.value = false
    clearInterval(htTimer)
  }
  const left = r.next_at === null ? 1500 : r.next_at - r.server_now
  countdown.value = r.started && r.tick === 0 && left > 0 ? Math.ceil(left / 1000) : 0
  if (halftime.value) halftimeLeft.value = Math.max(0, Math.ceil(left / 1000))
  return Math.min(1500, Math.max(250, left + 60))
}

function toggleSound() {
  sound.start()
  soundOn.value = !soundOn.value
  sound.setMuted(!soundOn.value)
  if (soundOn.value) sound.whistle()
}

onMounted(async () => {
  try {
    view.value = await sim.show(props.id)
    teams.value = view.value.teams
    score.value = view.value.score
    if (mine.value) {
      Object.assign(draft, teams.value[mine.value].tactics)
      initial.value = { ...teams.value[mine.value].tactics }
    }
    finished.value = view.value.finished
    if (live.value) {
      started.value = view.value.started
      seen = view.value.tick
      return poll()
    }
    await fetchNext()
    schedule(1200)
  } catch (e: any) {
    error.value = e.message
  }
})

onBeforeUnmount(() => {
  clearTimeout(timer)
  clearTimeout(pollTimer)
  clearInterval(htTimer)
  sound.stop()
})

const lastAttacks = computed(() => (last.value?.events ?? []).filter((e) => e.type === 'attack'))
</script>
