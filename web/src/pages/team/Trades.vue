<script setup lang="ts">
// Trades between coaches (Sprint 25 W1), inside the market: the transfer list, my offers in and out, and the
// composer for a new offer or a counter. Every rule (the fair range, the season limits) is checked by the API,
// which answers in Arabic; the screen only gathers the terms.
import UiToggle from '../../components/ui/UiToggle.vue'
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import { count, money, type Line } from '../../lib/format'

type T = components['schemas']['Transfers']
type Offer = components['schemas']['TransferOffer']
type Mine = components['schemas']['Market']['mine'][number]
const props = defineProps<{ leagueId: number; view: 'list' | 'offers'; mine: Mine[] }>()
const emit = defineEmits<{ changed: [] }>()

const t = ref<T | null>(null)
const error = ref('')
const notice = ref('')
const busy = ref(false)
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

async function run(label: string, fn: () => Promise<unknown>) {
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    await fn()
    notice.value = label
    await load()
    emit('changed')
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

// ---------------------------------------------------------------- the transfer list
const listPrice = reactive<Record<number, number>>({})
const listed = computed(() => new Map((t.value?.listings ?? []).filter((l) => l.mine).map((l) => [l.player.id, l.price])))
const list = (p: Mine) => run(`عُرض ${p.name} للبيع.`, () => api.POST('/leagues/{league}/transfers/listings', { params: path.value, body: { player_id: p.id, price: listPrice[p.id] || p.value } }))
const unlist = (p: Mine) => run(`سُحب ${p.name} من القائمة.`, () => api.DELETE('/leagues/{league}/transfers/listings/{player}', { params: { path: { league: props.leagueId, player: p.id } } }))

// ---------------------------------------------------------------- the composer
type Squad = { id: number; name: string; position: string; line: string; overall: number; value: number }
const draft = reactive({ open: false, to: 0, toName: '', counterOf: 0, money: 0, in: [] as number[], out: [] as number[] })
const theirs = ref<Squad[]>([])
async function compose(to: number, toName: string, opts: { in?: number[]; out?: number[]; money?: number; counterOf?: number } = {}) {
  Object.assign(draft, { open: true, to, toName, counterOf: opts.counterOf ?? 0, money: opts.money ?? 0, in: opts.in ?? [], out: opts.out ?? [] })
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
function send() {
  const body = { money: draft.money || 0, in: draft.in, out: draft.out, idempotency_key: crypto.randomUUID() }
  const label = draft.counterOf ? `أُرسل ردك إلى ${draft.toName}.` : `أُرسل عرضك إلى ${draft.toName}.`
  run(label, () => draft.counterOf
    ? api.POST('/leagues/{league}/transfers/offers/{offer}/counter', { params: { path: { league: props.leagueId, offer: draft.counterOf } }, body })
    : api.POST('/leagues/{league}/transfers/offers', { params: path.value, body: { ...body, to_club_id: draft.to } })).then(() => { if (!error.value) draft.open = false })
}
// A counter: I want what he offered of his, and I give what he asked of mine.
const counter = (o: Offer) => compose(o.from.id, o.from.name, { counterOf: o.id, in: o.out.map((p) => p.id), out: o.in.map((p) => p.id), money: 0 })
const decide = (o: Offer, what: 'accept' | 'reject' | 'cancel') => run(
  { accept: 'تمت الصفقة.', reject: 'رُفض العرض.', cancel: 'سُحب العرض.' }[what],
  () => api.POST(`/leagues/{league}/transfers/offers/{offer}/${what}` as any, { params: { path: { league: props.leagueId, offer: o.id } } }),
)
const pending = computed(() => (t.value?.offers ?? []).filter((o) => o.status === 'pending'))
const done = computed(() => (t.value?.offers ?? []).filter((o) => o.status !== 'pending'))
const hours = (iso: string) => Math.max(0, Math.round((new Date(iso).getTime() - Date.now()) / 3_600_000))

watch(() => props.view, () => (notice.value = error.value = ''))
onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-3">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ $t(notice) }}</p>

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
            <button type="button" class="h-touch rounded-md bg-gold px-3 font-bold text-on-gold disabled:opacity-40" :disabled="!!t.closed" @click="compose(l.club.id, l.club.name, { in: [l.player.id], money: l.price })">{{ $t('قدّم عرضاً') }}</button>
          </li>
        </ul>
      </section>
      <section :aria-label="$t('اعرض لاعبيك')" class="rounded-xl bg-surface p-2">
        <h2 class="px-2 pt-2 font-display text-lg font-bold">{{ $t('اعرض لاعبيك') }}</h2>
        <p class="px-2 text-xs text-text-muted">{{ $t('السعر من نصف القيمة إلى سقف اللاعب. المدربون يقدّمون عروضهم فتقبل أو ترفض أو ترد، ولو لم يشتره أحد يشتريه نادٍ من خارج الدوري في موعده (تفاصيل كل لاعب في «بيع لاعبيّ»).') }}</p>
        <ul>
          <li v-for="p in mine" :key="p.id" class="flex flex-wrap items-center gap-3 border-t border-text/5 px-2 py-2">
            <LineBadge :line="p.line as Line" />
            <span class="min-w-0 flex-1"><b class="block truncate" dir="auto">{{ $nm(p.name) }}</b><span class="text-xs text-text-muted">{{ $t('قيمته {v0}', { v0: money(p.value) }) }}</span></span>
            <template v-if="listed.has(p.id)">
              <span class="rounded-pill bg-gold/15 px-3 py-1 font-numbers text-sm text-gold" dir="ltr">{{ money(listed.get(p.id)!) }}</span>
              <button type="button" class="h-touch rounded-md bg-surface-raised px-3 text-sm" :disabled="busy" @click="unlist(p)">{{ $t('اسحب') }}</button>
            </template>
            <template v-else>
              <input v-model.number="listPrice[p.id]" type="number" inputmode="numeric" :placeholder="String(p.value)" :aria-label="$t('سعر {v0}', { v0: p.name })" class="h-touch w-32 rounded-md bg-surface-sunk px-2 font-numbers" dir="ltr" />
              <button type="button" class="h-touch rounded-md border border-gold/60 px-3 text-sm font-bold text-gold disabled:opacity-40" :disabled="busy || !!t.closed" @click="list(p)">{{ $t('اعرض') }}</button>
            </template>
          </li>
        </ul>
      </section>
    </template>

    <template v-if="t && view === 'offers'">
      <div class="flex flex-wrap items-center gap-2">
        <label class="flex h-11 items-center gap-2 rounded-lg bg-surface px-3 text-sm text-text-muted">{{ $t('عرض جديد إلى') }}
          <select class="h-8 bg-transparent font-semibold text-text" :disabled="!!t.closed" @change="(e) => { const c = t!.clubs.find((c) => c.id === Number((e.target as HTMLSelectElement).value)); if (c) compose(c.id, c.name); (e.target as HTMLSelectElement).value = '' }">
            <option value="">{{ $t('اختر مدرباً') }}</option><option v-for="c in t.clubs" :key="c.id" :value="c.id">{{ $nm(c.name) }}</option>
          </select>
        </label>
        <span class="text-xs text-text-muted">{{ $t('ما يُدفع فوق القيمة بين ناديين في الموسم لا يتجاوز {v0}', { v0: count(t.pair_cap) }) }}</span>
      </div>
      <p v-if="!t.offers.length" class="rounded-xl bg-surface p-4 text-sm text-text-muted">{{ $t('لا عروض بعد.') }}</p>
      <article v-for="o in [...pending, ...done]" :key="o.id" class="flex flex-col gap-2 rounded-xl border bg-surface p-4" :class="o.status === 'pending' && o.incoming ? 'border-gold/50' : 'border-transparent'">
        <div class="flex flex-wrap items-center gap-2 text-sm">
          <b>{{ o.incoming ? $t('عرض وارد من {v0}', { v0: o.from.name }) : $t('عرضك إلى {v0}', { v0: o.to.name }) }}</b>
          <span class="rounded-pill bg-text/10 px-2 py-0.5 text-xs">{{ STATUS[o.status] }}</span>
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
            <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy || !!t.closed" @click="decide(o, 'accept')">{{ $t('قبول') }}</button>
            <button type="button" class="h-touch rounded-md border border-gold/60 px-4 font-bold text-gold" :disabled="busy" @click="counter(o)">{{ $t('تفاوض') }}</button>
            <button type="button" class="h-touch rounded-md bg-surface-raised px-4" :disabled="busy" @click="decide(o, 'reject')">{{ $t('رفض') }}</button>
          </template>
          <button v-else type="button" class="h-touch rounded-md bg-surface-raised px-4" :disabled="busy" @click="decide(o, 'cancel')">{{ $t('اسحب العرض') }}</button>
        </div>
      </article>
    </template>

    <div v-if="draft.open" class="fixed inset-0 z-40 flex items-end justify-center bg-black/60 md:items-center" @click.self="draft.open = false">
      <section role="dialog" aria-modal="true" :aria-label="draft.counterOf ? $t('رد بعرض') : $t('عرض جديد')" class="flex max-h-[90dvh] w-full max-w-2xl flex-col gap-3 overflow-y-auto rounded-t-xxl bg-surface p-4 md:rounded-xxl">
        <h2 class="font-display text-xl font-extrabold">{{ draft.counterOf ? $t('ردك على') : $t('عرض إلى') }} {{ draft.toName }}</h2>
        <div>
          <h3 class="mb-1 text-sm font-bold">{{ $t('تريد من فريقه (حتى 5)') }}</h3>
          <div class="flex max-h-56 flex-col overflow-y-auto rounded-lg bg-surface-sunk">
            <UiToggle v-for="p in theirs" :key="p.id" class="border-b border-text/5 px-2" :model-value="draft.in.includes(p.id)" @update:model-value="toggle(draft.in, p.id)">
              <span class="flex items-center gap-2"><LineBadge :line="p.line as Line" /><span class="flex-1 truncate">{{ $nm(p.name) }}</span><span class="font-numbers" dir="ltr">{{ p.overall }} · {{ money(p.value) }}</span></span>
            </UiToggle>
          </div>
        </div>
        <div>
          <h3 class="mb-1 text-sm font-bold">{{ $t('تعطيه من فريقك (اختياري)') }}</h3>
          <div class="flex max-h-40 flex-col overflow-y-auto rounded-lg bg-surface-sunk">
            <UiToggle v-for="p in mine" :key="p.id" class="border-b border-text/5 px-2" :model-value="draft.out.includes(p.id)" @update:model-value="toggle(draft.out, p.id)">
              <span class="flex items-center gap-2"><LineBadge :line="p.line as Line" /><span class="flex-1 truncate">{{ $nm(p.name) }}</span><span class="font-numbers" dir="ltr">{{ p.overall }} · {{ money(p.value) }}</span></span>
            </UiToggle>
          </div>
        </div>
        <label class="flex flex-col gap-1 text-sm font-bold">{{ $t('والمال من أموال النادي') }}
          <input v-model.number="draft.money" type="number" min="0" inputmode="numeric" class="h-touch rounded-md bg-surface-sunk px-3 font-numbers" dir="ltr" />
        </label>
        <p class="text-xs text-text-muted">{{ $t('تطلب لاعبين قيمتهم {v0}، وتعطي {v1}. المسموح: من 50% إلى 200% من قيمة ما تطلب.', { v0: money(wantValue), v1: money(giveValue + (draft.money || 0)) }) }}</p>
        <div class="flex gap-2">
          <button type="button" class="h-12 flex-1 rounded-md bg-gold font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy || !draft.in.length" @click="send">{{ draft.counterOf ? $t('أرسل الرد') : $t('أرسل العرض') }}</button>
          <button type="button" class="h-12 rounded-md bg-surface-raised px-5" @click="draft.open = false">{{ $t('إلغاء') }}</button>
        </div>
      </section>
    </div>
  </div>
</template>
