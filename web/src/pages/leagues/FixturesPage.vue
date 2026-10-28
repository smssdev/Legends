<script setup lang="ts">
// «جدول المباريات» [Sprint 21 E4.3]: the whole season round by round, the league's and the cup's, for any club
// (the owner's request: anyone may see any rival's fixtures). The coach's own club in gold and chosen first; a club's
// name opens its squad; a played match its report, a live one the match.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { intlLocale } from '../../lib/i18n'
import { useSlot } from '../../stores/slot'
import ClubSquadDialog from '../../components/ClubSquadDialog.vue'

type Fixture = components['schemas']['Fixture']
const STAGES: Record<string, string> = { preliminary: 'الدور التمهيدي', r16: 'دور الـ16', qf: 'ربع النهائي', sf: 'نصف النهائي', final: 'النهائي' }

const leagueId = ref<number | null>(null)
const fixtures = ref<Fixture[]>([])
const loaded = ref(false)
const error = ref('')
const club = ref<number | 'all'>('all')
const squadOf = ref<number | null>(null)
const slot = useSlot()
const mine = computed(() => slot.current?.club?.id ?? null)

onMounted(async () => {
  try {
    leagueId.value = await currentLeague()
    if (leagueId.value) fixtures.value = (await api.GET('/leagues/{league}/fixtures', { params: { path: { league: leagueId.value } } })).data!.fixtures as Fixture[]
    if (mine.value) club.value = mine.value
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
})

const clubs = computed(() => {
  const seen = new Map<number, string>()
  for (const f of fixtures.value) for (const c of [f.home, f.away]) if (c) seen.set(c.id, c.name)
  return [...seen].map(([id, name]) => ({ id, name })).sort((a, b) => a.name.localeCompare(b.name))
})
// Round by round (and each cup stage on its own), only the chosen club's when one is chosen.
const groups = computed(() => {
  const out: { key: string; title: string; when: string; items: Fixture[] }[] = []
  for (const f of fixtures.value) {
    if (club.value !== 'all' && f.home?.id !== club.value && f.away?.id !== club.value) continue
    const key = `${f.competition}:${f.round}`
    let g = out.find((x) => x.key === key)
    if (!g) {
      g = { key, title: f.competition === 'cup' ? `${STAGES[f.stage ?? ''] ?? ''}` : `${f.round}`, when: f.scheduled_at, items: [] }
      out.push(g)
    }
    g.items.push(f)
  }
  return out
})
const day = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))
const played = (f: Fixture) => f.status === 'finished' && f.home_goals !== null && f.home_goals !== undefined
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 class="font-display text-3xl font-extrabold">{{ $t('جدول المباريات') }}</h1>
        <p class="mt-1 text-sm text-text-muted">{{ $t('الموسم كله جولة بجولة. اختر أي نادٍ لترى مبارياته، واضغط اسمه لترى لاعبيه.') }}</p>
      </div>
      <label v-if="clubs.length" class="flex flex-col gap-1 text-sm font-bold">{{ $t('النادي') }}
        <select v-model="club" class="h-touch min-w-56 rounded-lg bg-surface px-3 text-text">
          <option value="all">{{ $t('كل الأندية') }}</option>
          <option v-for="c in clubs" :key="c.id" :value="c.id">{{ $nm(c.name) }}{{ c.id === mine ? ' ★' : '' }}</option>
        </select>
      </label>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <p v-else-if="loaded && !leagueId" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('انضم إلى دوري واستلم فريقاً لترى مبارياته.') }}</p>
    <div v-else-if="!loaded" class="flex flex-col gap-3" aria-hidden="true">
      <div v-for="i in 4" :key="i" class="h-40 animate-pulse rounded-xl bg-surface" />
    </div>

    <section v-for="g in groups" :key="g.key" class="flex flex-col gap-1.5 rounded-xl bg-surface p-3" :aria-label="g.key.startsWith('cup') ? $t(g.title) : $t('الجولة {v0}', { v0: g.title })">
      <h2 class="flex items-center gap-2 px-1 font-display text-lg font-extrabold">
        <span v-if="g.key.startsWith('cup')" class="rounded-pill bg-gold/20 px-2 text-xs text-gold">{{ $t('الكأس') }}</span>
        {{ g.key.startsWith('cup') ? $t(g.title) : $t('الجولة {v0}', { v0: g.title }) }}
        <span class="ms-auto text-xs font-normal text-text-muted">{{ day(g.when) }}</span>
      </h2>
      <div v-for="f in g.items" :key="f.id" class="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-2 rounded-lg bg-surface-sunk px-3 py-2 text-sm"
        :class="(f.home?.id === mine || f.away?.id === mine) ? 'ring-1 ring-gold/50' : ''">
        <template v-if="f.is_bye">
          <button type="button" class="truncate text-start font-bold hover:text-gold" @click="squadOf = f.home!.id">{{ $nm(f.home!.name) }}</button>
          <span class="text-xs text-text-muted">{{ $t('راحة') }}</span><span />
        </template>
        <template v-else>
          <button type="button" class="flex min-w-0 items-center gap-2 text-start font-bold hover:text-gold" :class="f.home?.id === mine ? 'text-gold' : ''" @click="f.home && (squadOf = f.home.id)">
            <img v-if="f.home" :src="f.home.crest_url" alt="" class="size-6 shrink-0" /><span class="truncate">{{ f.home ? $nm(f.home.name) : $t('يُحدد لاحقاً') }}</span>
          </button>
          <RouterLink v-if="f.match_id && (played(f) || f.status === 'live')" :to="played(f) ? { name: 'league-report', params: { id: f.match_id } } : { name: 'league-match', params: { id: f.match_id } }"
            class="rounded-md px-2 py-1 text-center font-numbers font-bold" :class="f.status === 'live' ? 'bg-live text-white' : 'bg-surface text-gold'" dir="ltr">
            {{ played(f) ? `${f.home_goals} - ${f.away_goals}` : $t('مباشر') }}
          </RouterLink>
          <span v-else class="text-center font-numbers text-xs text-text-muted" dir="ltr">{{ new Date(f.scheduled_at).toLocaleTimeString(intlLocale(), { hour: '2-digit', minute: '2-digit' }) }}</span>
          <button type="button" class="flex min-w-0 items-center justify-end gap-2 text-end font-bold hover:text-gold" :class="f.away?.id === mine ? 'text-gold' : ''" @click="f.away && (squadOf = f.away.id)">
            <span class="truncate">{{ f.away ? $nm(f.away.name) : $t('يُحدد لاحقاً') }}</span><img v-if="f.away" :src="f.away.crest_url" alt="" class="size-6 shrink-0" />
          </button>
        </template>
      </div>
    </section>
    <ClubSquadDialog v-if="squadOf && leagueId" :league-id="leagueId" :club-id="squadOf" @close="squadOf = null" />
  </div>
</template>
