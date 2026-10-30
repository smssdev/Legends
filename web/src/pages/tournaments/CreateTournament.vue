<script setup lang="ts">
// [Sprint 27] Make a tournament (docs/design/legends-ui/Sprint27Drafts.html, 3): a template fills the teams and the
// shape (World Cup, Club World Cup, AFCON, EURO, Asian Cup, or custom), and everything stays editable: the teams
// (national teams by continent and clubs by search, 2 to 32), the format, the groups, the live draw's time, and the
// maker's own team (or none: the organizer only).
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components, paths } from '../../api/schema'
import { strength } from '../../lib/format'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import UiButton from '../../components/ui/UiButton.vue'
import { CONFEDERATIONS, FORMATS, TEMPLATES, TEMPLATE_NOTES } from './labels'

type Catalog = paths['/tournaments/catalog']['get']['responses']['200']['content']['application/json']
type Card = components['schemas']['TeamCard']
const router = useRouter()
const catalog = ref<Catalog | null>(null)
const error = ref('')
const sending = ref(false)

const template = ref('world_cup')
const name = ref('')
const format = ref<'league' | 'groups' | 'knockout'>('groups')
const groupCount = ref(8)
const advance = ref(2)
const legs = ref(1)
const picked = ref<Card[]>([])
const myTeam = ref<number | null>(null)
const startsAt = ref(local(addDays(2, 21)))
const liveDraw = ref(true)
const drawAt = ref(local(addDays(1, 21)))
const time = ref('21:00')

const tab = ref<'nations' | 'clubs'>('nations')
const conf = ref('')
const q = ref('')
const found = ref<Card[]>([])

function addDays(n: number, h: number) { const d = new Date(); d.setDate(d.getDate() + n); d.setHours(h, 0, 0, 0); return d }
function local(d: Date) {
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`
}

onMounted(async () => {
  try {
    const { data } = await api.GET('/tournaments/catalog')
    catalog.value = data!
    await apply('world_cup')
  } catch (e) {
    error.value = asApiError(e).message
  }
})

/** A template's teams and shape. */
async function apply(key: string) {
  template.value = key
  const t = catalog.value?.templates.find((x) => x.key === key)
  if (!t) return
  format.value = t.format as typeof format.value
  groupCount.value = t.group_count
  advance.value = t.advance_per_group
  legs.value = t.legs
  myTeam.value = null
  const nations = new Map(catalog.value!.nations.map((n) => [n.id, n]))
  const ids = t.teams.filter((id) => !nations.has(id))
  let clubs: Card[] = []
  if (ids.length) {
    const { data } = await api.GET('/tournaments/clubs', { params: { query: { ids: ids.join(',') } } })
    clubs = data!.clubs
  }
  const byId = new Map(clubs.map((c) => [c.id, c]))
  picked.value = t.teams.map((id) => nations.get(id) ?? byId.get(id)).filter((c): c is Card => !!c)
  tab.value = t.pool === 'clubs' ? 'clubs' : 'nations'
  conf.value = t.confederation ?? ''
}

let timer = 0
watch(q, () => {
  window.clearTimeout(timer)
  timer = window.setTimeout(async () => {
    if (q.value.trim().length < 2) return void (found.value = [])
    const { data } = await api.GET('/tournaments/clubs', { params: { query: { q: q.value.trim() } } })
    found.value = data!.clubs
  }, 300)
})

const isIn = (id: number) => picked.value.some((c) => c.id === id)
function toggle(c: Card) {
  if (isIn(c.id)) {
    picked.value = picked.value.filter((x) => x.id !== c.id)
    if (myTeam.value === c.id) myTeam.value = null
  } else if (picked.value.length < (catalog.value?.limits.max_teams ?? 32)) picked.value.push(c)
}
const nations = computed(() => (catalog.value?.nations ?? []).filter((n) => !conf.value || n.confederation === conf.value))
const count = computed(() => picked.value.length)
/** The group counts that fit: at least two teams in each, and a knockout of two or more after. */
const groupOptions = computed(() => (catalog.value?.limits.group_counts ?? [1, 2, 4, 8]).filter((g) => Math.floor(count.value / g) >= 2))
watch(groupOptions, (opts) => { if (!opts.includes(groupCount.value)) groupCount.value = opts[opts.length - 1] ?? 1 })
const shape = computed(() => {
  if (format.value === 'groups') {
    const per = Math.ceil(count.value / groupCount.value)
    return `${groupCount.value} × ${per} → ${groupCount.value * advance.value}`
  }
  return ''
})

async function create() {
  error.value = ''
  sending.value = true
  try {
    await ensureCsrf()
    const { data } = await api.POST('/tournaments', { body: {
      name: name.value || null, template: template.value as 'custom', teams: picked.value.map((c) => c.id), format: format.value,
      group_count: format.value === 'groups' ? groupCount.value as 1 : null, advance_per_group: format.value === 'groups' ? advance.value as 1 : null,
      legs: format.value === 'knockout' ? null : legs.value as 1, round_times: [time.value], rounds_per_day: 1,
      starts_at: new Date(startsAt.value).toISOString(), draw_at: liveDraw.value ? new Date(drawAt.value).toISOString() : null,
      club_id: myTeam.value, timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    } })
    await router.push({ name: 'tournament', params: { id: data!.tournament.id } })
  } catch (e) {
    error.value = asApiError(e).message
  } finally {
    sending.value = false
  }
}
</script>

<template>
  <form class="flex flex-col gap-5 pb-8" @submit.prevent="create">
    <h1 class="font-display text-3xl font-extrabold">{{ $t('بطولة جديدة') }}</h1>

    <section class="grid grid-cols-2 gap-2 md:grid-cols-3" :aria-label="$t('القالب')">
      <button v-for="t in catalog?.templates ?? []" :key="t.key" type="button" class="flex min-h-[72px] flex-col items-start rounded-2xl border-2 bg-surface p-3 text-start"
        :class="template === t.key ? 'border-gold ring-2 ring-gold/40' : 'border-transparent'" :aria-pressed="template === t.key" @click="apply(t.key)">
        <b>{{ $t(TEMPLATES[t.key]) }}</b>
        <span class="text-xs text-text-muted">{{ $t(TEMPLATE_NOTES[t.key]) }}</span>
      </button>
    </section>

    <label class="flex flex-col gap-1"><span class="font-bold">{{ $t('اسم البطولة') }}</span>
      <input v-model="name" maxlength="60" :placeholder="$t(TEMPLATES[template])" class="h-touch rounded-lg bg-surface-sunk px-3" /></label>

    <section class="flex flex-col gap-2 rounded-2xl bg-surface p-4">
      <div class="flex items-center justify-between"><h2 class="font-bold">{{ $t('الفرق') }} <span class="font-numbers text-gold">{{ count }}</span></h2>
        <button v-if="count" type="button" class="min-h-touch px-2 text-sm text-text-muted" @click="picked = []; myTeam = null">{{ $t('امسح الكل') }}</button></div>
      <ul class="flex flex-wrap gap-2">
        <li v-for="c in picked" :key="c.id">
          <button type="button" class="flex min-h-touch items-center gap-2 rounded-xl bg-surface-raised px-2 text-sm" :aria-label="$t('أزل {v0}', { v0: $nm(c.name) })" @click="toggle(c)">
            <ClubCrest :url="c.crest_url" :code="c.code" :size="24" /><span>{{ $nm(c.name) }}</span><span class="text-text-muted">✕</span></button>
        </li>
      </ul>
      <div class="flex gap-2" role="tablist">
        <button v-for="k in (['nations', 'clubs'] as const)" :key="k" type="button" role="tab" :aria-selected="tab === k" class="min-h-touch rounded-full px-4 text-sm font-bold"
          :class="tab === k ? 'bg-brand' : 'bg-surface-sunk text-text-muted'" @click="tab = k">{{ k === 'nations' ? $t('المنتخبات') : $t('الأندية') }}</button>
      </div>
      <template v-if="tab === 'nations'">
        <div class="flex flex-wrap gap-1">
          <button type="button" class="min-h-[36px] rounded-full px-3 text-xs" :class="!conf ? 'bg-gold text-on-gold' : 'bg-surface-sunk'" @click="conf = ''">{{ $t('الكل') }}</button>
          <button v-for="(label, k) in CONFEDERATIONS" :key="k" type="button" class="min-h-[36px] rounded-full px-3 text-xs" :class="conf === k ? 'bg-gold text-on-gold' : 'bg-surface-sunk'" @click="conf = k">{{ $t(label) }}</button>
        </div>
        <ul class="grid max-h-72 grid-cols-2 gap-1 overflow-y-auto sm:grid-cols-3">
          <li v-for="n in nations" :key="n.id">
            <button type="button" class="flex min-h-touch w-full items-center gap-2 rounded-lg px-2 text-start text-sm" :class="isIn(n.id) ? 'bg-brand/30 ring-1 ring-brand' : 'bg-surface-sunk'" @click="toggle(n)">
              <ClubCrest :url="n.crest_url" :code="n.code" :size="24" /><span class="min-w-0 flex-1 truncate">{{ $nm(n.name) }}</span>
              <span class="font-numbers text-xs text-text-muted">{{ strength(n.strength_cp) }}</span></button>
          </li>
        </ul>
        <details v-if="catalog?.missing.length" class="text-xs text-text-muted">
          <summary class="min-h-touch cursor-pointer py-2">{{ $t('منتخبات لا يكفيها لاعبوها بعد ({n})', { n: catalog.missing.length }) }}</summary>
          <p>{{ $t('تحتاج 14 لاعباً وحارساً على الأقل في البيانات، ويكمّلها الأدمن من محرر البيانات.') }}</p>
          <p class="mt-1">{{ catalog.missing.map((m) => $nm(m.name)).join('، ') }}</p>
        </details>
      </template>
      <template v-else>
        <input v-model="q" type="search" :placeholder="$t('ابحث عن نادٍ')" class="h-touch rounded-lg bg-surface-sunk px-3" />
        <ul class="grid max-h-72 grid-cols-1 gap-1 overflow-y-auto sm:grid-cols-2">
          <li v-for="c in found" :key="c.id">
            <button type="button" class="flex min-h-touch w-full items-center gap-2 rounded-lg px-2 text-start text-sm" :class="isIn(c.id) ? 'bg-brand/30 ring-1 ring-brand' : 'bg-surface-sunk'" @click="toggle(c)">
              <ClubCrest :url="c.crest_url" :code="c.code" :size="24" /><span class="min-w-0 flex-1 truncate">{{ $nm(c.name) }}</span>
              <span class="truncate text-xs text-text-muted">{{ $ln(c.league) }}</span></button>
          </li>
        </ul>
      </template>
    </section>

    <section class="flex flex-col gap-3 rounded-2xl bg-surface p-4">
      <h2 class="font-bold">{{ $t('نظام البطولة') }}</h2>
      <div class="flex flex-wrap gap-2">
        <button v-for="(label, k) in FORMATS" :key="k" type="button" class="min-h-touch rounded-full px-4 text-sm font-bold" :class="format === k ? 'bg-brand' : 'bg-surface-sunk text-text-muted'"
          @click="format = k as typeof format">{{ $t(label) }}</button>
      </div>
      <div v-if="format === 'groups'" class="flex flex-wrap items-center gap-3 text-sm">
        <label class="flex items-center gap-2">{{ $t('المجموعات') }}
          <select v-model.number="groupCount" class="h-touch rounded-lg bg-surface-sunk px-2"><option v-for="g in groupOptions" :key="g" :value="g">{{ g }}</option></select></label>
        <label class="flex items-center gap-2">{{ $t('يتأهل من كل مجموعة') }}
          <select v-model.number="advance" class="h-touch rounded-lg bg-surface-sunk px-2"><option :value="1">1</option><option :value="2">2</option></select></label>
        <span class="font-numbers text-text-muted" dir="ltr">{{ shape }}</span>
      </div>
      <label v-if="format !== 'knockout'" class="flex items-center gap-2 text-sm">{{ $t('المباريات') }}
        <select v-model.number="legs" class="h-touch rounded-lg bg-surface-sunk px-2"><option :value="1">{{ $t('مباراة واحدة') }}</option><option :value="2">{{ $t('ذهاب وإياب') }}</option></select></label>
    </section>

    <section class="flex flex-col gap-3 rounded-2xl bg-surface p-4">
      <label class="flex flex-col gap-1"><span class="font-bold">{{ $t('موعد البداية') }}</span>
        <input v-model="startsAt" type="datetime-local" required dir="ltr" class="h-touch rounded-lg bg-surface-sunk px-3" /></label>
      <label class="flex flex-col gap-1"><span class="font-bold">{{ $t('موعد المباريات يومياً (توقيت القاهرة)') }}</span>
        <input v-model="time" type="time" required dir="ltr" class="h-touch rounded-lg bg-surface-sunk px-3" /></label>
      <label class="flex min-h-touch items-center gap-3"><input v-model="liveDraw" type="checkbox" class="size-5" />
        <span><b>{{ $t('قرعة مباشرة يشاهدها الجميع') }}</b><span class="block text-xs text-text-muted">{{ $t('بدونها تُسحب القرعة عند البداية، ويستطيع الجميع مشاهدتها بعدها.') }}</span></span></label>
      <input v-if="liveDraw" v-model="drawAt" type="datetime-local" dir="ltr" :aria-label="$t('موعد القرعة')" class="h-touch rounded-lg bg-surface-sunk px-3" />
      <label class="flex flex-col gap-1"><span class="font-bold">{{ $t('فريقك') }}</span>
        <select v-model="myTeam" class="h-touch rounded-lg bg-surface-sunk px-3">
          <option :value="null">{{ $t('منظم فقط، بلا فريق') }}</option>
          <option v-for="c in picked" :key="c.id" :value="c.id">{{ $nm(c.name) }}</option>
        </select></label>
    </section>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <UiButton type="submit" block :loading="sending" :disabled="count < 2">{{ $t('أنشئ البطولة') }} · 🪙 <span class="font-numbers">{{ count * (catalog?.limits.coins_per_team ?? 0) }}</span></UiButton>
  </form>
</template>
