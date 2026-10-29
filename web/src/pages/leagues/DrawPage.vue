<script setup lang="ts">
// The live draw [X26]: before it, the time and the announced hash; at its time the slots are revealed one by
// one on the server clock (every member sees the same slot at the same moment), then the first round and the
// cup's ties, and the seed with how to check it. The committee is the league's owner.
import { intlLocale } from '../../lib/i18n'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import ClubCrest from '../../components/ui/ClubCrest.vue'
import UiButton from '../../components/ui/UiButton.vue'

type Draw = components['responses']['Draw']['content']['application/json']
type Card = { id: number; name: string; code: string; crest_url: string; coach?: string | null }
const props = defineProps<{ id: string }>()
const draw = ref<Draw | null>(null)
const error = ref('')
const message = ref('')
const when = ref('')
let skew = 0
const now = ref(Date.now())
let timer = 0
let poll = 0

async function load() {
  try {
    const { data } = await api.GET('/leagues/{league}/draw', { params: { path: { league: Number(props.id) } } })
    draw.value = data!
    skew = data!.server_now - Date.now()
  } catch (e) {
    error.value = asApiError(e).message
  }
}
onMounted(async () => {
  await load()
  timer = window.setInterval(() => (now.value = Date.now()), 250)
  // Waiting for the draw: ask again around its time.
  poll = window.setInterval(() => {
    const d = draw.value
    if (d && !d.drawn_at && d.draw_at && new Date(d.draw_at).getTime() <= serverNow() + 1000) void load()
  }, 3000)
})
onBeforeUnmount(() => (window.clearInterval(timer), window.clearInterval(poll)))
const serverNow = () => now.value + skew

const countdown = computed(() => {
  if (!draw.value?.draw_at || draw.value.drawn_at) return ''
  const s = Math.max(0, Math.ceil((new Date(draw.value.draw_at).getTime() - serverNow()) / 1000))
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60
  return (h ? `${h}:` : '') + `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
})
// How many slots are shown now, on the shared clock.
const shown = computed(() => {
  const d = draw.value
  if (!d?.drawn_at) return 0
  return Math.min(d.slots.length, Math.floor((serverNow() - new Date(d.drawn_at).getTime()) / d.reveal_ms) + 1)
})
const done = computed(() => !!draw.value && draw.value.slots.length > 0 && shown.value >= draw.value.slots.length)
const card = (c: unknown) => c as Card

async function schedule() {
  message.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/draw', { params: { path: { league: Number(props.id) } }, body: { draw_at: new Date(when.value).toISOString() } })
    draw.value = data!
    message.value = 'حُدد موعد القرعة.'
  } catch (e) {
    message.value = asApiError(e).message
  }
}
const local = (iso: string) => new Date(iso).toLocaleString(intlLocale(), { weekday: 'long', day: 'numeric', month: 'long', hour: 'numeric', minute: '2-digit' })
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <header class="flex items-center justify-between gap-3">
      <h1 class="font-display text-3xl font-extrabold">{{ $t('القرعة المباشرة') }}</h1>
      <RouterLink :to="{ name: 'league-home', params: { id } }" class="text-sm font-bold text-gold">{{ $t('الدوري') }}</RouterLink>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <template v-if="draw">
      <section class="flex flex-col items-center gap-2 rounded-2xl border border-gold/30 bg-surface p-5 text-center">
        <template v-if="!draw.draw_at">
          <p class="text-text-muted">{{ $t('لم يحدد منشئ الدوري موعد القرعة بعد. بدونها تُرتّب الأندية بقوتها عند البداية.') }}</p>
        </template>
        <template v-else-if="!draw.drawn_at">
          <p class="text-sm text-text-muted">{{ $t('تُسحب القرعة {v0}', { v0: local(draw.draw_at) }) }}</p>
          <p class="font-numbers text-5xl font-bold text-gold" dir="ltr" aria-live="polite">{{ countdown }}</p>
        </template>
        <template v-else>
          <p class="flex items-center gap-2 font-bold"><span class="size-2 animate-pulse rounded-full bg-live" v-if="!done" />{{ done ? $t('انتهت القرعة') : $t('القرعة تُسحب الآن') }}</p>
        </template>
        <p class="text-xs text-text-muted">{{ $t('اللجنة المنظمة:') }} <b class="text-text">{{ draw.committee.owner }}</b> {{ $t('(منشئ الدوري)') }}</p>
        <p v-if="draw.commit" class="w-full break-all rounded-lg bg-surface-sunk px-3 py-2 text-start text-xs text-text-muted">
          {{ $t('بصمة القرعة المعلنة قبلها (SHA-256):') }} <code dir="ltr" class="block font-numbers text-text">{{ draw.commit }}</code>
        </p>
      </section>

      <form v-if="draw.can_schedule" class="flex flex-col gap-2 rounded-xl bg-surface p-4" @submit.prevent="schedule">
        <label for="draw-at" class="font-bold">{{ draw.draw_at ? $t('غيّر موعد القرعة') : $t('حدد موعد القرعة') }}</label>
        <p class="text-xs text-text-muted">{{ $t('قبل بداية الدوري ({v0}). تُعلن البصمة الآن، ولا يمكن لأحد تغيير النتيجة بعدها.', { v0: local(draw.starts_at) }) }}</p>
        <div class="flex gap-2">
          <input id="draw-at" v-model="when" type="datetime-local" required class="h-touch min-w-0 flex-1 rounded-lg bg-surface-sunk px-3" dir="ltr" />
          <UiButton type="submit">{{ $t('حفظ') }}</UiButton>
        </div>
        <p v-if="message" class="text-sm" role="status">{{ $t(message) }}</p>
      </form>

      <section v-if="draw.drawn_at" class="flex flex-col gap-2" aria-labelledby="h-slots">
        <h2 id="h-slots" class="font-display text-xl font-extrabold">{{ $t('خانات الدوري') }}</h2>
        <ol class="grid gap-2 sm:grid-cols-2">
          <li v-for="(s, i) in draw.slots" :key="s.slot" class="flex min-h-touch items-center gap-3 rounded-xl p-3 transition-all duration-500"
            :class="i < shown ? 'bg-surface' : 'bg-surface-sunk opacity-60'">
            <span class="grid size-9 shrink-0 place-items-center rounded-full bg-gold/15 font-numbers font-bold text-gold">{{ s.slot }}</span>
            <template v-if="i < shown">
              <ClubCrest :url="card(s.club).crest_url" :code="card(s.club).code" :size="36" />
              <span class="min-w-0 flex-1"><b class="block truncate">{{ $nm(card(s.club).name) }}</b><span class="block truncate text-xs text-text-muted">{{ card(s.club).coach ?? $t('الحاسوب') }}</span></span>
            </template>
            <span v-else class="text-sm text-text-muted">{{ i === shown ? $t('يُسحب…') : $t('؟') }}</span>
          </li>
        </ol>
      </section>

      <template v-if="done">
        <section class="flex flex-col gap-2 rounded-xl bg-surface p-4" aria-labelledby="h-first">
          <h2 id="h-first" class="font-display text-lg font-extrabold">{{ $t('الجولة الأولى') }}</h2>
          <p v-for="(m, i) in draw.league_round" :key="i" class="flex items-center justify-between gap-2 rounded-lg bg-surface-sunk px-3 py-2 text-sm">
            <b class="truncate">{{ $nm(card(m.home)?.name) }}</b><span class="text-text-muted">{{ $t('ضد') }}</span><b class="truncate">{{ $nm(card(m.away)?.name) }}</b>
          </p>
        </section>
        <section v-if="draw.cup_round.length" class="flex flex-col gap-2 rounded-xl bg-surface p-4" aria-labelledby="h-cup">
          <h2 id="h-cup" class="font-display text-lg font-extrabold">{{ $t('الدور الأول من الكأس') }}</h2>
          <p v-for="(m, i) in draw.cup_round" :key="i" class="flex items-center justify-between gap-2 rounded-lg bg-surface-sunk px-3 py-2 text-sm">
            <b class="truncate">{{ $nm(card(m.home)?.name) }}</b><span class="text-text-muted">{{ $t('ضد') }}</span><b class="truncate">{{ $nm(card(m.away)?.name) }}</b>
          </p>
        </section>
        <p class="rounded-lg bg-surface-sunk px-3 py-2 text-xs text-text-muted">
          {{ $t('البذرة') }} <b class="font-numbers text-text" dir="ltr">{{ draw.seed }}</b>{{ $t('. تحقق بنفسك: SHA-256 للنص') }}
          <code dir="ltr" class="font-numbers text-text">legends-draw:{{ id }}:{{ draw.seed }}</code> {{ $t('يساوي البصمة المعلنة أعلاه.') }}
        </p>
      </template>
    </template>
  </div>
</template>
