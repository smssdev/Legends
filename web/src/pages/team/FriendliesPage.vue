<script setup lang="ts">
// [Sprint 20 B4] Friendlies (the owner's approved draft): a match now against any club of the league, played whole by
// the engine with no effect on the table, money, fitness or injuries, and a little training for those who played.
// The closest in strength recommended; the report at once. [Sprint 24 B2] Five coins each, with no limit, in every
// league: the first tap asks to confirm with the price, and the coins go with the match. [Sprint 27 B3] Then the quick
// simulation plays in the page (QuickMatch, from the server's timeline) before the result shows.
import UiButton from '../../components/ui/UiButton.vue'
import { scoreText } from '../../lib/format'
import { uuid } from '../../lib/uuid'
import { computed, onMounted, ref } from 'vue'
import QuickMatch from '../../components/match/QuickMatch.vue'
import { api } from '../../api/client'
import { act, busy as isBusy } from '../../lib/action'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { countdown, useNow } from '../../lib/clock'
import { useWallet } from '../../stores/wallet'

type View = components['schemas']['Friendlies']
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const last = ref<components['schemas']['Friendly'] | null>(null)
// The friendly being watched (its quick simulation), before its result shows.
const watching = ref(false)

const loaded = ref(false)
const now = useNow()
// The opponent waiting for the coach to confirm the price.
const confirming = ref<number | null>(null)
const canPay = computed(() => !!v.value && v.value.balance >= v.value.coins)
const path = computed(() => ({ params: { path: { league: leagueId.value! } } }))

onMounted(async () => {
  leagueId.value = await currentLeague()
  if (leagueId.value) v.value = (await api.GET('/leagues/{league}/friendlies', path.value)).data ?? null
  loaded.value = true
})
// [X92] Through lib/action: its button waits, an error in a toast. The price stays asked on the button itself (the
// second tap, Sprint 24), which is lighter than a window for five coins.
async function play(opponent: number) {
  if (confirming.value !== opponent) {
    confirming.value = opponent
    return
  }
  confirming.value = null
  const r = await act('friendly', () => api.POST('/leagues/{league}/friendlies', { ...path.value, body: { opponent_id: opponent, idempotency_key: uuid() } }))
  const data = r?.data
  if (!data) return
  last.value = data.friendly
  watching.value = !!data.friendly.report.timeline?.length
  v.value = data
  useWallet().load()
}
const busy = computed(() => isBusy('friendly'))
const result = (f: components['schemas']['Friendly']) => (f.goals_for > f.goals_against ? 'فوز' : f.goals_for < f.goals_against ? 'خسارة' : 'تعادل')
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-start gap-3">
      <div class="min-w-0 flex-1">
        <h1 class="font-display text-3xl font-extrabold">{{ $t('الوديات') }}</h1>
      </div>
      <span v-if="v" class="flex flex-col items-end gap-1">
        <span class="rounded-pill bg-gold px-3 py-1 text-sm font-bold text-on-gold">{{ v.first_free ? $t('أول ودية لك مجانية') : $t('الودية بـ {v0} كوينز', { v0: v.coins }) }}</span>
        <span class="text-xs text-text-muted">{{ $t('رصيدك') }}: <b class="font-numbers" dir="ltr">{{ v.balance }}</b></span>
      </span>
    </header>
    <p v-if="loaded && !leagueId" class="rounded-xl ui-card p-6 text-center text-text-muted">{{ $t('ليس لديك فريق بعد.') }}</p>
    <p v-if="v && v.balance < v.coins" class="rounded-lg bg-warning/15 px-3 py-2 text-sm text-warning" role="status">{{ $t('رصيدك لا يكفي لودية. الكوينز تُكسب من المهام والفوز.') }}</p>
    <p v-if="v?.blocked" class="rounded-lg bg-warning/15 px-3 py-2 text-sm text-warning" role="status">
      {{ v.blocked.reason === 'live' ? $t('مباراتك تُلعب الآن: الوديات بعدها.') : $t('مباراتك بعد قليل: الوديات تعود بعدها ({v0}).', { v0: countdown(v.blocked.until, now) }) }}
    </p>

    <!-- [Sprint 27 B3] The quick simulation first. -->
    <QuickMatch
      v-if="last && watching"
      :timeline="last.report.timeline ?? []"
      :home="{ name: v?.club.name ?? '', crest: v?.club.crest_url ?? '' }"
      :away="{ name: last.opponent.name, crest: last.opponent.crest_url }"
      @done="watching = false"
    />
    <!-- The friendly just played. -->
    <section v-else-if="last" class="flex flex-col gap-3 rounded-xl border border-gold/40 ui-card p-4" :aria-label="$t('نتيجة الودية')" aria-live="polite">
      <div class="flex items-center gap-3">
        <AppImage :src="last.opponent.crest_url" alt="" class="size-10" :size="40" crest />
        <span class="min-w-0 flex-1"><b class="block">{{ $t('ضد {v0}', { v0: $nm(last.opponent.name) }) }}</b><span class="text-xs text-text-muted">{{ $t(result(last)) }}</span></span>
        <b class="font-numbers text-4xl" dir="ltr">{{ scoreText(last.goals_for, last.goals_against) }}</b>
      </div>
      <ul v-if="last.report.goals.length" class="flex flex-wrap gap-x-3 text-sm">
        <li v-for="(g, i) in last.report.goals" :key="i" :class="g.side === 'home' ? '' : 'text-text-muted'"><span class="font-numbers text-text-muted" dir="ltr">{{ g.minute }}'</span> <bdi>{{ $nm(g.name ?? '') }}</bdi></li>
      </ul>
      <p v-if="last.report.coins" class="text-xs text-text-muted">{{ $t('خُصم {v0} كوينز من رصيدك.', { v0: last.report.coins }) }}</p>
      <p class="text-xs text-text-muted">{{ $t('الأفضل') }}: <template v-for="(p, i) in last.report.best" :key="p.id"><bdi>{{ $nm(p.name ?? '') }}</bdi> <span class="font-numbers text-gold">{{ (p.rating / 100).toFixed(1) }}</span><template v-if="i < last.report.best.length - 1">، </template></template> · {{ $t('{v0} لاعباً زاد تدريبهم ولياقتهم (+{v1})', { v0: last.report.played, v1: v?.fitness ?? 0 }) }}</p>
    </section>

    <div v-if="!v && leagueId" class="flex flex-col gap-2" aria-hidden="true"><div v-for="n in 4" :key="n" class="h-16 animate-pulse rounded-xl ui-card" /></div>
    <ul v-else-if="v" class="flex flex-col gap-2">
      <li v-for="o in v.opponents" :key="o.id" class="flex min-h-touch items-center gap-3 rounded-xl ui-card p-3" :class="o.recommended ? 'border border-brand-light/40' : ''">
        <AppImage :src="o.crest_url" alt="" class="size-10 shrink-0" :size="40" crest />
        <span class="min-w-0 flex-1">
          <b class="block truncate">{{ $nm(o.name) }} · <span class="font-numbers text-brand-light">{{ Math.round(o.strength_cp / 100) }}</span></b>
          <span class="block truncate text-xs text-text-muted">{{ o.recommended ? $t('موصى به: الأقرب إلى قوتك') : o.coach ? $t('مدرب: {v0}', { v0: o.coach }) : $t('الكمبيوتر') }}</span>
        </span>
        <button v-if="confirming === o.id" type="button" class="h-touch shrink-0 rounded-lg px-3 text-sm text-text-muted" @click="confirming = null">{{ $t('إلغاء') }}</button>
        <UiButton size="sm" class="shrink-0" :variant="confirming === o.id ? 'brand' : o.recommended ? 'primary' : 'quiet'" :disabled="busy || watching || !canPay || !!v.blocked || o.played_today" @click="play(o.id)">
          {{ o.played_today ? $t('لُعبت اليوم') : confirming === o.id ? (v.first_free ? $t('العب مجاناً') : $t('أكّد: {v0} كوينز', { v0: v.coins })) : $t('العب') }}
        </UiButton>
      </li>
    </ul>

    <section v-if="v?.recent.length" class="flex flex-col gap-2">
      <h2 class="font-display text-lg font-bold">{{ $t('آخر الوديات') }}</h2>
      <div v-for="f in v.recent" :key="f.id" class="flex items-center gap-2 rounded-lg bg-surface px-3 py-2 text-sm">
        <AppImage :src="f.opponent.crest_url" alt="" class="size-7" :size="28" crest /><span class="min-w-0 flex-1 truncate">{{ $nm(f.opponent.name) }}</span>
        <b class="font-numbers text-base" dir="ltr">{{ scoreText(f.goals_for, f.goals_against) }}</b>
      </div>
    </section>
  </div>
</template>
