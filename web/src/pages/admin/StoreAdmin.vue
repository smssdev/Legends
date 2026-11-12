<script setup lang="ts">
// [Sprint 43 W2] The store in the admin panel (Sprint43Drafts.html): add a package (it stays until changed or deleted)
// or an offer (it ends at the time set here), with a picture uploaded from the device (cut to one size on the server),
// a preview, then hide, change, delete, or email it to the coaches who asked.
import { computed, onMounted, reactive, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import UiButton from '../../components/ui/UiButton.vue'
import StoreCard from '../../components/store/StoreCard.vue'
import { t } from '../../lib/i18n'
import { useConfirm } from '../../stores/confirm'
import { useToast } from '../../stores/toast'

const items = ref<any[]>([])
const currency = ref('ج.م')
const busy = ref(false)
const editing = ref<number | null>(null)
const file = ref<File | null>(null)
const preview = ref<string | null>(null)
const toast = useToast()
const blank = () => ({ kind: 'package' as 'package' | 'offer', title: '', description: '', price: 0, old_price: null as number | null, currency: '', visible: true, sort: 0, ends_at: '' })
const form = reactive(blank())

async function load() {
  const data = (await api.GET('/admin/store')).data!
  items.value = data.items
  currency.value = data.currency
}
onMounted(load)

function pick(e: Event) {
  const f = (e.target as HTMLInputElement).files?.[0] ?? null
  file.value = f
  if (preview.value) URL.revokeObjectURL(preview.value)
  preview.value = f ? URL.createObjectURL(f) : null
}
function edit(i: any) {
  editing.value = i.id
  Object.assign(form, { kind: i.kind, title: i.title, description: i.description, price: i.price, old_price: i.old_price, currency: i.currency, visible: i.visible, sort: i.sort,
    ends_at: i.ends_at ? toLocal(i.ends_at) : '' })
  file.value = null
  preview.value = null
}
function reset() {
  editing.value = null
  Object.assign(form, blank())
  file.value = null
  preview.value = null
}
// The input shows the device's time; the server keeps UTC.
const toLocal = (iso: string) => { const d = new Date(iso); return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16) }
const card = computed(() => ({ id: 0, kind: form.kind, title: form.title || t('العنوان'), description: form.description, price: Number(form.price) || 0,
  old_price: form.old_price ? Number(form.old_price) : null, currency: form.currency || currency.value,
  discount: form.old_price && Number(form.old_price) > Number(form.price) ? Math.floor((Number(form.old_price) - Number(form.price)) * 100 / Number(form.old_price)) : null,
  visible: form.visible, sort: form.sort, ends_at: form.kind === 'offer' && form.ends_at ? new Date(form.ends_at).toISOString() : null, ended: false,
  image_url: preview.value ?? items.value.find((i) => i.id === editing.value)?.image_url ?? null, emailed_at: null, whatsapp_url: '#' }))

async function save() {
  busy.value = true
  try {
    await ensureCsrf()
    const body = new FormData()
    for (const [k, v] of Object.entries(form)) {
      if (k === 'ends_at') { if (form.kind === 'offer' && v) body.append(k, new Date(String(v)).toISOString()); continue }
      if (k === 'visible') { body.append(k, v ? '1' : '0'); continue }
      if (v !== null && v !== '') body.append(k, String(v))
    }
    if (file.value) body.append('image', file.value)
    const opts = { body: body as never, bodySerializer: (b: unknown) => b as FormData }
    if (editing.value) await api.POST('/admin/store/{id}', { params: { path: { id: editing.value } }, ...opts })
    else await api.POST('/admin/store', opts)
    toast.show(t('حُفظ.'))
    reset()
    await load()
  } catch (e) { toast.show(asApiError(e).message, 'error') }
  busy.value = false
}
async function remove(i: any) {
  if (!(await useConfirm().ask({ title: t('حذف «{t}»؟', { t: i.title }), text: t('يختفي من المتجر نهائياً مع صورته.'), action: t('احذف') }))) return
  try { await ensureCsrf(); await api.DELETE('/admin/store/{id}', { params: { path: { id: i.id } } }); await load() } catch (e) { toast.show(asApiError(e).message, 'error') }
}
async function email(i: any) {
  if (!(await useConfirm().ask({ title: t('إرسال «{t}» بالبريد؟', { t: i.title }), text: t('يصل لكل من فعّل عروض المتجر بالبريد ووثّق بريده.'), action: t('أرسل') }))) return
  try { await ensureCsrf(); const sent = (await api.POST('/admin/store/{id}/email', { params: { path: { id: i.id } } })).data!.sent; toast.show(t('أُرسل إلى {n}.', { n: sent })); await load() }
  catch (e) { toast.show(asApiError(e).message, 'error') }
}
const field = 'min-h-touch rounded-lg border border-surface-raised bg-surface-sunk px-3 py-2'
</script>

<template>
  <section class="grid gap-5 lg:grid-cols-[minmax(0,1fr)_340px]">
    <form class="flex flex-col gap-3 rounded-xl bg-surface p-4" @submit.prevent="save">
      <h2 class="font-display text-xl font-bold">{{ editing ? $t('تعديل') : $t('عنصر جديد') }}</h2>
      <div class="flex gap-2" role="radiogroup" :aria-label="$t('النوع')">
        <button v-for="k in (['package', 'offer'] as const)" :key="k" type="button" role="radio" :aria-checked="form.kind === k"
          class="min-h-touch flex-1 rounded-lg font-bold" :class="form.kind === k ? 'bg-brand text-white' : 'bg-surface-sunk text-text-muted'" @click="form.kind = k">
          {{ k === 'package' ? $t('باقة ثابتة') : $t('عرض لمدة محددة') }}</button>
      </div>
      <label class="flex aspect-video cursor-pointer flex-col items-center justify-center gap-1 overflow-hidden rounded-xl border-2 border-dashed border-gold text-center text-sm text-text-soft">
        <img v-if="card.image_url" :src="card.image_url" alt="" class="size-full object-cover" loading="lazy" decoding="async" />
        <template v-else><b class="text-gold">📷 {{ $t('ارفع صورة من جهازك') }}</b>{{ $t('تُقصّ بنسبة 16:9 تلقائياً') }}</template>
        <input type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="sr-only" @change="pick" />
      </label>
      <label class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('العنوان') }}<input v-model="form.title" maxlength="80" required :class="field" class="text-text" /></label>
      <label class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('الوصف') }}<textarea v-model="form.description" maxlength="600" rows="3" required :class="field" class="text-text" /></label>
      <div class="grid grid-cols-3 gap-2">
        <label class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('السعر') }}<input v-model.number="form.price" type="number" min="0" required dir="ltr" :class="field" class="text-text" /></label>
        <label class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('قبل الخصم (اختياري)') }}<input v-model.number="form.old_price" type="number" min="0" dir="ltr" :class="field" class="text-text" /></label>
        <label class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('العملة') }}<input v-model="form.currency" maxlength="12" :placeholder="currency" :class="field" class="text-text" /></label>
      </div>
      <label v-if="form.kind === 'offer'" class="flex flex-col gap-1 text-sm text-text-muted">{{ $t('ينتهي العرض في') }}<input v-model="form.ends_at" type="datetime-local" required dir="ltr" :class="field" class="text-text" /></label>
      <label class="flex min-h-touch items-center justify-between gap-2 rounded-lg bg-surface-sunk px-3 text-sm">{{ $t('يظهر في الموقع') }}<input v-model="form.visible" type="checkbox" class="size-5" /></label>
      <div class="flex gap-2">
        <UiButton type="submit" :loading="busy">{{ editing ? $t('احفظ التعديل') : $t('انشر') }}</UiButton>
        <UiButton v-if="editing" type="button" variant="quiet" @click="reset">{{ $t('إلغاء') }}</UiButton>
      </div>
    </form>
    <aside class="flex flex-col gap-2">
      <h3 class="text-sm font-bold text-text-muted">{{ $t('معاينة') }}</h3>
      <StoreCard :item="card" />
    </aside>
    <div class="flex flex-col gap-2 lg:col-span-2">
      <h2 class="font-display text-xl font-bold">{{ $t('المتجر') }} <span class="font-numbers text-text-muted">{{ items.length }}</span></h2>
      <p v-if="!items.length" class="text-text-muted">{{ $t('لا شيء بعد.') }}</p>
      <div v-for="i in items" :key="i.id" class="flex flex-wrap items-center gap-3 rounded-xl bg-surface p-3">
        <img v-if="i.image_url" :src="i.image_url" alt="" class="aspect-video w-28 rounded-lg object-cover" loading="lazy" decoding="async" />
        <div class="min-w-0 flex-1">
          <b>{{ i.title }}</b>
          <span class="block text-xs text-text-muted">{{ i.kind === 'offer' ? (i.ended ? $t('عرض منتهٍ') : $t('عرض حتى {d}', { d: new Date(i.ends_at).toLocaleString() })) : $t('باقة ثابتة') }}
            · <span dir="ltr">{{ i.price }}</span> {{ i.currency }}{{ i.visible ? '' : ' · ' + $t('مخفي') }}{{ i.emailed_at ? ' · ' + $t('أُرسل بالبريد') : '' }}</span>
        </div>
        <UiButton variant="quiet" @click="edit(i)">{{ $t('تعديل') }}</UiButton>
        <UiButton v-if="!i.ended" variant="quiet" @click="email(i)">{{ $t('أرسل بالبريد') }}</UiButton>
        <UiButton variant="danger" @click="remove(i)">{{ $t('احذف') }}</UiButton>
      </div>
    </div>
  </section>
</template>
