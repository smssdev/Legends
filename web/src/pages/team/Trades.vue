<script setup lang="ts">
// Trades between coaches (Sprint 25 W1), inside the market: the transfer list, my offers in and out, and the
// composer for a new offer or a counter. Every rule (the fair range, the season limits) is checked by the API,
// which answers in Arabic; the screen only gathers the terms.
// [X91] Simpler (the owner's request): «عرض سريع» from the list sends his asking price in one tap (with «تراجع» to
// withdraw it); the composer starts at the fair money for what is chosen, with chips for it, +10% and +25%, and says
// at once whether the offer is in the allowed range. Every action through lib/action (its button waits, a toast).
import UiSlider from '../../components/ui/UiSlider.vue'
import { uuid } from '../../lib/uuid'
import UiDialog from '../../components/ui/UiDialog.vue'
import UiToggle from '../../components/ui/UiToggle.vue'
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { api, asApiError } from '../../api/client'
import { act, busy as isBusy } from '../../lib/action'
import { nm } from '../../lib/names'
import { t as tr } from '../../lib/i18n'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import Character from '../../components/characters/Character.vue'
import { count, money, type Line } from '../../lib/format'

type T = components['schemas']['Transfers']
type Offer = components['schemas']['TransferOffer']
type Mine = components['schemas']['Market']['mine'][number]
const props = defineProps<{ leagueId: number; view: 'list' | 'offers'; mine: Mine[] }>()
const emit = defineEmits<{ changed: [] }>()

const t = ref<T | null>(null)
const error = ref('')
const STATUS: Record<string, string> = { pending: 'بانتظار الرد', accepted: 'تمت', rejected: 'رُفض', countered: 'رُد عليه بعرض', cancelled: 'أُلغي', expired: 'انتهت مدته' }
const path = computed(() => ({ path: { league: props.leagueId } }))

async function load() {
  try {
    const { data } = await api.GET('/leagues/{league}/transfers', { params: path.value })
    t.value = data!
  } catch (e) {
    error.value = asApiError(e).message
  }
}

async function run<R>(key: string, fn: () => Promise<R>, o: Parameters<typeof act<R>>[2] = {}) {
  const r = await act(key, fn, o)
  if (r !== undefined) { await load(); emit('changed') }
  return r
}
const withdraw = (id: number) => api.POST('/leagues/{league}/transfers/offers/{offer}/cancel' as any, { params: { path: { league: props.leagueId, offer: id } } }).then(load)

// [X84] Listing a player is in «بيع لاعبيّ» only (SellPanel.vue).

// ---------------------------------------------------------------- the composer
type Squad = { id: number; name: string; position: string; line: string; overall: number; value: number }
const draft = reactive({ open: false, to: 0, toName: '', counterOf: 0, money: 0, sellOn: 0, in: [] as number[], out: [] as number[], touched: false, more: false })
const theirs = ref<Squad[]>([])
async function compose(to: number, toName: string, opts: { in?: number[]; out?: number[]; money?: number; counterOf?: number } = {}) {
  Object.assign(draft, { open: true, to, toName, counterOf: opts.counterOf ?? 0, money: opts.money ?? 0, sellOn: 0, in: opts.in ?? [], out: opts.out ?? [], touched: !!opts.money, more: false })
  theirs.value = []
  try {
    const { data } = await api.GET('/leagues/{league}/clubs/{club}', { params: { path: { league: props.leagueId, club: to } } })
    theirs.value = (data as any).players
  } catch (e) {
    error.value = asApiError(e).message
  }
}
const toggle = (list: number[], id: number) => (list.includes(id) ? list.splice(list.indexOf(id), 1) : list.length < 5 && list.push(id))
const wantValue = computed(() => theirs.value.filter((p) => draft.in.includes(p.id)).reduce((s, p) => s + p.value, 0))
const giveValue = computed(() => props.mine.filter((p) => draft.out.includes(p.id)).reduce((s, p) => s + p.value, 0))
// The allowed range (the API's rule, said here before sending): what I give, money and players, from half to twice
// the value of what I ask for.
const fair = computed(() => Math.max(0, wantValue.value - giveValue.value))
const range = computed(() => ({ min: Math.max(0, Math.ceil(wantValue.value / 2) - giveValue.value), max: Math.max(0, wantValue.value * 2 - giveValue.value) }))
const inRange = computed(() => !draft.in.length || ((draft.money || 0) >= range.value.min && (draft.money || 0) <= range.value.max))
const presets = computed(() => [
  { label: 'السعر العادل', v: fair.value },
  { label: '+10%', v: Math.round((fair.value * 11) / 10 / 1000) * 1000 },
  { label: '+25%', v: Math.round((fair.value * 5) / 4 / 1000) * 1000 },
].filter((x, i, a) => x.v <= range.value.max && a.findIndex((y) => y.v === x.v) === i))
// Until the coach types his own number, the money follows the fair price of what is chosen.
watch(fair, (v) => { if (draft.open && !draft.touched) draft.money = v })
const pick = (v: number) => { draft.money = v; draft.touched = true }
const sendKey = computed(() => `offer:${draft.to}`)
async function send() {
  const body = { money: draft.money || 0, in: draft.in, out: draft.out, idempotency_key: uuid() }
  const name = nm(draft.toName)
  const r = await run(sendKey.value, () => (draft.counterOf
    ? api.POST('/leagues/{league}/transfers/offers/{offer}/counter', { params: { path: { league: props.leagueId, offer: draft.counterOf } }, body })
    : api.POST('/leagues/{league}/transfers/offers', { params: path.value, body: { ...body, to_club_id: draft.to, sell_on_bp: draft.sellOn * 100 } })) as Promise<{ data?: { offer?: Offer } }>, {
    success: draft.counterOf ? tr('أُرسل ردك إلى {v0}.', { v0: name }) : tr('أُرسل عرضك إلى {v0}.', { v0: name }),
  })
  if (r !== undefined) draft.open = false
}
// [X91] One tap from the list: his asking price for him alone; «تراجع» withdraws it.
type Listing = T['listings'][number]
function quick(l: Listing) {
  let id = 0
  return run(`quick:${l.player.id}`, async () => {
    const r = await api.POST('/leagues/{league}/transfers/offers', { params: path.value, body: { to_club_id: l.club.id, money: l.price, in: [l.player.id], out: [], sell_on_bp: 0, idempotency_key: uuid() } })
    id = (r as { data?: { offer?: Offer } }).data?.offer?.id ?? 0
    return r
  }, {
    success: tr('أُرسل عرضك {v0} على {v1} إلى {v2}.', { v0: money(l.price), v1: nm(l.player.name), v2: nm(l.club.name) }),
    undo: () => (id ? withdraw(id) : Promise.resolve()),
  })
}
// A counter: I want what he offered of his, and I give what he asked of mine.
const counter = (o: Offer) => compose(o.from.id, o.from.name, { counterOf: o.id, in: o.out.map((p) => p.id), out: o.in.map((p) => p.id), money: 0 })
// Accepting cannot be undone (the players move): asked first; rejecting and withdrawing go at once.
const decide = (o: Offer, what: 'accept' | 'reject' | 'cancel') => run(`deal:${o.id}`,
  () => api.POST(`/leagues/{league}/transfers/offers/{offer}/${what}` as any, { params: { path: { league: props.leagueId, offer: o.id } } }), {
    success: tr({ accept: 'تمت الصفقة.', reject: 'رُفض العرض.', cancel: 'سُحب العرض.' }[what]),
    confirm: what === 'accept' ? { title: tr('تقبل عرض {v0}؟', { v0: nm(o.from.name) }), text: tr('تنتقل الأموال واللاعبون الآن، ولا تراجع بعد القبول.'), action: tr('قبول'), tone: 'gold' } : undefined,
  })
const busy = (key: string) => isBusy(key)
const pending = computed(() => (t.value?.offers ?? []).filter((o) => o.status === 'pending'))
const done = computed(() => (t.value?.offers ?? []).filter((o) => o.status !== 'pending'))
const hours = (iso: string) => Math.max(0, Math.round((new Date(iso).getTime() - Date.now()) / 3_600_000))

watch(() => props.view, () => (error.value = ''))
onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-3">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <template v-if="t && view === 'list'">
      <section :aria-label="$t('قائمة الانتقالات')" class="rounded-xl bg-surface p-2">
        <h2 class="px-2 pt-2 font-display text-lg font-bold">{{ $t('المعروضون للبيع') }}</h2>
        <p v-if="!t.listings.filter((l) => !l.mine).length" class="p-3 text-sm text-text-muted">{{ $t('لم يعرض مدرب لاعباً بعد.') }}</p>
        <ul>
          <li v-for="l in t.listings.filter((l) => !l.mine)" :key="l.player.id" class="flex items-center gap-3 border-t border-text/5 px-2 py-2 first:border-0">
            <LineBadge :line="l.player.line as Line" />
            <span class="min-w-0 flex-1"><b class="block truncate" dir="auto">{{ $nm(l.player.name) }}</b><span class="text-xs text-text-muted">{{ $t('{v0} · {v1} · {v2} سنة · قيمته {v3}', { v0: $nm(l.club.name), v1: l.player.position, v2: l.player.age, v3: money(l.player.value) }) }}</span></span>
            <span class="w-10 text-center font-numbers text-xl">{{ l.player.overall }}</span>
            <span class="w-20 text-end font-numbers text-lg font-bold" dir="ltr">{{ money(l.price) }}</span>
            <span class="flex flex-col gap-1 sm:flex-row">
              <button type="button" class="h-touch rounded-md bg-gold px-3 font-bold text-on-gold disabled:opacity-40" :disabled="!!t.closed || busy(`quick:${l.player.id}`)" :title="$t('عرض بسعره مباشرة')" @click="quick(l)">{{ busy(`quick:${l.player.id}`) ? '...' : $t('اشترِه بسعره') }}</button>
              <button type="button" class="h-touch rounded-md border border-gold/60 px-3 text-sm font-bold text-gold disabled:opacity-40" :disabled="!!t.closed" @click="compose(l.club.id, l.club.name, { in: [l.player.id], money: l.price })">{{ $t('فاوض') }}</button>
            </span>
          </li>
        </ul>
      </section>
      <!-- [X84] Listing a player is in «بيع لاعبيّ» only (once, with withdraw or keep): one way to do one thing. -->
      <p class="rounded-xl bg-surface px-4 py-3 text-sm text-text-muted">{{ $t('لعرض لاعب للبيع: تبويب «بيع لاعبيّ» في السوق، أو بطاقة اللاعب في صفحة الفريق.') }}</p>
    </template>

    <!-- [Sprint 48 T6] The negotiations (the owner's screenshots, our own look): the offers in the middle, and at the side
         the assistant coach with how a deal between coaches goes. -->
    <div v-if="t && view === 'offers'" class="grid items-start gap-4 lg:grid-cols-[minmax(0,1fr)_20rem]">
     <div class="flex min-w-0 flex-col gap-3">
      <div class="flex flex-wrap items-center gap-2">
        <label class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">{{ $t('عرض جديد إلى') }}
          <select class="h-8 bg-transparent font-semibold text-text" :disabled="!!t.closed" @change="(e) => { const c = t!.clubs.find((c) => c.id === Number((e.target as HTMLSelectElement).value)); if (c) compose(c.id, c.name); (e.target as HTMLSelectElement).value = '' }">
            <option value="">{{ $t('اختر مدرباً') }}</option><option v-for="c in t.clubs" :key="c.id" :value="c.id">{{ $nm(c.name) }}</option>
          </select>
        </label>
        <span class="text-xs text-text-muted">{{ $t('ما يُدفع فوق القيمة بين ناديين في الموسم لا يتجاوز {v0}', { v0: count(t.pair_cap) }) }}</span>
      </div>
      <div v-if="!t.offers.length" class="deals-empty flex min-h-72 flex-col items-center justify-center gap-3 rounded-2xl p-6 text-center">
        <p class="font-display text-xl font-extrabold text-white">{{ $t('هنا تظهر مفاوضاتك الجارية') }}</p>
        <p class="max-w-sm text-sm text-white/80">{{ $t('اختر مدرباً من القائمة أعلاه وابدأ أول عرض.') }}</p>
      </div>
      <article v-for="o in [...pending, ...done]" :key="o.id" class="flex flex-col gap-2 rounded-xl border bg-surface p-4" :class="o.status === 'pending' && o.incoming ? 'border-gold/50' : 'border-transparent'">
        <div class="flex flex-wrap items-center gap-2 text-sm">
          <b>{{ o.incoming ? $t('عرض وارد من {v0}', { v0: o.from.name }) : $t('عرضك إلى {v0}', { v0: o.to.name }) }}</b>
          <span class="rounded-pill bg-text/10 px-2 py-0.5 text-xs">{{ $t(STATUS[o.status]) }}</span>
          <span v-if="o.status === 'pending'" class="text-xs text-text-muted">{{ $t('ينتهي بعد {v0} ساعة', { v0: hours(o.expires_at) }) }}</span>
        </div>
        <div class="grid gap-2 sm:grid-cols-2">
          <div class="rounded-lg bg-surface-sunk p-3 text-sm">
            <span class="text-xs text-text-muted">{{ o.incoming ? $t('يريد منك') : $t('تطلب') }}</span>
            <div v-for="p in o.in" :key="p.id" class="mt-1 flex items-center gap-2"><LineBadge :line="p.line as Line" /><span class="flex-1 truncate">{{ $nm(p.name) }}</span><span class="font-numbers" dir="ltr">{{ p.overall }} · {{ money(p.value) }}</span></div>
          </div>
          <div class="rounded-lg bg-surface-sunk p-3 text-sm">
            <span class="text-xs text-text-muted">{{ o.incoming ? $t('يعطيك') : $t('تعطي') }}</span>
            <div v-if="o.money" class="mt-1 font-numbers text-lg text-gold" dir="ltr">{{ count(o.money) }}</div>
            <div v-for="p in o.out" :key="p.id" class="mt-1 flex items-center gap-2"><LineBadge :line="p.line as Line" /><span class="flex-1 truncate">{{ $nm(p.name) }}</span><span class="font-numbers" dir="ltr">{{ p.overall }} · {{ money(p.value) }}</span></div>
          </div>
        </div>
        <div v-if="o.status === 'pending'" class="flex flex-wrap gap-2">
          <template v-if="o.incoming">
            <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy(`deal:${o.id}`) || !!t.closed" @click="decide(o, 'accept')">{{ $t('قبول') }}</button>
            <button type="button" class="h-touch rounded-md border border-gold/60 px-4 font-bold text-gold" :disabled="busy(`deal:${o.id}`)" @click="counter(o)">{{ $t('تفاوض') }}</button>
            <button type="button" class="h-touch rounded-md bg-surface-raised px-4" :disabled="busy(`deal:${o.id}`)" @click="decide(o, 'reject')">{{ $t('رفض') }}</button>
          </template>
          <button v-else type="button" class="h-touch rounded-md bg-surface-raised px-4" :disabled="busy(`deal:${o.id}`)" @click="decide(o, 'cancel')">{{ $t('اسحب العرض') }}</button>
        </div>
      </article>
     </div>
      <aside class="deals-aside flex flex-col overflow-hidden rounded-2xl" :aria-label="$t('صفقات المدربين')">
        <div class="deals-hero grid place-items-center pt-4"><Character model="B2" mood="happy" class="w-36" /></div>
        <div class="flex flex-col gap-2 bg-surface p-4">
          <h2 class="font-display text-lg font-extrabold">{{ $t('صفقات المدربين') }}</h2>
          <p class="text-sm leading-6 text-text-soft">{{ $t('كل لاعب في الدوري قابل للتفاوض: اطلب لاعباً أو أكثر من مدرب، وأعطه مالاً أو لاعبين أو نسبة من بيعه القادم. ويرد بالقبول أو الرفض أو بعرض مضاد قبل أن ينتهي العرض.') }}</p>
        </div>
      </aside>
    </div>

    <UiDialog :open="draft.open" bare @close="draft.open = false"><template v-if="draft.open">
      <section :aria-label="draft.counterOf ? $t('رد بعرض') : $t('عرض جديد')" class="flex max-h-[90dvh] w-full max-w-2xl flex-col gap-3 overflow-y-auto rounded-t-xxl bg-surface p-4 md:rounded-xxl">
        <h2 class="font-display text-xl font-extrabold">{{ draft.counterOf ? $t('ردك على') : $t('عرض إلى') }} {{ draft.toName }}</h2>
        <div>
          <h3 class="mb-1 text-sm font-bold">{{ $t('تريد من فريقه (حتى 5)') }}</h3>
          <div class="flex max-h-56 flex-col overflow-y-auto rounded-lg bg-surface-sunk">
            <UiToggle v-for="p in theirs" :key="p.id" class="border-b border-text/5 px-2" :model-value="draft.in.includes(p.id)" @update:model-value="toggle(draft.in, p.id)">
              <span class="flex items-center gap-2"><LineBadge :line="p.line as Line" /><span class="flex-1 truncate">{{ $nm(p.name) }}</span><span class="font-numbers" dir="ltr">{{ p.overall }} · {{ money(p.value) }}</span></span>
            </UiToggle>
          </div>
        </div>
        <button v-if="!draft.more && !draft.counterOf && !draft.out.length" type="button" class="h-touch self-start rounded-md bg-surface-raised px-4 text-sm font-bold" @click="draft.more = true">{{ $t('أضف لاعبين منك أو نسبة من بيعه القادم') }}</button>
        <div v-if="draft.more || draft.counterOf || draft.out.length">
          <h3 class="mb-1 text-sm font-bold">{{ $t('تعطيه من فريقك (اختياري)') }}</h3>
          <div class="flex max-h-40 flex-col overflow-y-auto rounded-lg bg-surface-sunk">
            <UiToggle v-for="p in mine" :key="p.id" class="border-b border-text/5 px-2" :model-value="draft.out.includes(p.id)" @update:model-value="toggle(draft.out, p.id)">
              <span class="flex items-center gap-2"><LineBadge :line="p.line as Line" /><span class="flex-1 truncate">{{ $nm(p.name) }}</span><span class="font-numbers" dir="ltr">{{ p.overall }} · {{ money(p.value) }}</span></span>
            </UiToggle>
          </div>
        </div>
        <div class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3">
          <label class="flex flex-col gap-1 text-sm font-bold">{{ $t('والمال من أموال النادي') }}
            <input v-model.number="draft.money" type="number" min="0" inputmode="numeric" class="h-touch rounded-md bg-surface px-3 font-numbers" dir="ltr" @input="draft.touched = true" />
          </label>
          <div v-if="draft.in.length" class="flex flex-wrap gap-2" role="group" :aria-label="$t('مبالغ جاهزة')">
            <button v-for="x in presets" :key="x.label" type="button" class="h-9 rounded-pill px-3 text-xs font-bold"
              :class="draft.money === x.v ? 'bg-gold text-on-gold' : 'bg-surface text-text-soft hover:bg-surface-raised'" @click="pick(x.v)">
              {{ $t(x.label) }} <bdi dir="ltr" class="font-numbers">{{ money(x.v) }}</bdi>
            </button>
          </div>
          <p v-if="draft.in.length" class="text-xs" :class="inRange ? 'text-success' : 'text-danger'" role="status">
            {{ inRange ? $t('عرض مقبول في الحدود: المال من {v0} إلى {v1}.', { v0: money(range.min), v1: money(range.max) }) : $t('خارج الحدود: المال من {v0} إلى {v1}.', { v0: money(range.min), v1: money(range.max) }) }}
          </p>
        </div>
        <!-- [X62] The sell-on clause: a share of the next sale promised to the other coach (a new offer only). -->
        <label v-if="!draft.counterOf && draft.more" class="flex flex-col gap-1 text-sm font-bold">{{ $t('نسبة له من بيعك القادم لهم (اختياري)') }}
          <span class="flex items-center gap-2"><UiSlider v-model="draft.sellOn" :max="20" :step="5" label="نسبة من البيع القادم" :value-text="`${draft.sellOn}%`" class="flex-1" /><b class="w-12 text-center font-numbers" dir="ltr">{{ draft.sellOn }}%</b></span>
        </label>
        <p class="text-xs text-text-muted">{{ $t('تطلب لاعبين قيمتهم {v0}، وتعطي {v1}.', { v0: money(wantValue), v1: money(giveValue + (draft.money || 0)) }) }}</p>
        <div class="flex gap-2">
          <button type="button" class="h-12 flex-1 rounded-md bg-gold font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy(sendKey) || !draft.in.length || !inRange" @click="send">{{ draft.counterOf ? $t('أرسل الرد') : $t('أرسل العرض') }}</button>
          <button type="button" class="h-12 rounded-md bg-surface-raised px-5" @click="draft.open = false">{{ $t('إلغاء') }}</button>
        </div>
      </section>
    </template></UiDialog>
  </div>
</template>

<style scoped>
/* [Sprint 48 T6] The empty table: a night pitch out of focus, in our own colours. */
.deals-empty { background: radial-gradient(70% 60% at 50% 40%, rgb(255 255 255 / 0.12), transparent 70%), repeating-linear-gradient(90deg, var(--color-pitch) 0 48px, var(--color-pitch-dark) 48px 96px); box-shadow: inset 0 0 80px rgb(0 0 0 / 0.45); }
.deals-empty p { text-shadow: 0 1px 3px rgb(0 0 0 / 0.5); }
.deals-hero { background: radial-gradient(80% 70% at 50% 100%, var(--color-pitch), transparent 70%), linear-gradient(180deg, var(--color-brand-light), var(--color-brand)); }
.deals-aside { border: 1px solid color-mix(in srgb, var(--color-gold) 22%, transparent); }
</style>
