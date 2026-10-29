<script setup lang="ts">
// The integrity system [X28], only in a league whose owner switched it on: paying the next match's referee
// (the VAR catches it one time in five), a security check that shows the spies on me and turning one into a
// double agent, and taking my spy's proof of a bribe to the FA. A market ban shows here while it lasts.
import { intlLocale } from '../../lib/i18n'
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import PriceTag from '../../components/ui/PriceTag.vue'
import { money } from '../../lib/format'
import { useWallet } from '../../stores/wallet'

type View = components['responses']['Integrity']['content']['application/json']
const props = defineProps<{ leagueId: number }>()
const view = ref<View | null>(null)
const message = ref('')
const busy = ref(false)
const confirmBribe = ref(false)

const base = () => ({ params: { path: { league: props.leagueId } } })
onMounted(async () => {
  try {
    view.value = (await api.GET('/leagues/{league}/integrity', base())).data!
  } catch {
    view.value = null
  }
})
async function act(fn: () => Promise<View>, done: string) {
  busy.value = true
  message.value = ''
  try {
    await ensureCsrf()
    view.value = await fn()
    message.value = done
    useWallet().load()
  } catch (e) {
    message.value = asApiError(e).message
  }
  busy.value = false
  confirmBribe.value = false
}
const fixture = () => ({ fixture_id: view.value!.fixture!.id })
const bribe = () => act(async () => (await api.POST('/leagues/{league}/integrity/bribe', { ...base(), body: fixture() })).data!, 'دُفع للحكم. انتبه: الفار قد يكشف الأمر.')
const security = () => act(async () => (await api.POST('/leagues/{league}/integrity/security', { ...base(), body: fixture() })).data!, 'تم الفحص الأمني.')
const turn = (spy: number) => act(async () => (await api.POST('/leagues/{league}/integrity/spies/{spy}/turn', { params: { path: { league: props.leagueId, spy } } })).data!,
  'صار جاسوساً مزدوجاً: سيرى الخصم لوحة وهمية.')
const accuse = (spy: number) => act(async () => {
  const data = (await api.POST('/leagues/{league}/integrity/spies/{spy}/accuse', { params: { path: { league: props.leagueId, spy } } })).data!
  return data
}, 'أدانت لجنة الانضباط النادي المرتشي.')
const until = (iso: string) => new Date(iso).toLocaleString(intlLocale(), { weekday: 'short', hour: 'numeric', minute: '2-digit' })
</script>

<template>
  <section v-if="view?.on" class="flex flex-col gap-3 rounded-xl border border-live/30 bg-surface p-4" aria-labelledby="h-integrity">
    <div>
      <h2 id="h-integrity" class="font-display text-xl font-extrabold">{{ $t('ما وراء الكواليس') }}</h2>
    </div>
    <p v-if="message" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm" role="status">{{ $t(message) }}</p>
    <p v-if="view.banned_until" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-[#FF8A8A]" role="alert">{{ $t('ناديك محظور من السوق حتى {v0} بقرار لجنة الانضباط.', { v0: until(view.banned_until) }) }}</p>

    <template v-if="view.fixture">
      <div class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
        <b>{{ $t('الحكم في مباراة {v0}', { v0: $nm(view.fixture.opponent) }) }}</b>
        <p v-if="view.bribe.paid" class="text-sm font-bold text-gold">{{ $t('دفعت للحكم في هذه المباراة.') }}</p>
        <template v-else>
          <button v-if="!confirmBribe" type="button" class="h-touch rounded-md border border-live/50 px-4 text-sm font-bold text-[#FF8A8A]" @click="confirmBribe = true">
            {{ $t('ادفع للحكم · {v0} +', { v0: money(view.bribe.money) }) }} <PriceTag :amount="view.bribe.extra.amount" :currency="view.bribe.extra.currency" />
          </button>
          <div v-else class="flex gap-2">
            <button type="button" class="h-touch flex-1 rounded-md bg-live px-3 text-sm font-bold text-white disabled:opacity-50" :disabled="busy" @click="bribe">{{ $t('متأكد، ادفع') }}</button>
            <button type="button" class="h-touch flex-1 rounded-md bg-surface px-3 text-sm" @click="confirmBribe = false">{{ $t('تراجع') }}</button>
          </div>
        </template>
      </div>

      <div class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
        <b>{{ $t('الجواسيس عليك') }}</b>
        <template v-if="view.security.sees">
          <p v-if="!view.spies_on_me.length" class="text-sm text-text-muted">{{ $t('لا جواسيس على مباراتك القادمة حتى الآن.') }}</p>
          <div v-for="s in view.spies_on_me" :key="s.id" class="flex items-center justify-between gap-2 text-sm">
            <span>{{ $t('جاسوس من') }} <b>{{ s.club }}</b></span>
            <span v-if="s.turned" class="text-gold">{{ $t('مزدوج ✓') }}</span>
            <button v-else type="button" class="h-touch rounded-md bg-gold px-3 font-bold text-on-gold disabled:opacity-50" :disabled="busy" @click="turn(s.id)">
              {{ $t('اجعله مزدوجاً ·') }} <PriceTag :amount="view.double_agent.amount" :currency="view.double_agent.currency" />
            </button>
          </div>
        </template>
        <template v-else>
          <button type="button" class="h-touch self-start rounded-md bg-surface px-4 text-sm font-bold disabled:opacity-50" :disabled="busy" @click="security">
            {{ $t('فحص أمني ·') }} <PriceTag :amount="view.security.cost.amount" :currency="view.security.cost.currency" />
          </button>
        </template>
      </div>
    </template>

    <div v-if="view.proofs.length" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
      <b>{{ $t('أدلة جواسيسك') }}</b>
      <div v-for="p in view.proofs" :key="p.spy_report_id" class="flex items-center justify-between gap-2 text-sm">
        <span>{{ $t('رشوة من') }} <b>{{ p.club }}</b></span>
        <span v-if="p.filed" class="text-text-muted">{{ $t('فُصل فيها') }}</span>
        <button v-else type="button" class="h-touch rounded-md bg-live px-3 font-bold text-white disabled:opacity-50" :disabled="busy" @click="accuse(p.spy_report_id)">{{ $t('بلّغ لجنة الانضباط') }}</button>
      </div>
    </div>
  </section>
</template>
