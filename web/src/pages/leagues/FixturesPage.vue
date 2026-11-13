<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// «جدول المباريات» [Sprint 21 E4.3]: the whole season round by round, the league's and the cup's, for any club
// (the owner's request: anyone may see any rival's fixtures). The coach's own club in gold and chosen first; a club's
// name opens its squad; a live one the match. [X69] A played match's score opens its quick
// recap for any member (then the whole match again on /live/{id}), and on top: the coach's last match and the last
// round's matches, each with «ملخص» and «شاهد المحاكاة».
import { scoreText } from '../../lib/format'
import { computed, onMounted, ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'
import { intlLocale, t } from '../../lib/i18n'
import { useSlot } from '../../stores/slot'
import ClubSquadDialog from '../../components/ClubSquadDialog.vue'
import AsyncState from '../../components/ui/AsyncState.vue'
import UiButton from '../../components/ui/UiButton.vue'
import UiTabs from '../../components/ui/UiTabs.vue'
import MatchRecap from '../../components/shell/MatchRecap.vue'

type Fixture = components['schemas']['Fixture']
const STAGES: Record<string, string> = { preliminary: 'الدور التمهيدي', r32: 'دور الـ32', r16: 'دور الـ16', qf: 'ربع النهائي', sf: 'نصف النهائي', final: 'النهائي' }

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
// [Sprint 56 W9] The rounds as tabs (it was a list eleven screens long): «شاهد» first when a round is played, then each
// round and cup stage; it opens on the round to come (or the last one at the season's end).
const TABS = computed(() => [
  ...(lastRound.value ? [{ key: 'watch', label: 'شاهد' }] : []),
  ...groups.value.map((g) => ({ key: g.key, label: g.key.startsWith('cup') ? g.title : t('ج {v0}', { v0: g.title }) })),
])
const chosen = ref('')
const tab = computed({
  get: () => chosen.value || groups.value.find((g) => g.items.some((f) => !played(f) && !f.is_bye))?.key || groups.value[groups.value.length - 1]?.key || 'watch',
  set: (k: string) => (chosen.value = k),
})
const round = computed(() => groups.value.find((g) => g.key === tab.value) ?? null)
const day = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))
const played = (f: Fixture) => f.status === 'finished' && f.home_goals !== null && f.home_goals !== undefined
const recapOf = ref<number | null>(null)
// The played matches, the latest first: the coach's last one, and the round (or cup stage) of the latest of all.
const done = computed(() => fixtures.value.filter((f) => f.match_id && played(f)).sort((a, b) => b.scheduled_at.localeCompare(a.scheduled_at)))
const lastMine = computed(() => (mine.value ? done.value.find((f) => f.home?.id === mine.value || f.away?.id === mine.value) ?? null : null))
const lastRound = computed(() => {
  const top = done.value[0]
  if (!top) return null
  const items = done.value.filter((f) => f.competition === top.competition && f.round === top.round).reverse()
  return { title: top.competition === 'cup' ? (STAGES[top.stage ?? ''] ?? '') : `${top.round}`, cup: top.competition === 'cup', items }
})
</script>

<template>
  <!-- [Sprint 56 W9] One screen: the rounds as tabs over the round's matches, each row 44px. -->
  <div class="fx">
    <h1 class="sr-only">{{ $t('جدول المباريات') }}</h1>
    <AsyncState v-if="error || !loaded || !leagueId" :loading="!loaded" :error="error || null" :empty="loaded && !error && !leagueId"
      empty-title="انضم إلى دوري واستلم فريقاً لترى مبارياته." skeleton="row" :rows="6" />
    <template v-else>
      <div class="flex items-center gap-2">
        <UiTabs v-model="tab" :items="TABS" label="الجولات" size="sm" class="min-w-0 flex-1" />
        <label v-if="clubs.length" class="shrink-0">
          <span class="sr-only">{{ $t('النادي') }}</span>
          <select v-model="club" class="h-touch w-36 rounded-lg bg-surface px-2 text-caption text-text">
            <option value="all">{{ $t('كل الأندية') }}</option>
            <option v-for="c in clubs" :key="c.id" :value="c.id">{{ $nm(c.name) }}{{ c.id === mine ? ' · ' + $t('فريقك') : '' }}</option>
          </select>
        </label>
      </div>

      <div class="fx-body">
        <!-- [X69] Watch them again: the coach's last match, and every match of the last round. -->
        <template v-if="tab === 'watch' && lastRound">
          <template v-if="lastMine">
            <h2 class="text-body font-extrabold">{{ $t('آخر مباراة لك') }}</h2>
            <div class="fx-row ring-1 ring-gold/50">
              <span class="flex min-w-0 flex-1 items-center gap-2 font-bold">
                <AppImage :src="lastMine.home!.crest_url" alt="" class="size-6 shrink-0" :size="24" crest /><bdi class="truncate">{{ $nm(lastMine.home!.name) }}</bdi>
                <span class="flex gap-1 font-numbers text-gold"><span>{{ lastMine.home_goals }}</span><span>-</span><span>{{ lastMine.away_goals }}</span></span>
                <bdi class="truncate">{{ $nm(lastMine.away!.name) }}</bdi><AppImage :src="lastMine.away!.crest_url" alt="" class="size-6 shrink-0" :size="24" crest />
              </span>
              <UiButton size="sm" variant="quiet" @click="recapOf = lastMine.match_id!"><Icon name="bolt" :size="16" class="inline-block align-[-3px]" /> {{ $t('ملخص') }}</UiButton>
              <UiButton size="sm" :to="{ name: 'league-match', params: { id: lastMine.match_id! } }"><Icon name="play" :size="16" class="inline-block align-[-3px]" /> {{ $t('شاهد المحاكاة') }}</UiButton>
            </div>
          </template>
          <h2 class="flex items-center gap-2 text-body font-extrabold">
            <span v-if="lastRound.cup" class="rounded-pill bg-gold/20 px-2 text-caption text-gold">{{ $t('الكأس') }}</span>
            {{ lastRound.cup ? $t(lastRound.title) : $t('الجولة الأخيرة · {v0}', { v0: lastRound.title }) }}
          </h2>
          <div v-for="f in lastRound.items" :key="f.id" class="fx-row" :class="(f.home?.id === mine || f.away?.id === mine) ? 'ring-1 ring-gold/50' : ''">
            <span class="flex min-w-0 flex-1 items-center gap-2 font-bold">
              <AppImage :src="f.home!.crest_url" alt="" class="size-6 shrink-0" :size="24" crest /><bdi class="truncate">{{ $nm(f.home!.name) }}</bdi>
              <span class="flex gap-1 font-numbers text-gold"><span>{{ f.home_goals }}</span><span>-</span><span>{{ f.away_goals }}</span></span>
              <bdi class="truncate">{{ $nm(f.away!.name) }}</bdi><AppImage :src="f.away!.crest_url" alt="" class="size-6 shrink-0" :size="24" crest />
            </span>
            <UiButton size="sm" variant="quiet" @click="recapOf = f.match_id!"><Icon name="bolt" :size="16" class="inline-block align-[-3px]" /><span class="max-md:hidden">{{ $t('ملخص') }}</span></UiButton>
            <UiButton size="sm" variant="quiet" :to="{ name: 'league-match', params: { id: f.match_id! } }"><Icon name="play" :size="16" class="inline-block align-[-3px]" /><span class="max-md:hidden">{{ $t('شاهد المحاكاة') }}</span></UiButton>
          </div>
        </template>

        <section v-else-if="round" class="flex flex-col gap-1" :aria-label="round.key.startsWith('cup') ? $t(round.title) : $t('الجولة {v0}', { v0: round.title })">
          <p class="flex items-center gap-2 text-caption text-text-muted">
            <span v-if="round.key.startsWith('cup')" class="rounded-pill bg-gold/20 px-2 text-gold">{{ $t('الكأس') }}</span>
            <b class="text-text">{{ round.key.startsWith('cup') ? $t(round.title) : $t('الجولة {v0}', { v0: round.title }) }}</b> · {{ day(round.when) }}
          </p>
          <div v-for="f in round.items" :key="f.id" class="fx-row grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)]"
            :class="(f.home?.id === mine || f.away?.id === mine) ? 'ring-1 ring-gold/50' : ''">
            <template v-if="f.is_bye">
              <button type="button" class="min-h-touch truncate text-start font-bold hover:text-gold" @click="squadOf = f.home!.id">{{ $nm(f.home!.name) }}</button>
              <span class="text-caption text-text-muted">{{ $t('راحة') }}</span><span />
            </template>
            <template v-else>
              <button type="button" class="flex min-h-touch min-w-0 items-center gap-2 text-start font-bold hover:text-gold" :class="f.home?.id === mine ? 'text-gold' : ''" @click="f.home && (squadOf = f.home.id)">
                <AppImage v-if="f.home" :src="f.home.crest_url" alt="" class="size-6 shrink-0" :size="24" crest /><span class="truncate">{{ f.home ? $nm(f.home.name) : $t('يُحدد لاحقاً') }}</span>
              </button>
              <button v-if="f.match_id && played(f)" type="button" class="min-h-touch min-w-14 rounded-md bg-surface px-2 text-center font-numbers font-bold text-gold" dir="ltr"
                :aria-label="$t('الملخص السريع')" @click="recapOf = f.match_id">{{ scoreText(f.home_goals, f.away_goals) }}</button>
              <UiButton v-else-if="f.match_id && f.status === 'live'" size="sm" variant="danger" :to="{ name: 'league-match', params: { id: f.match_id } }">{{ $t('مباشر') }}</UiButton>
              <span v-else class="min-w-14 text-center font-numbers text-caption text-text-muted" dir="ltr">{{ new Date(f.scheduled_at).toLocaleTimeString(intlLocale(), { hour: '2-digit', minute: '2-digit' }) }}</span>
              <button type="button" class="flex min-h-touch min-w-0 items-center justify-end gap-2 text-end font-bold hover:text-gold" :class="f.away?.id === mine ? 'text-gold' : ''" @click="f.away && (squadOf = f.away.id)">
                <span class="truncate">{{ f.away ? $nm(f.away.name) : $t('يُحدد لاحقاً') }}</span><AppImage v-if="f.away" :src="f.away.crest_url" alt="" class="size-6 shrink-0" :size="24" crest />
              </button>
            </template>
          </div>
        </section>
      </div>
    </template>
    <MatchRecap v-if="recapOf" :match-id="recapOf" @close="recapOf = null" />
    <ClubSquadDialog v-if="squadOf && leagueId" :league-id="leagueId" :club-id="squadOf" @close="squadOf = null" />
  </div>
</template>

<style scoped>
.fx { display: flex; flex-direction: column; gap: var(--space-sm); }
.fx-body { position: relative; display: flex; flex: 1; min-height: 0; flex-direction: column; gap: var(--space-xs); overflow-y: auto; overscroll-behavior: contain; padding: var(--space-sm); border-radius: var(--radius-xl); background: var(--color-surface); }
.fx-row { display: flex; min-height: var(--spacing-touch); align-items: center; gap: var(--space-sm); padding: 0 var(--space-sm); border-radius: var(--radius-lg); font-size: var(--text-body); background: var(--color-surface-sunk); }
.fx-row.grid { display: grid; }
</style>
