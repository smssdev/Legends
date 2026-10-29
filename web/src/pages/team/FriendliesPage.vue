<script setup lang="ts">
// [Sprint 20 B4] Friendlies (the owner's approved draft): a match now against any club of the league, played whole by
// the engine with no effect on the table, money, fitness or injuries, and a little training for those who played.
// Free, three a day; the closest in strength recommended; the report at once.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { countdown, useNow } from '../../lib/clock'

type View = components['schemas']['Friendlies']
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const last = ref<components['schemas']['Friendly'] | null>(null)
const message = ref('')
const busy = ref(false)
const loaded = ref(false)
const now = useNow()
const path = computed(() => ({ params: { path: { league: leagueId.value! } } }))

onMounted(async () => {
  leagueId.value = await currentLeague()
  if (leagueId.value) v.value = (await api.GET('/leagues/{league}/friendlies', path.value)).data ?? null
  loaded.value = true
})
async function play(opponent: number) {
  message.value = ''
  busy.value = true
  try {
    await ensureCsrf()
    const { data } = await api.POST('/leagues/{league}/friendlies', { ...path.value, body: { opponent_id: opponent } })
    last.value = data!.friendly
    v.value = data!
  } catch (e) {
    message.value = asApiError(e).message
  } finally {
    busy.value = false
  }
}
const result = (f: components['schemas']['Friendly']) => (f.goals_for > f.goals_against ? 'فوز' : f.goals_for < f.goals_against ? 'خسارة' : 'تعادل')
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-start gap-3">
      <div class="min-w-0 flex-1">
        <h1 class="font-display text-3xl font-extrabold">{{ $t('الوديات') }}</h1>
      </div>
      <span v-if="v" class="rounded-pill bg-brand/20 px-3 py-1 font-numbers text-sm text-brand-light">{{ $t('{v0} من {v1} اليوم', { v0: v.left, v1: v.max }) }}</span>
    </header>
    <p v-if="loaded && !leagueId" class="rounded-xl bg-surface p-6 text-center text-text-muted">{{ $t('ليس لديك فريق بعد.') }}</p>
    <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm text-warning" role="status">{{ $t(message) }}</p>
    <p v-if="v?.blocked" class="rounded-lg bg-warning/15 px-3 py-2 text-sm text-warning" role="status">
      {{ v.blocked.reason === 'live' ? $t('مباراتك تُلعب الآن: الوديات بعدها.') : $t('مباراتك بعد قليل: الوديات تعود بعدها ({v0}).', { v0: countdown(v.blocked.until, now) }) }}
    </p>

    <!-- The friendly just played. -->
    <section v-if="last" class="flex flex-col gap-3 rounded-xl border border-gold/40 bg-surface p-4" :aria-label="$t('نتيجة الودية')" aria-live="polite">
      <div class="flex items-center gap-3">
        <img :src="last.opponent.crest_url" alt="" class="size-10" />
        <span class="min-w-0 flex-1"><b class="block">{{ $t('ضد {v0}', { v0: $nm(last.opponent.name) }) }}</b><span class="text-xs text-text-muted">{{ $t(result(last)) }}</span></span>
        <b class="font-numbers text-4xl" dir="ltr">{{ last.goals_for }} - {{ last.goals_against }}</b>
      </div>
      <ul v-if="last.report.goals.length" class="flex flex-wrap gap-x-3 text-sm">
        <li v-for="(g, i) in last.report.goals" :key="i" :class="g.side === 'home' ? '' : 'text-text-muted'"><span class="font-numbers text-text-muted" dir="ltr">{{ g.minute }}'</span> <bdi>{{ $nm(g.name ?? '') }}</bdi></li>
      </ul>
      <p class="text-xs text-text-muted">{{ $t('الأفضل') }}: <template v-for="(p, i) in last.report.best" :key="p.id"><bdi>{{ $nm(p.name ?? '') }}</bdi> <span class="font-numbers text-gold">{{ (p.rating / 100).toFixed(1) }}</span><template v-if="i < last.report.best.length - 1">، </template></template> · {{ $t('{v0} لاعباً زاد تدريبهم', { v0: last.report.played }) }}</p>
    </section>

    <div v-if="!v && leagueId" class="flex flex-col gap-2" aria-hidden="true"><div v-for="n in 4" :key="n" class="h-16 animate-pulse rounded-xl bg-surface" /></div>
    <ul v-else-if="v" class="flex flex-col gap-2">
      <li v-for="o in v.opponents" :key="o.id" class="flex min-h-touch items-center gap-3 rounded-xl bg-surface p-3" :class="o.recommended ? 'border border-brand-light/40' : ''">
        <img :src="o.crest_url" alt="" class="size-10 shrink-0" />
        <span class="min-w-0 flex-1">
          <b class="block truncate">{{ $nm(o.name) }} · <span class="font-numbers text-brand-light">{{ Math.round(o.strength_cp / 100) }}</span></b>
          <span class="block truncate text-xs text-text-muted">{{ o.recommended ? $t('موصى به: الأقرب إلى قوتك') : o.coach ? $t('مدرب: {v0}', { v0: o.coach }) : $t('الكمبيوتر') }}</span>
        </span>
        <button type="button" class="h-touch shrink-0 rounded-lg px-4 font-bold disabled:opacity-40" :class="o.recommended ? 'bg-gold text-on-gold' : 'bg-surface-raised'" :disabled="busy || !v.left || !!v.blocked" @click="play(o.id)">{{ $t('العب') }}</button>
      </li>
    </ul>

    <section v-if="v?.recent.length" class="flex flex-col gap-2">
      <h2 class="font-display text-lg font-bold">{{ $t('آخر الوديات') }}</h2>
      <div v-for="f in v.recent" :key="f.id" class="flex items-center gap-2 rounded-lg bg-surface px-3 py-2 text-sm">
        <img :src="f.opponent.crest_url" alt="" class="size-7" /><span class="min-w-0 flex-1 truncate">{{ $nm(f.opponent.name) }}</span>
        <b class="font-numbers text-base" dir="ltr">{{ f.goals_for }} - {{ f.goals_against }}</b>
      </div>
    </section>
  </div>
</template>
