<script setup lang="ts">
// The next match (Sprint 17 W1): when and where, the referee once drawn, and the countdown to the lock.
// After the lock: my frozen sheet (and who came in for an injured starter), and the opponent's eleven,
// formation and the four tactics he may be seen with. The live match comes in Sprints 18 to 20.
// Before the lock: the spy (Sprint 30, docs/features/spy.md), a paid look at what the opponent has saved now.
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components, paths } from '../../api/schema'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import PriceTag from '../../components/ui/PriceTag.vue'
import UiChip from '../../components/ui/UiChip.vue'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'
import { strength } from '../../lib/format'

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
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="font-display text-3xl font-extrabold">المباراة القادمة</h1>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-else-if="loaded && !leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>
    <p v-else-if="loaded && !match" class="rounded-xl bg-surface p-6 text-text-muted">لا مباريات قادمة الآن.</p>
    <template v-else-if="match">
      <section class="flex flex-col gap-3 rounded-xl border border-gold/30 bg-surface p-4">
        <div class="flex items-center gap-3">
          <ClubCrest :url="match.opponent.crest_url" :code="match.opponent.code" :size="56" />
          <div class="min-w-0 flex-1">
            <p class="text-sm text-text-muted">{{ match.venue === 'home' ? 'على أرضك ضد' : 'خارج أرضك ضد' }}</p>
            <p class="truncate font-display text-2xl font-extrabold">{{ match.opponent.name }}</p>
            <p class="text-sm text-text-muted">{{ match.opponent.coach ?? 'الحاسوب' }} · القوة <span class="font-numbers">{{ strength(match.opponent.strength_cp) }}</span></p>
          </div>
          <UiChip :tone="match.competition === 'cup' ? 'gold' : 'neutral'">{{ match.competition === 'cup' ? 'الكأس' : `الجولة ${match.round}` }}</UiChip>
        </div>
        <dl class="grid grid-cols-3 gap-2 text-center text-sm">
          <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-text-muted">الموعد</dt><dd class="font-bold">{{ when(match.scheduled_at) }}</dd></div>
          <div class="rounded-lg bg-surface-sunk p-2"><dt class="text-text-muted">الحكم</dt><dd class="font-bold">{{ match.referee ? REFEREE[match.referee] : 'قبلها بنصف ساعة' }}</dd></div>
          <div class="rounded-lg bg-surface-sunk p-2">
            <dt class="text-text-muted">{{ locked ? 'مقفلة' : 'يُقفل بعد' }}</dt>
            <dd class="font-numbers text-lg font-bold text-gold" dir="ltr">{{ locked ? '🔒' : left(match.lock_at) }}</dd>
          </div>
        </dl>
        <p class="text-xs text-text-muted">قبل المباراة بخمس دقائق تُقفل التشكيلة والتكتيك، ويُستبدل أي مصاب أو موقوف تلقائياً بأفضل بديل.</p>
        <RouterLink
          v-if="match.status === 'live' && match.match_id"
          :to="{ name: 'league-match', params: { id: match.match_id } }"
          class="flex h-12 items-center justify-center gap-2 rounded-lg bg-live font-display font-extrabold text-white"
        ><span class="size-2 rounded-full bg-white" />تابع المباراة مباشرة</RouterLink>
        <div v-if="!locked" class="flex gap-2">
          <RouterLink :to="{ name: 'lineup' }" class="flex h-12 flex-1 items-center justify-center rounded-lg bg-gold font-display font-extrabold text-on-gold">التشكيلة</RouterLink>
          <RouterLink :to="{ name: 'tactics' }" class="flex h-12 flex-1 items-center justify-center rounded-lg border border-gold/70 font-display font-extrabold text-gold">التكتيك</RouterLink>
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
    <p v-else class="text-text-muted">جارٍ التحميل…</p>
  </div>
</template>
