<script setup lang="ts">
// The next match (Sprint 17 W1): when and where, the referee once drawn, and the countdown to the lock.
// After the lock: my frozen sheet (and who came in for an injured starter), and the opponent's eleven,
// formation and the four tactics he may be seen with. The live match comes in Sprints 18 to 20.
// Before the lock: the spy (Sprint 30, docs/features/spy.md), a paid look at what the opponent has saved now.
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components, paths } from '../../api/schema'
import Icon from '../../components/Icon.vue'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import RatingRing from '../../components/ui/RatingRing.vue'
import PriceTag from '../../components/ui/PriceTag.vue'
import UiChip from '../../components/ui/UiChip.vue'
import TicketsPanel from './TicketsPanel.vue'
import IntegrityPanel from './IntegrityPanel.vue'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'

type Match = NonNullable<paths['/leagues/{league}/team/next-match']['get']['responses'][200]['content']['application/json']['match']>
const match = ref<Match | null>(null)
const loaded = ref(false)
const error = ref('')
const now = ref(Date.now())
const leagueId = ref<number | null>(null)

const REFEREE: Record<string, string> = { lenient: 'متساهل', medium: 'متوسط', strict: 'صارم' }
const PLANS: Record<string, string> = { counter: 'هجوم مرتد', shots: 'تسديد عن بعد', long: 'كرات طويلة', passing: 'تمريرات', wings: 'لعب على الأجنحة' }
const TACKLING = ['قانوني', 'عادي', 'حماس', 'خشونة']
const when = (iso: string) => new Intl.DateTimeFormat('ar-EG-u-nu-latn', { weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

function left(iso: string) {
  const s = Math.max(0, Math.floor((Date.parse(iso) - now.value) / 1000))
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`
}
const locked = computed(() => match.value?.status !== 'scheduled')
const spy = ref<components['schemas']['SpyView'] | null>(null)
const spying = ref(false)
const FORM: Record<string, [string, string]> = { W: ['ف', 'bg-success text-on-gold'], D: ['ت', 'bg-white/20'], L: ['خ', 'bg-live text-white'] }
const spiedAt = (iso: string) => new Intl.DateTimeFormat('ar-EG-u-nu-latn', { hour: '2-digit', minute: '2-digit' }).format(new Date(iso))
async function sendSpy() {
  spying.value = true
  error.value = ''
  try {
    await ensureCsrf()
    spy.value = (await api.POST('/leagues/{league}/spy', { params: { path: { league: leagueId.value! } } })).data!
    useWallet().load()
  } catch (e) {
    error.value = asApiError(e).message
  }
  spying.value = false
}

let timer = 0
onMounted(async () => {
  timer = window.setInterval(() => (now.value = Date.now()), 1000)
  try {
    leagueId.value = await currentLeague()
    if (leagueId.value) {
      const path = { params: { path: { league: leagueId.value } } }
      const [m, sp] = await Promise.all([api.GET('/leagues/{league}/team/next-match', path), api.GET('/leagues/{league}/spy', path)])
      match.value = m.data!.match ?? null
      spy.value = sp.data!
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
})
onBeforeUnmount(() => window.clearInterval(timer))
const ACTIONS = [
  { name: 'lineup', label: 'التشكيلة', icon: 'lineup' },
  { name: 'tactics', label: 'التكتيك', icon: 'tactics' },
  { name: 'training', label: 'التدريب', icon: 'training' },
] as const
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="font-display text-3xl font-extrabold">المباراة القادمة</h1>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-else-if="loaded && !leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>
    <p v-else-if="loaded && !match" class="rounded-xl bg-surface p-6 text-text-muted">لا مباريات قادمة الآن.</p>
    <template v-else-if="match">
      <!-- [X32] The VS dashboard: a blue band with the competition, both clubs on silver discs with their strength in a
           ring, the countdown to the lock between them, then the facts and the action cards. -->
      <section class="overflow-hidden rounded-xl bg-surface">
        <div class="vs-band flex items-center justify-center gap-2 px-4 py-2 text-sm font-extrabold text-white">
          {{ match.competition === 'cup' ? 'الكأس' : match.competition === 'alliance' ? `بطولة التحالفات · الدور ${match.round}` : `الجولة ${match.round}` }}{{ match.slot === 2 ? ' · السهرة' : '' }}
          <span class="rounded bg-black/25 px-2 py-0.5 text-xs">{{ match.venue === 'home' ? 'على أرضك' : 'خارج أرضك' }}</span>
        </div>
        <div class="relative isolate px-3 pb-4 pt-5 md:px-8">
          <img src="/art/stadium-banner.svg" alt="" aria-hidden="true" class="absolute inset-0 -z-10 size-full object-cover object-[50%_75%] opacity-40" />
          <div class="absolute inset-0 -z-10 bg-gradient-to-b from-transparent to-panel" aria-hidden="true" />
          <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-2 md:gap-6">
            <div v-for="(side, i) in [match.club, match.opponent]" :key="i" class="flex flex-col items-center gap-2 text-center" :class="i === 1 ? 'order-last' : ''">
              <span class="vs-disc"><ClubCrest :url="side.crest_url" :code="side.code" :size="64" /></span>
              <b class="line-clamp-1 font-display text-base md:text-2xl">{{ side.name }}</b>
              <span class="text-xs text-text-muted">{{ i === 0 ? 'فريقك' : match.opponent.coach ?? 'الحاسوب' }}</span>
              <RatingRing :value="Math.round(side.strength_cp / 100)" label="القوة" :color="i === 0 ? 'var(--color-gold)' : 'var(--color-ring)'" :size="60" />
            </div>
            <div class="flex flex-col items-center gap-1">
              <span class="font-display text-4xl font-extrabold italic text-white drop-shadow md:text-6xl">VS</span>
              <span class="text-[11px] font-bold text-text-muted">{{ locked ? 'مقفلة' : 'يُقفل بعد' }}</span>
              <span class="rounded-lg bg-black/40 px-3 py-1 font-numbers text-xl font-bold text-ring md:text-2xl" dir="ltr">{{ locked ? '🔒' : left(match.lock_at) }}</span>
            </div>
          </div>
        </div>
        <div class="flex flex-col gap-3 p-4 pt-0">
          <dl class="grid grid-cols-3 gap-2 text-center text-sm">
            <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-xs text-text-muted">الموعد</dt><dd class="font-bold">{{ when(match.scheduled_at) }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-xs text-text-muted">المعنويات</dt><dd class="font-numbers text-lg font-bold" :class="match.morale >= 75 ? 'text-success' : match.morale < 50 ? 'text-[#FF8A8A]' : 'text-gold'">{{ match.morale }}</dd></div>
            <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-xs text-text-muted">الحكم</dt><dd class="font-bold">{{ match.referee ? REFEREE[match.referee] : 'قبلها بنصف ساعة' }}</dd></div>
          </dl>
          <p v-if="match.match_of_day" class="rounded-lg bg-gold/15 px-3 py-2 text-center text-sm font-bold text-gold">⭐ قمة الجولة: كل مدربي الدوري مدعوون لمشاهدتها الليلة</p>
          <RouterLink
            v-if="match.status === 'live' && match.match_id"
            :to="{ name: 'league-match', params: { id: match.match_id } }"
            class="flex h-12 items-center justify-center gap-2 rounded-lg bg-live font-display font-extrabold text-white"
          ><span class="size-2 animate-pulse rounded-full bg-white" />تابع المباراة مباشرة</RouterLink>
          <!-- The action cards: what to prepare before the lock. -->
          <div v-if="!locked" class="grid grid-cols-3 gap-2">
            <RouterLink v-for="c in ACTIONS" :key="c.name" :to="{ name: c.name }" class="action-card">
              <span class="grid size-11 place-items-center rounded-full bg-brand text-white shadow-md"><Icon :name="c.icon" /></span>
              <b class="text-sm">{{ c.label }}</b>
            </RouterLink>
          </div>
          <p class="text-xs text-text-muted">{{ match.slot === 2
            ? 'جولتك على فترتين ومباراتك في السهرة: تُقفل تشكيلات الجولة وتكتيكاتها كلها معاً قبل الفترة الأولى، ويُجمَّد الفريق كما هو عند القفل حتى صافرتك.'
            : 'قبل المباراة بخمس دقائق تُقفل التشكيلة والتكتيك، ويُستبدل أي مصاب أو موقوف تلقائياً بأفضل بديل.' }}</p>
        </div>
      </section>

      <section v-if="match.mine?.fixes?.length" class="rounded-xl bg-warning/15 p-4 text-sm">
        <h2 class="mb-1 font-bold">تصحيح تلقائي عند القفل</h2>
        <p v-for="(f, i) in match.mine.fixes" :key="i">دخل {{ f.in_name }} بدل {{ f.out_name ?? 'خانة فارغة' }}.</p>
      </section>

      <section v-if="match.opponent.sheet" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
        <h2 class="font-display text-xl font-extrabold">تشكيلة الخصم <span class="font-numbers text-base text-text-muted" dir="ltr">{{ match.opponent.sheet.formation.replace(/([AB])$/, ' $1') }}</span></h2>
        <div class="flex flex-wrap gap-2 text-sm">
          <UiChip>{{ PLANS[match.opponent.sheet.tactics.plan] }}</UiChip>
          <UiChip>قطع الكرة: {{ TACKLING[match.opponent.sheet.tactics.tackling] }}</UiChip>
          <UiChip>{{ match.opponent.sheet.tactics.marking === 'man' ? 'رجل لرجل' : 'دفاع منطقة' }}</UiChip>
          <UiChip v-if="match.opponent.sheet.tactics.trap">مصيدة التسلل</UiChip>
        </div>
        <ol class="grid grid-cols-2 gap-1 text-sm">
          <li v-for="p in match.opponent.sheet.starters" :key="p.id" class="truncate rounded bg-surface-sunk px-2 py-1">{{ p.name }}</li>
        </ol>
        <p class="text-xs text-text-muted">الضغط والأسلوب والإيقاع والتمركز لا تظهر لأحد غير صاحبها.</p>
      </section>

      <section v-if="spy && !match.opponent.sheet" aria-label="تقرير الجاسوس" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
        <div class="flex flex-wrap items-center gap-2">
          <h2 class="flex-1 font-display text-xl font-extrabold">تقرير الجاسوس</h2>
          <span v-if="spy.report" class="text-xs text-text-muted">كما كانت الساعة <span class="font-numbers" dir="ltr">{{ spiedAt(spy.report.at) }}</span>، وقد يغيّرها الخصم</span>
        </div>
        <template v-if="!spy.report">
          <p class="text-sm text-text-muted">اعرف خطة الخصم وتشكيلته وتكتيكه العلني وفورمته الآن، قبل القفل. لا يعرف أنك تجسست عليه.</p>
          <button type="button" class="h-12 rounded-md bg-gold px-6 font-display font-bold text-on-gold disabled:opacity-40" :disabled="spying || locked" @click="sendSpy">
            أرسل جاسوساً · <PriceTag :amount="spy.cost" :currency="spy.currency" /></button>
        </template>
        <template v-else>
          <div class="flex flex-wrap items-center gap-2">
            <UiChip><span dir="ltr">{{ spy.report.formation.replace(/([AB])$/, ' $1') }}</span></UiChip>
            <UiChip>{{ PLANS[spy.report.tactics.plan] }}</UiChip>
            <UiChip>قطع الكرة: {{ TACKLING[spy.report.tactics.tackling] }}</UiChip>
            <UiChip>{{ spy.report.tactics.marking === 'man' ? 'رجل لرجل' : 'دفاع منطقة' }}</UiChip>
            <UiChip v-if="spy.report.tactics.trap">مصيدة التسلل</UiChip>
            <UiChip v-if="spy.report.fitness !== null">لياقة الأحد عشر <span class="font-numbers" dir="ltr">{{ spy.report.fitness }}%</span></UiChip>
          </div>
          <div class="flex items-center gap-1.5 text-sm"><span class="text-text-muted">آخر النتائج</span>
            <span v-for="(r, i) in spy.report.form" :key="i" class="grid size-7 place-items-center rounded-full text-xs font-bold" :class="FORM[r]![1]">{{ FORM[r]![0] }}</span>
            <span v-if="!spy.report.form.length" class="text-text-muted">لم يلعب بعد</span>
          </div>
          <ol class="grid gap-1 text-sm sm:grid-cols-2">
            <li v-for="p in spy.report.starters" :key="p.id" class="flex items-center gap-2 rounded bg-surface-sunk px-2 py-1">
              <span class="w-9 text-xs text-text-muted" dir="ltr">{{ p.position }}</span><span class="min-w-0 flex-1 truncate"><bdi>{{ p.name }}</bdi></span><b class="font-numbers">{{ p.overall }}</b></li>
          </ol>
          <div class="flex flex-wrap items-center gap-1.5 text-sm"><span class="text-text-muted">البدلاء</span>
            <span v-for="p in spy.report.bench" :key="p.id" class="rounded-full bg-surface-sunk px-2.5 py-1 text-xs"><bdi>{{ p.name }}</bdi></span></div>
        </template>
      </section>
    </template>
    <IntegrityPanel v-if="leagueId" :league-id="leagueId" />
    <TicketsPanel v-if="leagueId" :league-id="leagueId" />
    <p v-if="!loaded" class="text-text-muted">جارٍ التحميل…</p>
  </div>
</template>

<style scoped>
.vs-band {
  background: linear-gradient(180deg, var(--color-brand), var(--color-brand-dark));
}
/* The crest on a silver disc, as on a broadcast's match card. */
.vs-disc {
  display: grid;
  place-items: center;
  width: 5.5rem;
  height: 5.5rem;
  border-radius: 999px;
  background: radial-gradient(circle at 50% 30%, #ffffff, var(--color-chrome) 55%, var(--color-chrome-dark));
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--color-brand-light) 60%, transparent), 0 12px 26px -10px rgb(0 0 0 / 0.8);
}
.action-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  min-height: 6rem;
  border-radius: 0.75rem;
  background: linear-gradient(180deg, color-mix(in srgb, var(--color-brand) 22%, transparent), color-mix(in srgb, var(--color-bg-deep) 70%, transparent));
  border: 1px solid color-mix(in srgb, var(--color-brand-light) 30%, transparent);
}
.action-card:hover {
  border-color: var(--color-brand-light);
}
</style>
