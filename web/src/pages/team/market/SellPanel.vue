<script setup lang="ts">
// Selling one of my players [X6, Sprint 21 E5.1, Sprint 23], one panel for the market's «بيع لاعبيّ» and the player's
// card on the squad page [Sprint 39 S1]: withdraw him if listed; sell him now (asked first: it cannot be undone); list
// him at his value; or at my price on a slider between his floor and his cap, with the server's estimate of the wait.
// Prices, fees and limits come from the API (GET /market's `mine`); buying stays in the market only.
// [X84] A player is listed once: once listed, the panel offers only withdraw him (back to the choices) or keep him.
import { computed, ref, watch } from 'vue'
import { uuid } from '../../../lib/uuid'
import { act, busy as isBusy } from '../../../lib/action'
import { nm } from '../../../lib/names'
import { api } from '../../../api/client'
import type { components } from '../../../api/schema'
import UiSlider from '../../../components/ui/UiSlider.vue'
import { intlLocale, t } from '../../../lib/i18n'
import { money } from '../../../lib/format'

type Mine = components['schemas']['Market']['mine'][number]
const props = defineProps<{ leagueId: number; player: Mine }>()
const emit = defineEmits<{ done: [notice: string]; error: [message: string]; keep: [] }>()

const price = ref<number | ''>(props.player.listed?.price ?? props.player.value)
const quote = ref<{ ok: boolean; wait_hours: number } | null>({ ok: true, wait_hours: props.player.wait_hours.value })
let quoting = 0
watch(price, (v) => {
  clearTimeout(quoting)
  if (!v) return (quote.value = null)
  quoting = window.setTimeout(async () => {
    const { data } = await api.GET('/leagues/{league}/market/quote', { params: { path: { league: props.leagueId }, query: { player_id: props.player.id, price: Number(v) } } })
    quote.value = data ?? null
  }, 250)
})

const p = props.player
// About a hundred stops between the floor and the cap, each a round thousand.
const step = Math.max(1000, Math.round((p.cap - p.floor) / 100 / 1000) * 1000)
const nudge = (dir: 1 | -1) => (price.value = Math.min(p.cap, Math.max(p.floor, (Number(price.value) || p.value) + dir * step)))
const fee = () => (p.quick.fee.currency === 'coins' ? t('{v0} كوينز', { v0: p.quick.fee.amount }) : t('{v0} من أموال النادي', { v0: money(p.quick.fee.amount) }))
const when = (iso: string | null) => (iso ? new Date(iso).toLocaleString(intlLocale(), { weekday: 'long', hour: 'numeric', minute: '2-digit' }) : '')
const hours = (h: number) => (h <= 1 ? t('ساعة تقريباً') : h === 2 ? t('ساعتين تقريباً') : h <= 10 ? t('{v0} ساعات تقريباً', { v0: h }) : t('{v0} ساعة تقريباً', { v0: h }))

// [X87] Through lib/action: the result in a toast (with «تراجع» for a withdrawal), only the pressed button waits; the
// parent hears «done» (with no words of its own to repeat) to load the squad again.
const busy = computed(() => isBusy(`sell:${p.id}`))
async function run(call: () => Promise<unknown>, o: Parameters<typeof act>[2]) {
  const r = await act(`sell:${p.id}`, call, { ...o, onError: (m) => emit('error', m) })
  if (r !== undefined) emit('done', '')
}

function sellNow() {
  return run(() => api.POST('/leagues/{league}/market/sell', { params: { path: { league: props.leagueId } }, body: { player_id: p.id, idempotency_key: uuid() } }), {
    confirm: { title: t('بيع {v0} الآن؟', { v0: nm(p.name) }), text: t('تحصل على {v0} مقابل {v1}، ولا تراجع بعد البيع.', { v0: money(p.quick.pays), v1: fee() }), action: t('بع الآن') },
    success: t('بِيع {v0} الآن.', { v0: nm(p.name) }),
  })
}
const listAt = (at: number) => run(() => api.POST('/leagues/{league}/transfers/listings', { params: { path: { league: props.leagueId } }, body: { player_id: p.id, price: at } }), {
  success: t('عُرض {v0} للبيع بـ {v1}. لو لم يشتره مدرب، يشتريه نادٍ من خارج الدوري في موعده.', { v0: nm(p.name), v1: money(at) }),
  undo: () => api.DELETE('/leagues/{league}/transfers/listings/{player}', { params: { path: { league: props.leagueId, player: p.id } } }).then(() => emit('done', '')),
})
// Withdrawn by mistake: «تراجع» lists him again at the same price.
const unlist = () => {
  const at = p.listed?.price ?? p.value
  return run(() => api.DELETE('/leagues/{league}/transfers/listings/{player}', { params: { path: { league: props.leagueId, player: p.id } } }), {
    success: t('سُحب {v0} من البيع.', { v0: nm(p.name) }),
    undo: () => api.POST('/leagues/{league}/transfers/listings', { params: { path: { league: props.leagueId } }, body: { player_id: p.id, price: at } }).then(() => emit('done', '')),
  })
}
</script>

<template>
  <!-- [X84] Listed once only: a listed player shows his listing and two choices, withdraw him or keep him as he is. -->
  <div v-if="player.listed" class="flex flex-col gap-3 rounded-lg border border-gold/40 bg-gold/10 p-3 text-sm" role="group" :aria-label="$t('معروض للبيع')">
    <p class="flex flex-wrap items-center gap-2">
      <span class="rounded-pill bg-gold px-2 py-0.5 text-xs font-bold text-on-gold">{{ $t('معروض للبيع') }}</span>
      <span>{{ $t('بسعر') }} <b dir="ltr" class="font-numbers">{{ money(player.listed.price) }}</b><template v-if="player.listed.sells_at">{{ $t('، ويُباع {v0} إن لم يشتره مدرب.', { v0: when(player.listed.sells_at) }) }}</template></span>
    </p>
    <div class="grid grid-cols-2 gap-2">
      <button type="button" class="h-touch rounded-md border border-danger/50 px-3 font-bold text-danger disabled:opacity-40" :disabled="busy" @click="unlist">{{ busy ? '...' : $t('اسحبه من قائمة الانتقالات') }}</button>
      <button type="button" class="h-touch rounded-md bg-surface-raised px-3 font-bold" :disabled="busy" @click="emit('keep')">{{ $t('اتركه كما هو') }}</button>
    </div>
  </div>
  <div v-else class="flex flex-col gap-3 rounded-lg bg-surface-sunk p-3 text-sm">
    <div class="flex flex-wrap items-center justify-between gap-2">
      <span><b>{{ $t('بيع فوري') }}</b>{{ $t(': تحصل الآن على') }} <b dir="ltr" class="font-numbers text-success">{{ money(player.quick.pays) }}</b> {{ $t('مقابل {v0}.', { v0: fee() }) }}</span>
      <button type="button" class="h-touch rounded-md bg-warning px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="sellNow">{{ busy ? '...' : $t('بع الآن') }}</button>
    </div>
    <!-- [Sprint 23] At his value, while the season's profit room allows it. -->
    <div v-if="player.value <= player.cap" class="flex flex-wrap items-center justify-between gap-2">
      <span><b>{{ $t('بقيمته') }}</b> <b dir="ltr" class="font-numbers">{{ money(player.value) }}</b> {{ $t('بلا رسوم، ويُباع خلال {v0}.', { v0: hours(player.wait_hours.value) }) }}</span>
      <button type="button" class="h-touch rounded-md border border-gold/60 px-4 font-bold text-gold disabled:opacity-40" :disabled="busy" @click="listAt(player.value)">{{ $t('اعرضه بقيمته') }}</button>
    </div>
    <form class="flex flex-col gap-2" @submit.prevent="price && listAt(Number(price))">
      <div class="flex flex-wrap items-baseline justify-between gap-2">
        <b>{{ $t('بسعرك') }}</b>
        <b dir="ltr" class="font-numbers text-lg text-gold">{{ money(Number(price) || player.value) }}</b>
      </div>
      <div class="flex items-center gap-2" dir="ltr">
        <button type="button" class="size-touch shrink-0 rounded-md bg-surface-raised text-xl font-bold disabled:opacity-40" :disabled="Number(price) <= player.floor" :aria-label="$t('أنقص السعر')" @click="nudge(-1)">−</button>
        <UiSlider :model-value="Number(price) || player.value" dir="ltr" :min="player.floor" :max="player.cap" :step="step" :label="$t('سعر {v0}', { v0: player.name })" class="min-w-0 flex-1" @update:model-value="(v: number) => (price = v)" />
        <button type="button" class="size-touch shrink-0 rounded-md bg-surface-raised text-xl font-bold disabled:opacity-40" :disabled="Number(price) >= player.cap" :aria-label="$t('زد السعر')" @click="nudge(1)">+</button>
      </div>
      <div class="flex justify-between text-xs text-text-muted" dir="ltr"><span class="font-numbers">{{ money(player.floor) }}</span><span class="font-numbers">{{ money(player.cap) }}</span></div>
      <div class="flex flex-wrap items-center gap-2">
        <button type="submit" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy || !quote?.ok">{{ $t('اعرضه بهذا السعر') }}</button>
        <span v-if="quote" class="text-xs" :class="quote.ok ? 'text-text-muted' : 'text-danger'">{{ quote.ok ? $t('يُباع خلال {v0}', { v0: hours(quote.wait_hours) }) : $t('خارج حدود سعره') }}</span>
      </div>
    </form>
  </div>
</template>
