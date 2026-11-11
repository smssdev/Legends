<script setup lang="ts">
// [Sprint 20 W5] The club board, the first page of a slot (the owner's approved draft, Sprint20Drafts.html): the next
// match fills its top (both sides, their strength and last five, the countdown, the referee, the lineup and the
// tactics a tap away), then cards that open their screens: training, the mini table, the board's mood, the market,
// the stadium, the money, the friendlies and the quests. Every number from GET /team/summary (B1).
import { computed, onMounted } from 'vue'
import Icon from '../../components/Icon.vue'
import Skeleton from '../../components/ui/Skeleton.vue'
import { countdown, useNow } from '../../lib/clock'
import { REFEREE, money } from '../../lib/format'
import { useBoard } from '../../stores/board'
import { useSlot } from '../../stores/slot'
import { LINE_NAMES, SECTION_NAMES } from '../../components/shell/agenda'

const store = useBoard()
const slot = useSlot()
const now = useNow()
const b = computed(() => store.board)
onMounted(() => store.load(slot.current?.league?.id ?? store.league, true))
const strength = (cp: number) => Math.round(cp / 100)
const FORM: Record<string, [string, string]> = { W: ['ف', 'bg-success text-on-gold'], D: ['ت', 'bg-surface-raised'], L: ['خ', 'bg-live text-white'] }
const MOOD: Record<string, [string, string, string]> = {
  calm: ['هادئة', 'تنتظر بداية الموسم', 'bg-surface-raised text-text-soft'],
  happy: ['مسرورة', 'أنت في الهدف أو أعلى', 'bg-success/20 text-success'],
  worried: ['قلقة', 'أنت تحت الهدف بقليل', 'bg-warning/20 text-warning'],
  angry: ['غاضبة', 'أنت بعيد عن الهدف', 'bg-live/20 text-danger'],
}
const training = computed(() => b.value?.timers.filter((t) => t.kind === 'training') ?? [])
const stadium = computed(() => b.value?.timers.find((t) => t.kind === 'stadium') ?? null)
const market = computed(() => b.value?.timers.find((t) => t.kind === 'market') ?? null)
const offers = computed(() => b.value?.pending.find((p) => p.kind === 'offers')?.count ?? 0)
const leagueId = computed(() => store.league)
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="sr-only">{{ $t('لوحة النادي') }}</h1>
    <!-- Its frame held while it loads, so nothing jumps. -->
    <div v-if="!b" class="grid gap-4 md:grid-cols-3" aria-hidden="true">
      <Skeleton kind="hero" :count="1" class="md:col-span-3" /><Skeleton v-for="i in 3" :key="i" kind="card" :count="1" />
    </div>
    <template v-else>
      <!-- The next match. -->
      <section class="hero" :aria-label="$t('المباراة القادمة')">
        <template v-if="b.match">
          <div class="flex flex-wrap items-center gap-x-3 text-xs text-text-muted">
            <span class="flex-1">{{ $t(b.match.competition === 'league' ? 'الدوري · الجولة {v0}' : 'الكأس', { v0: b.match.round }) }} · {{ $t(b.match.venue === 'home' ? 'على أرضك' : 'خارج أرضك') }}</span>
            <span>{{ $t('الحكم: {v0}', { v0: b.match.referee ? $t(REFEREE[b.match.referee] ?? b.match.referee) : $t('يُعيَّن قبل المباراة بنصف ساعة') }) }}</span>
          </div>
          <div class="grid gap-4 md:grid-cols-[1.3fr_1fr] md:items-center">
            <div class="grid grid-cols-[1fr_auto_1fr] items-center gap-2 text-center">
              <div v-for="(side, i) in [b.match.club, b.match.opponent]" :key="side.id" class="flex min-w-0 flex-col items-center gap-1" :style="{ order: i * 2 }">
                <img :src="side.crest_url" alt="" class="size-14 drop-shadow md:size-16" />
                <b class="max-w-full truncate font-display text-base md:text-lg">{{ $nm(side.name) }}</b>
                <span class="font-numbers text-xl text-brand-light">{{ strength(side.strength_cp) }}</span>
                <span class="flex gap-0.5" :aria-label="$t('آخر النتائج')">
                  <span v-for="(r, i) in side.form" :key="i" class="grid size-5 place-items-center rounded-full text-caption font-bold leading-none" :class="FORM[r][1]">{{ $t(FORM[r][0]) }}</span>
                </span>
              </div>
              <div class="order-1 flex flex-col items-center gap-0.5">
                <template v-if="b.match.status === 'live'">
                  <RouterLink :to="b.match.match_id ? `/live/${b.match.match_id}` : '/match'" class="flex items-center gap-1.5 rounded-pill bg-live px-3 py-1.5 font-bold text-white"><span class="size-2 animate-pulse rounded-full bg-white" />{{ $t('مباشر الآن') }}</RouterLink>
                </template>
                <template v-else>
                  <span class="text-xs text-text-muted">{{ $t('تبدأ بعد') }}</span>
                  <b class="font-numbers text-3xl leading-none text-gold md:text-5xl" dir="ltr">{{ countdown(b.match.scheduled_at, now) || '00:00:00' }}</b>
                </template>
              </div>
            </div>
            <div class="flex flex-col gap-2">
              <RouterLink to="/lineup" class="flex min-h-touch items-center gap-2 rounded-lg bg-surface-sunk px-3 py-2">
                <span class="min-w-0 flex-1"><b class="block text-sm">{{ $t(b.lineup.ready ? 'التشكيلة جاهزة' : 'في تشكيلتك مصاب أو موقوف') }}</b>
                  <span class="text-xs text-text-muted" dir="ltr">{{ b.lineup.formation.replace(/^custom:.*/, '') }}</span><span v-if="b.lineup.auto" class="text-xs text-text-muted"> · {{ $t('اختارها المساعد') }}</span></span>
                <span :class="b.lineup.ready ? 'text-success' : 'text-live'" aria-hidden="true">{{ b.lineup.ready ? '✓' : '!' }}</span>
              </RouterLink>
              <div class="grid grid-cols-2 gap-2 md:grid-cols-3">
                <RouterLink to="/lineup" class="btn-gold">{{ $t('التشكيلة') }}</RouterLink>
                <RouterLink to="/tactics" class="btn-plain">{{ $t('التكتيك') }}</RouterLink>
                <RouterLink to="/match" class="btn-plain col-span-2 md:col-span-1">{{ $t('تقرير الخصم') }}</RouterLink>
              </div>
            </div>
          </div>
        </template>
        <p v-else class="py-6 text-center text-text-muted">{{ $t('لا مباراة قادمة الآن.') }}</p>
      </section>

      <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <RouterLink to="/training" class="card">
          <h2 class="card-h"><Icon name="training" :size="18" />{{ $t('التدريب') }}<span class="ms-auto text-xs text-gold">{{ $t('{v0} من 4 خانات', { v0: training.length }) }}</span></h2>
          <p v-if="!training.length" class="text-sm text-text-muted">{{ $t('لا أحد يتدرب. ضع لاعباً من كل خط.') }}</p>
          <div v-for="t in training" :key="t.line" class="flex items-center gap-2 rounded-lg bg-surface-sunk px-2 py-1.5">
            <span class="min-w-0 flex-1 truncate text-sm"><bdi>{{ $nm(t.player ?? '') }}</bdi> <span class="text-xs text-text-muted">· {{ $t(LINE_NAMES[t.line ?? ''] ?? '') }}</span></span>
            <span class="font-numbers text-gold" dir="ltr">{{ countdown(t.at, now) || $t('الآن') }}</span>
          </div>
        </RouterLink>

        <RouterLink :to="leagueId ? `/leagues/${leagueId}` : '/stats'" class="card">
          <h2 class="card-h"><Icon name="league" :size="18" />{{ $t('الترتيب') }}<span class="ms-auto text-xs text-gold">{{ $t('الكل ›') }}</span></h2>
          <table class="w-full text-sm">
            <caption class="sr-only">{{ $t('الترتيب المصغر') }}</caption>
            <tbody>
              <tr v-for="r in b.standings.top" :key="r.id" class="border-t border-text/5" :class="r.mine ? 'text-gold' : ''">
                <td class="w-6 py-1 font-numbers text-text-muted">{{ r.position }}</td><td class="py-1"><bdi>{{ $nm(r.name) }}</bdi></td><td class="py-1 text-end font-numbers text-base">{{ r.points }}</td>
              </tr>
            </tbody>
          </table>
        </RouterLink>

        <div class="card">
          <h2 class="card-h"><Icon name="staff" :size="18" />{{ $t('الإدارة') }}</h2>
          <div v-if="b.board" class="flex items-center gap-3">
            <span class="rounded-pill px-3 py-1 text-sm font-bold" :class="MOOD[b.board.mood][2]">{{ $t(MOOD[b.board.mood][0]) }}</span>
            <span class="min-w-0 flex-1 text-xs text-text-muted">{{ $t(MOOD[b.board.mood][1]) }} · {{ $t('الهدف: المركز {v0} أو أعلى', { v0: b.board.target }) }}<template v-if="b.board.position"> · {{ $t('أنت {v0}', { v0: b.board.position }) }}</template></span>
          </div>
          <p v-else class="text-sm text-text-muted">{{ $t('الأهداف تُحدَّد أول الموسم.') }}</p>
        </div>

        <RouterLink to="/market" class="card">
          <h2 class="card-h"><Icon name="market" :size="18" />{{ $t('السوق') }}</h2>
          <p class="text-sm">{{ offers ? $t('{v0} عرض وارد', { v0: offers }) : $t('لا عروض واردة') }}</p>
          <p v-if="market" class="text-xs text-text-muted">{{ $t('الصفقات التالية بعد') }} <span class="font-numbers text-gold" dir="ltr">{{ countdown(market.at, now) || '—' }}</span></p>
        </RouterLink>

        <RouterLink to="/stadium" class="card">
          <h2 class="card-h"><Icon name="stadium" :size="18" />{{ $t('الملعب') }}</h2>
          <p v-if="stadium" class="text-sm">{{ $t(SECTION_NAMES[stadium.section ?? ''] ?? '') }} · {{ $t('الجزء {v0} من 5', { v0: stadium.part }) }} · <span class="font-numbers text-gold" dir="ltr">{{ countdown(stadium.at, now) || $t('الآن') }}</span></p>
          <p v-else class="text-sm text-text-muted">{{ $t('لا شيء يُبنى الآن.') }}</p>
        </RouterLink>

        <RouterLink to="/finance" class="card">
          <h2 class="card-h"><Icon name="finance" :size="18" />{{ $t('المالية') }}</h2>
          <b class="font-numbers text-2xl text-success" dir="ltr">{{ money(b.money.cash) }}</b>
        </RouterLink>

        <RouterLink to="/friendlies" class="card">
          <h2 class="card-h"><Icon name="friendly" :size="18" />{{ $t('الوديات') }}</h2>
        </RouterLink>

        <RouterLink to="/quests" class="card">
          <h2 class="card-h"><Icon name="quest" :size="18" />{{ $t('المهام الأسبوعية') }}</h2>
        </RouterLink>

        <RouterLink v-if="leagueId" :to="`/leagues/${leagueId}/newspaper`" class="card">
          <h2 class="card-h"><Icon name="news" :size="18" />{{ $t('أخبار الدوري') }}</h2>
        </RouterLink>
      </div>
    </template>
  </div>
</template>

<style scoped>
.hero {
  display: flex;
  flex-direction: column;
  gap: 0.9rem;
  padding: 1rem;
  border-radius: 1rem;
  border: 1px solid color-mix(in srgb, var(--color-gold) 35%, transparent);
  background: radial-gradient(120% 90% at 50% 0%, color-mix(in srgb, var(--color-brand) 25%, var(--color-panel)), var(--color-panel));
}
.card {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  min-width: 0;
  padding: 0.85rem;
  border-radius: 0.85rem;
  background: var(--color-surface);
  border: 1px solid color-mix(in srgb, var(--color-text) 7%, transparent);
  transition: border-color 0.15s ease;
}
a.card:hover { border-color: color-mix(in srgb, var(--color-gold) 45%, transparent); }
.card-h { display: flex; align-items: center; gap: 0.4rem; font-size: 0.95rem; font-weight: 700; }
.btn-gold, .btn-plain { display: flex; min-height: 2.75rem; align-items: center; justify-content: center; border-radius: 0.6rem; font-weight: 700; font-size: 0.9rem; }
.btn-gold { background: var(--color-gold); color: var(--color-on-gold); }
.btn-plain { background: var(--color-surface-raised); }
</style>
