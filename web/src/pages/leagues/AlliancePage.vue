<script setup lang="ts">
// The alliance tournament [X27]: the owner's request (it waits for the developers), the two alliances with their
// captains, and the rounds. Team-mates are not played: their captain picks who goes on, and a title left to one
// alliance is its own without another match.
import { intlLocale } from '../../lib/i18n'
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import UiButton from '../../components/ui/UiButton.vue'
import UiChip from '../../components/ui/UiChip.vue'
import EmptyState from '../../components/ui/EmptyState.vue'

type View = components['responses']['Alliance']['content']['application/json']
type Card = { id: number; name: string; code: string; coach?: string | null; crest_url: string }
const props = defineProps<{ id: string }>()
const view = ref<View | null>(null)
const error = ref('')
const message = ref('')
const busy = ref(false)
const form = ref({ name: '', captain_a: '', captain_b: '', size: 5, first_round_at: '' })

const path = computed(() => ({ params: { path: { league: Number(props.id) } } }))
async function load() {
  try {
    view.value = (await api.GET('/leagues/{league}/alliance', path.value)).data!
    form.value.size = view.value.default_size
  } catch (e) {
    error.value = asApiError(e).message
  }
}
onMounted(load)
const t = computed(() => view.value?.tournament ?? null)
const rounds = computed(() => {
  const by = new Map<number, NonNullable<typeof t.value>['ties']>()
  for (const x of t.value?.ties ?? []) by.set(x.round, [...(by.get(x.round) ?? []), x])
  return [...by.entries()]
})
const card = (c: unknown) => c as Card | null
const NAMES = { a: 'التحالف الأول', b: 'التحالف الثاني' } as const
const STATUS: Record<string, [string, 'gold' | 'neutral' | 'win' | 'loss']> = {
  pending: ['بانتظار اعتماد المطورين', 'gold'], rejected: ['لم يُعتمد', 'loss'], running: ['جارية', 'win'], finished: ['انتهت', 'neutral'],
}
const KIND: Record<string, string> = { bye: 'يتأهل مباشرة', captain: 'زميلان: يختار القائد', walkover: 'نهائي بين زميلين: اللقب لتحالفهما' }

async function create() {
  busy.value = true
  message.value = ''
  try {
    await ensureCsrf()
    view.value = (await api.POST('/leagues/{league}/alliance', { ...path.value, body: { ...form.value, first_round_at: new Date(form.value.first_round_at).toISOString() } })).data!
    message.value = 'أُرسلت البطولة للمطورين، وتبدأ بعد اعتمادها.'
  } catch (e) {
    message.value = asApiError(e).message
  }
  busy.value = false
}
async function decide(tie: number, winner: number) {
  busy.value = true
  try {
    await ensureCsrf()
    view.value = (await api.POST('/leagues/{league}/alliance/ties/{tie}/decide', { params: { path: { league: Number(props.id), tie } }, body: { winner } })).data!
  } catch (e) {
    message.value = asApiError(e).message
  }
  busy.value = false
}
const when = (iso: string) => new Date(iso).toLocaleString(intlLocale(), { weekday: 'short', day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' })
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <header class="flex items-center justify-between gap-3">
      <h1 class="font-display text-3xl font-extrabold">{{ $t('بطولة التحالفات') }}</h1>
      <RouterLink :to="{ name: 'league-home', params: { id } }" class="text-sm font-bold text-gold">{{ $t('الدوري') }}</RouterLink>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-if="message" class="rounded-lg bg-surface px-3 py-2 text-sm" role="status">{{ $t(message) }}</p>

    <!-- [Sprint 30 P5] Never a blank page: a waiting card while it loads. -->
    <div v-if="!view && !error" class="h-40 animate-pulse rounded-2xl bg-surface" :aria-label="$t('يحمّل…')" role="status" />
    <template v-if="view">
      <section v-if="t" class="flex flex-col gap-3 rounded-2xl border border-gold/30 bg-surface p-4">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <h2 class="font-display text-2xl font-extrabold">{{ $nm(t.name) }}</h2>
          <UiChip :tone="STATUS[t.status][1]">{{ $t(STATUS[t.status][0]) }}</UiChip>
        </div>
        <p v-if="t.status === 'finished' && t.winner" class="rounded-lg bg-gold/15 px-3 py-2 text-center font-display text-lg font-extrabold text-gold">{{ $t('🏆 البطل: {v0}', { v0: NAMES[t.winner] }) }}</p>
        <p v-if="t.review_note" class="text-sm text-text-muted">{{ $t('ملاحظة المطورين: {v0}', { v0: t.review_note }) }}</p>
        <p class="text-sm text-text-muted">{{ $t('الدور الأول {v0} · {v1} ضد {v2}', { v0: when(t.first_round_at), v1: t.size, v2: t.size }) }}</p>
        <div class="grid gap-3 md:grid-cols-2">
          <div v-for="side in (['a', 'b'] as const)" :key="side" class="flex flex-col gap-2 rounded-xl bg-surface-sunk p-3" :class="t.winner === side ? 'ring-2 ring-gold' : ''">
            <h3 class="flex items-center justify-between font-bold"><span>{{ $t(NAMES[side]) }}</span><span class="text-xs text-text-muted">{{ $t('القائد: {v0}', { v0: t.alliances[side].captain }) }}</span></h3>
            <p v-for="c in t.alliances[side].clubs" :key="card(c)!.id" class="flex items-center gap-2 text-sm">
              <ClubCrest :url="card(c)!.crest_url" :code="card(c)!.code" :size="26" />
              <b class="min-w-0 flex-1 truncate">{{ $nm(card(c)!.name) }}</b><span class="truncate text-xs text-text-muted">{{ card(c)!.coach }}</span>
            </p>
          </div>
        </div>
      </section>

      <section v-for="[round, ties] in rounds" :key="round" class="flex flex-col gap-2" :aria-label="$t('الدور {v0}', { v0: round })">
        <h2 class="font-display text-xl font-extrabold">{{ $t('الدور {v0}', { v0: round }) }} <span class="text-sm font-normal text-text-muted">{{ when(ties[0].scheduled_at) }}</span></h2>
        <article v-for="x in ties" :key="x.id" class="flex flex-col gap-2 rounded-xl bg-surface p-3">
          <div class="flex items-center gap-2">
            <b class="min-w-0 flex-1 truncate" :class="x.winner_id === card(x.home)?.id ? 'text-gold' : ''">{{ $nm(card(x.home)?.name) }}</b>
            <span v-if="x.score" class="font-numbers font-bold" dir="ltr">{{ x.score.home }} - {{ x.score.away }}</span>
            <span v-else-if="x.kind === 'match'" class="text-sm text-text-muted">{{ $t('ضد') }}</span>
            <b v-if="x.away" class="min-w-0 flex-1 truncate text-end" :class="x.winner_id === card(x.away)?.id ? 'text-gold' : ''">{{ $nm(card(x.away)?.name) }}</b>
          </div>
          <p v-if="KIND[x.kind]" class="text-xs text-text-muted">{{ $t(KIND[x.kind]) }}</p>
          <RouterLink v-if="x.match_id" :to="{ name: 'league-match', params: { id: x.match_id } }" class="text-sm font-bold text-gold">{{ x.status === 'finished' ? $t('الملخص') : $t('تابع المباراة') }}</RouterLink>
          <div v-if="x.kind === 'captain' && !x.winner_id && t?.captain_of === x.alliance" class="grid grid-cols-2 gap-2">
            <UiButton v-for="c in [card(x.home)!, card(x.away)!]" :key="c.id" variant="outline" :disabled="busy" @click="decide(x.id, c.id)">{{ $t('يتأهل {v0}', { v0: $nm(c.name) }) }}</UiButton>
          </div>
        </article>
      </section>

      <form v-if="view.can_create" class="flex flex-col gap-3 rounded-xl bg-surface p-4" @submit.prevent="create">
        <h2 class="font-display text-xl font-extrabold">{{ $t('أنشئ بطولة تحالفات') }}</h2>
        <label class="flex flex-col gap-1 text-sm">{{ $t('اسم البطولة') }}<input v-model="form.name" required minlength="3" maxlength="40" class="h-touch rounded-lg bg-surface-sunk px-3" /></label>
        <div class="grid grid-cols-2 gap-2">
          <label v-for="k in (['captain_a', 'captain_b'] as const)" :key="k" class="flex flex-col gap-1 text-sm">{{ $t('قائد {v0}', { v0: k === 'captain_a' ? NAMES.a : NAMES.b }) }}
            <select v-model="form[k]" required class="h-touch rounded-lg bg-surface-sunk px-2" dir="ltr">
              <option value="" disabled>{{ $t('اختر') }}</option>
              <option v-for="c in view.coaches" :key="c.username ?? c.name" :value="c.username">{{ c.username }} · {{ $nm(c.name) }}</option>
            </select>
          </label>
        </div>
        <label class="flex flex-col gap-1 text-sm">{{ $t('عدد كل تحالف:') }} <b class="font-numbers text-gold">{{ $t('{v0} ضد {v1}', { v0: form.size, v1: form.size }) }}</b>
          <input v-model.number="form.size" type="range" :min="view.sizes[0]" :max="view.sizes[1]" class="accent-gold" />
        </label>
        <label class="flex flex-col gap-1 text-sm">{{ $t('موعد الدور الأول') }}<input v-model="form.first_round_at" type="datetime-local" required class="h-touch rounded-lg bg-surface-sunk px-3" dir="ltr" /></label>
        <UiButton type="submit" :disabled="busy">{{ $t('أرسل للاعتماد') }}</UiButton>
      </form>
      <EmptyState v-else-if="!t" icon="trophy" :title="$t('لا بطولة تحالفات في هذا الدوري بعد')" :text="$t('ينشئها منشئ الدوري: تحالفان من مدربي الدوري بقائد لكل منهما، وتبدأ بعد اعتماد المطورين.')"
        :cta="{ label: 'عُد إلى الدوري', to: `/leagues/${id}` }" />
    </template>
  </div>
</template>
