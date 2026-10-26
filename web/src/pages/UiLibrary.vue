<script setup lang="ts">
// Sprint 11: the component library on a real club. Choose a league and a club; its badge,
// squad with values and room to grow, and the league's clubs by strength, all from the API.
import { computed, onMounted, ref, watch } from 'vue'
import { api, asApiError } from '../api/client'
import type { components } from '../api/schema'
import ClubCrest from '../components/ui/ClubCrest.vue'
import Coins from '../components/ui/Coins.vue'
import LineBadge from '../components/ui/LineBadge.vue'
import PlayerRow from '../components/ui/PlayerRow.vue'
import UiButton from '../components/ui/UiButton.vue'
import UiCard from '../components/ui/UiCard.vue'
import UiChip from '../components/ui/UiChip.vue'
import UiTable from '../components/ui/UiTable.vue'
import { LINES, money, strength, type Line } from '../lib/format'

type Club = components['schemas']['DataClub']
type Player = components['schemas']['DataPlayer']
type Template = { name: string; clubs: number; top_strength_cp: number }

const templates = ref<Template[]>([])
const league = ref('Premier League')
const clubs = ref<Club[]>([])
const clubId = ref<number | null>(null)
const club = ref<(Club & { squad_value: number; players: Player[] }) | null>(null)
const tab = ref<'all' | Line>('all')
const error = ref('')

onMounted(async () => {
  try {
    const { data } = await api.GET('/data/templates')
    templates.value = (data?.templates ?? []) as Template[]
    if (!templates.value.some((t) => t.name === league.value) && templates.value[0]) league.value = templates.value[0].name
    await loadClubs()
  } catch (e) {
    error.value = asApiError(e).message
  }
})
watch(league, loadClubs)
watch(clubId, loadClub)

async function loadClubs() {
  const { data } = await api.GET('/data/clubs', { params: { query: { league: league.value } } })
  clubs.value = data?.clubs ?? []
  clubId.value = clubs.value[0]?.id ?? null
}
async function loadClub() {
  if (!clubId.value) return
  const { data } = await api.GET('/data/clubs/{club}', { params: { path: { club: clubId.value } } })
  club.value = data as typeof club.value
  tab.value = 'all'
}

const lines: Line[] = ['gk', 'def', 'mid', 'att']
const counts = computed(() => Object.fromEntries(lines.map((l) => [l, club.value?.players.filter((p) => p.line === l).length ?? 0])))
const shown = computed(() => (club.value?.players ?? []).filter((p) => tab.value === 'all' || p.line === tab.value))
const table = computed(() => clubs.value.map((c, i) => ({ rank: i + 1, ...c })))
</script>

<template>
  <div class="flex flex-col gap-5">
    <div>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('مكتبة المكونات') }}</h1>
      <p class="mt-1 text-text-muted">{{ $t('مكونات نظام التصميم على نادٍ حقيقي من البيانات.') }}</p>
    </div>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>

    <UiCard :title="$t('الأزرار والشارات')">
      <div class="flex flex-wrap gap-2">
        <UiButton>{{ $t('احفظ التشكيلة') }}</UiButton>
        <UiButton variant="outline">{{ $t('تحسين تلقائي') }}</UiButton>
        <UiButton variant="quiet">{{ $t('إلغاء') }}</UiButton>
        <UiButton variant="danger">{{ $t('حذف') }}</UiButton>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <UiChip tone="live">{{ $t('مباشر') }} <span class="font-numbers" dir="ltr">67'</span></UiChip>
        <UiChip><Coins :amount="1250" /></UiChip>
        <UiChip tone="win">{{ $t('فوز') }}</UiChip>
        <UiChip tone="draw">{{ $t('تعادل') }}</UiChip>
        <UiChip tone="loss">{{ $t('خسارة') }}</UiChip>
        <UiChip tone="gold">{{ $t('الحكم: صارم') }}</UiChip>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <LineBadge v-for="l in lines" :key="l" :line="l" full />
        <span class="text-sm text-text-muted">{{ $t('ألوان الخطوط تفرّق الخط فقط') }}</span>
      </div>
    </UiCard>

    <UiCard :title="$t('النادي')">
      <template #action>
        <div class="flex flex-wrap gap-2">
          <label class="sr-only" for="ui-league">{{ $t('الدوري') }}</label>
          <select id="ui-league" v-model="league" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3">
            <option v-for="t in templates" :key="t.name" :value="t.name">{{ t.name }} ({{ t.clubs }})</option>
          </select>
          <label class="sr-only" for="ui-club">{{ $t('النادي') }}</label>
          <select id="ui-club" v-model="clubId" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3">
            <option v-for="c in clubs" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
        </div>
      </template>
      <div class="flex gap-3 overflow-x-auto pb-1">
        <button v-for="c in clubs.slice(0, 10)" :key="c.id" type="button" class="shrink-0 rounded-xl p-2" :class="c.id === clubId ? 'bg-surface-raised ring-1 ring-gold/60' : ''" @click="clubId = c.id">
          <ClubCrest :url="c.crest_url" :code="c.code" :name="c.name" :size="52" />
        </button>
      </div>
    </UiCard>

    <section v-if="club" class="flex flex-col gap-3" aria-labelledby="h-squad">
      <div class="flex flex-wrap items-center gap-4">
        <ClubCrest :url="club.crest_url" :code="club.code" :size="64" />
        <div class="min-w-0 flex-1">
          <h2 id="h-squad" class="font-display text-2xl font-extrabold">{{ club.name }}</h2>
          <p class="text-text-muted">
            <span class="font-numbers text-base text-text">{{ club.players.length }}</span> {{ $t('لاعباً · القوة') }}
            <span class="font-numbers text-base text-gold">{{ strength(club.strength_cp) }}</span> {{ $t('· القيمة') }}
            <span class="font-numbers text-base text-text">{{ money(club.squad_value) }}</span>
          </p>
        </div>
      </div>
      <div role="tablist" :aria-label="$t('الخطوط')" class="flex gap-2 overflow-x-auto pb-1">
        <button type="button" role="tab" :aria-selected="tab === 'all'" class="h-touch shrink-0 rounded-lg px-4 font-bold" :class="tab === 'all' ? 'bg-gold text-on-gold' : 'bg-surface'" @click="tab = 'all'">
          {{ $t('الكل') }} <span class="font-numbers">{{ club.players.length }}</span>
        </button>
        <button v-for="l in lines" :key="l" type="button" role="tab" :aria-selected="tab === l" class="h-touch shrink-0 rounded-lg px-4 font-bold" :class="tab === l ? 'bg-gold text-on-gold' : 'bg-surface'" @click="tab = l">
          {{ $t(LINES[l].plural) }} <span class="font-numbers">{{ counts[l] }}</span>
        </button>
      </div>
      <div class="grid gap-2 lg:grid-cols-2">
        <PlayerRow v-for="p in shown" :key="p.id" :name="p.name" :line="p.line" :position="p.position" :age="p.age" :overall="p.overall" :potential="p.potential" :value="p.value" />
      </div>
    </section>

    <UiCard v-if="table.length" :title="$t('أندية {v0}', { v0: league })">
      <UiTable
        :rows="table"
        :caption="$t('أندية {v0} حسب القوة', { v0: league })"
        :columns="[{ key: 'rank', label: '#', numeric: true }, { key: 'name', label: $t('النادي') }, { key: 'code', label: $t('الرمز'), hideSm: true }, { key: 'strength_cp', label: $t('القوة'), numeric: true }]"
        :highlight="(r) => r.id === clubId"
      >
        <template #name="{ row }">
          <span class="flex items-center gap-2"><img :src="row.crest_url" alt="" width="24" height="27" loading="lazy" />{{ row.name }}</span>
        </template>
        <template #strength_cp="{ row }"><span class="text-gold">{{ strength(row.strength_cp) }}</span></template>
      </UiTable>
    </UiCard>
  </div>
</template>
