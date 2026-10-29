<script setup lang="ts">
// Training (Sprint 27 W1, PLAN 2.8), per the WebTraining and MobileTraining drafts: the four slots with their
// bars and the countdown to the next session, and the candidates of the chosen line. Every number comes from
// the server; the countdown reloads when a session is due. "Finish now" waits for the premium coins.
import AdReward from '../../components/ads/AdReward.vue'
import { useGlossary } from '../../lib/glossary'
import HelpTip from '../../components/ui/HelpTip.vue'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import PriceTag from '../../components/ui/PriceTag.vue'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'
import { count, money, type Line } from '../../lib/format'

type View = components['schemas']['TrainingView']
// The "?" texts [X19].
const g = useGlossary()
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const loaded = ref(false)
const error = ref('')
const notice = ref('')
const busy = ref(false)
const line = ref<Line>('mid')
const now = ref(Date.now())
let skew = 0   // the game clock minus this device's clock (clock:travel in development)
let tick = 0
const LINE_NAMES: Record<string, string> = { gk: 'حارس', def: 'دفاع', mid: 'وسط', att: 'هجوم' }
const candidates = computed(() => {
  const busyIds = new Set(v.value?.slots.map((s) => s.player?.id))
  return (v.value?.players ?? []).filter((p) => p.line === line.value && !busyIds.has(p.id))
    .sort((a, b) => Number(a.maxed) - Number(b.maxed) || (b.potential - b.overall) - (a.potential - a.overall) || a.age - b.age)
})
// [UP8] One player per line in training: while the line's slot is taken, the others of that line wait.
const lineBusy = computed(() => !!v.value?.slots.find((s) => s.line === line.value)?.player)
// [Sprint 21 E6] The chosen line's coach, without whom it does not train.
const lineCoach = computed(() => !!v.value?.slots.find((s) => s.line === line.value)?.coach.hired)
function left(at: string | null | undefined) {
  if (!at) return ''
  const s = Math.max(0, Math.floor((new Date(at).getTime() - now.value) / 1000))
  return [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
}

async function load() {
  try {
    leagueId.value ??= await currentLeague()
    if (leagueId.value) {
      const { data } = await api.GET('/leagues/{league}/training', { params: { path: { league: leagueId.value } } })
      v.value = data!
      skew = new Date(data!.now).getTime() - Date.now()
      now.value = Date.now() + skew
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

async function act(run: () => Promise<{ data?: View }>, done: string) {
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    const { data } = await run()
    v.value = data!
    notice.value = done
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

// Finish a session now for coins [Sprint 34].
const wallet = useWallet()
const finish = (l: string) => act(() => api.POST('/leagues/{league}/training/{line}/finish', { params: { path: { league: leagueId.value!, line: l as Line } } }) as any,
  'انتهت الجلسة الآن.').then(() => wallet.load())

const train = (id: number, name: string) => act(() => api.POST('/leagues/{league}/training', { params: { path: { league: leagueId.value! } }, body: { player_id: id } }) as any,
  `بدأ ${name} التدريب. أول جلسة بعد ${Math.round((v.value?.interval_minutes ?? 0) / 60)} ساعات.`)
const stop = (l: string) => act(() => api.DELETE('/leagues/{league}/training/{line}', { params: { path: { league: leagueId.value!, line: l as Line } } }) as any,
  'فرغت الخانة، واللاعب يحتفظ بتقدمه.')

onMounted(() => {
  load()
  tick = window.setInterval(() => {
    now.value = Date.now() + skew
    if (v.value?.slots.some((s) => s.next_at && new Date(s.next_at).getTime() <= now.value - 2000)) load()
  }, 1000)
})
onBeforeUnmount(() => clearInterval(tick))
// The slot cards' tiers [X29], as the squad's cards.
const tier = (overall: number) => (overall >= 85 ? 'gold' : overall >= 75 ? 'silver' : 'bronze')
const TIER = { gold: 'border-gold/50 from-[#3a2c07] to-[#10284F]', silver: 'border-text/25 from-[#33415a] to-[#10284F]', bronze: 'border-[#B4692A]/40 from-[#3b2414] to-[#10284F]' } as const
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-end gap-3">
      <div class="flex-1">
        <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">{{ $t('التدريب') }}</h1><HelpTip :text="g.training" :label="$t('التدريب')" /></span>
        <p class="mt-1 text-sm text-text-muted">{{ $t('لاعب من كل خط · جلسة كل {v0} ساعات حتى لو كنت غائباً · عند 100% القوة +1 · التدريب مفتوح طوال الموسم: بعد الإمكانية أبطأ، حتى 99', { v0: v ? Math.round(v.interval_minutes / 60) : 8 }) }}</p>
      </div>
      <div v-if="v" class="money-box px-4 py-2 text-end">
        <span class="block text-xs text-text-muted">{{ $t('أموال النادي') }}</span>
        <b class="font-numbers text-xl" dir="ltr">{{ money(v.balance) }}</b>
        <span class="block text-xs text-text-muted">{{ $t('الجلسة') }} <span class="font-numbers" dir="ltr">{{ count(v.cost) }}</span></span>
      </div>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ $t(notice) }}</p>
    <p v-if="!loaded" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">{{ $t('ليس لديك فريق بعد.') }} <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink></p>

    <template v-else-if="v">
      <p v-if="v.balance < v.cost" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t('رصيد النادي لا يكفي جلسة، فالجلسات تفوت حتى يرجع الرصيد.') }}</p>

      <section :aria-label="$t('خانات التدريب')" class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <!-- Each slot as a card [X29]: its line's colour on top, and a filled slot in its player's tier (gold, silver, bronze). -->
        <article v-for="s in v.slots" :key="s.line" class="relative flex flex-col gap-3 overflow-hidden rounded-xl p-4"
          :class="s.player ? ['border bg-gradient-to-b', TIER[tier(s.player.overall)]] : 'border border-dashed border-white/15 bg-surface/50'">
          <span class="absolute inset-x-0 top-0 h-1" :style="{ background: `var(--color-line-${s.line})` }" aria-hidden="true" />
          <div class="flex items-center gap-2">
            <LineBadge :line="s.line as Line" />
            <span class="text-sm text-text-muted">{{ $t('خانة {v0}', { v0: $t(LINE_NAMES[s.line] ?? '') }) }}</span>
            <span v-if="s.player" class="ms-auto font-numbers text-sm text-gold" dir="ltr" :aria-label="$t('الجلسة التالية بعد')">{{ left(s.next_at) }}</span>
          </div>
          <template v-if="s.player">
            <div class="flex items-center gap-3">
              <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ $nm(s.player.name) }}</bdi></b>
                <span class="text-xs text-text-muted">{{ $t('{v0} · {v1} سنة · الإمكانية {v2}', { v0: s.player.position, v1: s.player.age, v2: s.player.potential }) }}</span></span>
              <span class="text-center"><b class="block font-numbers text-3xl" :class="tier(s.player.overall) === 'gold' ? 'text-gold' : ''">{{ s.player.overall }}</b><span class="font-numbers text-xs text-success" dir="ltr">→ {{ s.player.overall + 1 }}</span></span>
            </div>
            <div>
              <div class="flex justify-between text-xs text-text-muted"><span>{{ $t('التقدم') }}</span><span class="font-numbers" dir="ltr">{{ s.player.progress }}%</span></div>
              <div class="mt-1 h-2 overflow-hidden rounded-full bg-surface-sunk" role="progressbar" :aria-valuenow="s.player.progress" aria-valuemin="0" aria-valuemax="100">
                <div class="h-full rounded-full bg-gold transition-all" :style="{ width: s.player.progress + '%' }" />
              </div>
              <p class="mt-1 text-xs text-text-muted">{{ $t('حوالي {v0} جلسة للـ +1 · {v1} جلسة حتى الآن', { v0: s.player.sessions, v1: s.sessions_done }) }}</p>
            </div>
            <div class="flex gap-2">
              <button type="button" class="h-touch flex-1 rounded-md bg-surface-sunk px-3 text-sm font-bold" @click="line = s.line as Line">{{ $t('اختر لاعباً آخر') }}</button>
              <button v-if="wallet.open(leagueId)" type="button" class="flex h-touch items-center gap-1 rounded-md bg-gold/15 px-3 text-sm font-bold text-gold" :disabled="busy" @click="finish(s.line)"
                :title="$t('أنهِ الجلسة الآن')">{{ $t('الآن ·') }} <PriceTag :amount="wallet.price('finish_training')" currency="coins" /></button>
              <button type="button" class="h-touch rounded-md px-3 text-sm text-text-muted hover:text-text" :disabled="busy" @click="stop(s.line)">{{ $t('إفراغ') }}</button>
            </div>
            <!-- [Sprint 20 S4] A game ad cuts the next session's wait. -->
            <div v-if="leagueId && s.ads.enabled" class="flex flex-wrap items-center gap-2">
              <AdReward :league-id="leagueId" item="training" :line="s.line as Line" :ads="s.ads" @done="load" />
            </div>
          </template>
          <!-- [Sprint 21 E6] No coach for the line, no training: the way to hire him. -->
          <template v-else-if="!s.coach.hired">
            <p class="text-sm text-warning">{{ $t('لا تدريب بلا {v0}.', { v0: s.coach.name }) }}</p>
            <RouterLink :to="{ name: 'specialists' }" class="flex h-touch items-center justify-center rounded-md bg-gold px-4 font-bold text-on-gold">{{ $t('تعاقد معه من الجهاز الفني') }}</RouterLink>
          </template>
          <template v-else>
            <div class="flex items-center justify-between gap-3">
              <p class="text-sm text-text-muted">{{ $t('الخانة فارغة.') }}</p>
              <button type="button" class="h-touch rounded-md bg-brand px-4 font-bold" @click="line = s.line as Line">{{ $t('اختر لاعباً') }}</button>
            </div>
          </template>
        </article>
      </section>

      <section :aria-label="$t('مرشحون للتدريب')" class="flex flex-col gap-2 rounded-xl bg-surface p-3">
        <div class="flex flex-wrap items-center gap-2 px-1">
          <span class="flex flex-wrap items-center gap-1"><h2 class="font-display text-lg font-bold">{{ $t('مرشحون للتدريب') }}</h2><HelpTip :text="g.potential" :label="$t('الإمكانية')" /></span>
          <span class="text-sm text-text-muted">{{ $t('الأصغر سناً يتطور أسرع وسقفه أعلى') }}</span>
          <div class="ms-auto flex gap-1" role="tablist" :aria-label="$t('الخط')">
            <button v-for="(n, k) in LINE_NAMES" :key="k" type="button" role="tab" :aria-selected="line === k" class="h-touch rounded-md px-3 text-sm font-bold"
              :class="line === k ? 'bg-gold text-on-gold' : 'bg-surface-sunk text-text-muted'" @click="line = k as Line">{{ $t(n) }}</button>
          </div>
        </div>
        <div class="hidden grid-cols-[1fr_3rem_3rem_3rem_5rem_6rem] gap-2 px-2 text-xs text-text-muted sm:grid">
          <span>{{ $t('اللاعب') }}</span><span class="text-center">{{ $t('السن') }}</span><span class="text-center">{{ $t('القوة') }}</span><span class="text-center">{{ $t('السقف') }}</span><span class="text-center">{{ $t('جلسات للـ +1') }}</span><span />
        </div>
        <div v-for="p in candidates" :key="p.id" class="grid grid-cols-[1fr_3rem_6rem] items-center gap-2 rounded-lg bg-surface-sunk px-2 py-2 sm:grid-cols-[1fr_3rem_3rem_3rem_5rem_6rem]">
          <span class="min-w-0"><b class="block truncate"><bdi>{{ $nm(p.name) }}</bdi></b><span class="text-xs text-text-muted">{{ p.position }}<template v-if="p.progress"> {{ $t('· التقدم {v0}%', { v0: p.progress }) }}</template><template v-if="p.injured"> {{ $t('· مصاب') }}</template><span class="sm:hidden"> {{ $t('· {v0} سنة · الإمكانية {v1}', { v0: p.age, v1: p.potential }) }}</span></span></span>
          <span class="hidden text-center font-numbers sm:block">{{ p.age }}</span>
          <span class="text-center font-numbers text-lg">{{ p.overall }}</span>
          <span class="hidden text-center font-numbers sm:block" :class="p.over_potential ? 'text-warning' : 'text-success'" :title="p.over_potential ? $t('تجاوز إمكانيته: يتطور أبطأ، حتى 99') : undefined">{{ p.potential }}</span>
          <span class="hidden text-center font-numbers text-text-muted sm:block">~{{ p.sessions }}</span>
          <span v-if="!p.maxed && lineBusy" class="text-center text-xs text-text-muted" :title="$t('لاعب واحد من كل خط في التدريب')">{{ $t('الخانة مشغولة') }}</span>
          <RouterLink v-else-if="!p.maxed && !lineCoach" :to="{ name: 'specialists' }" class="text-center text-xs font-bold text-warning">{{ $t('يلزم مدرب') }}</RouterLink>
          <button v-else-if="!p.maxed" type="button" class="h-touch rounded-md bg-brand px-3 text-sm font-bold disabled:opacity-40" :disabled="busy" @click="train(p.id, p.name)">{{ $t('درّب') }}</button>
          <span v-else class="text-center text-xs text-text-muted">{{ $t('بلغ سقفه') }}</span>
        </div>
        <p v-if="!candidates.length" class="px-1 text-sm text-text-muted">{{ $t('لا لاعبين آخرين في هذا الخط.') }}</p>
      </section>

      <section :aria-label="$t('منشأة التدريب')" class="flex flex-wrap items-center gap-3 rounded-xl bg-surface p-4">
        <div class="flex-1"><b class="block">{{ $t('منشأة التدريب') }}</b><span class="text-sm text-text-muted">{{ $t('كل مرحلة منها تسرّع التقدم في كل الخانات، وتُطوَّر من صفحة الملعب.') }}</span></div>
        <RouterLink :to="{ name: 'stadium' }" class="grid h-touch place-items-center rounded-md bg-surface-sunk px-4 font-bold text-gold">{{ $t('إلى الملعب') }}</RouterLink>
      </section>
    </template>
  </div>
</template>
