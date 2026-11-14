<script setup lang="ts">
import Icon from '../../components/Icon.vue'
// [Sprint 15 D1] The app's versions in the admin panel: pick the APK from the device, its version and what is new;
// it goes up in pieces (each well under the server's upload limits) with its progress, a piece retried on a network
// hiccup, and becomes the site's download once whole and checked. The two latest are kept on the server.
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import UiButton from '../../components/ui/UiButton.vue'
import { intlLocale, t } from '../../lib/i18n'
import { useConfirm } from '../../stores/confirm'
import { useToast } from '../../stores/toast'

const releases = ref<any[]>([])
const chunkKb = ref(1536)
const file = ref<File | null>(null)
const version = ref('')
const notes = ref('')
const progress = ref<number | null>(null)
const toast = useToast()
const mb = (b: number) => new Intl.NumberFormat(intlLocale(), { maximumFractionDigits: 1 }).format(b / 1048576)

async function load() {
  const data = (await api.GET('/admin/app-releases')).data as any
  releases.value = data.releases
  chunkKb.value = data.chunk_kb
}
onMounted(load)

function pick(e: Event) {
  file.value = (e.target as HTMLInputElement).files?.[0] ?? null
  // The version from a name like app-1.2.0.apk, when it has one.
  const m = file.value?.name.match(/(\d+\.\d+\.\d+)/)
  if (m && !version.value) version.value = m[1]
}

async function upload() {
  if (!file.value || !version.value) return toast.show(t('اختر الملف واكتب النسخة.'), 'error')
  const f = file.value
  progress.value = 0
  try {
    await ensureCsrf()
    const id = (
      (await api.POST('/admin/app-releases', { body: { version: version.value, bytes: f.size, notes: notes.value || null } })).data as any
    ).id
    const size = chunkKb.value * 1024
    let offset = 0
    while (offset < f.size) {
      const piece = f.slice(offset, offset + size)
      let tries = 0
      for (;;) {
        try {
          const r = await api.PUT('/admin/app-releases/{id}/chunk', {
            params: { path: { id }, query: { offset } },
            body: piece as never,
            bodySerializer: (b: unknown) => b as Blob,
            headers: { 'Content-Type': 'application/octet-stream' },
          })
          offset = (r.data as any).received
          break
        } catch (e) {
          if (++tries >= 4) throw e
          await new Promise((ok) => setTimeout(ok, 1500 * tries))
        }
      }
      progress.value = Math.floor((offset * 100) / f.size)
    }
    await api.POST('/admin/app-releases/{id}/finish', { params: { path: { id } } })
    toast.show(t('نُشرت النسخة {v} للتنزيل من الموقع.', { v: version.value }))
    file.value = null
    version.value = ''
    notes.value = ''
    await load()
  } catch (e) {
    toast.show(asApiError(e).message, 'error')
  }
  progress.value = null
}

async function remove(r: any) {
  if (
    !(await useConfirm().ask({
      title: t('حذف النسخة {v}؟', { v: r.version }),
      text: t('يُحذف ملفها من الخادم، ويُنزَّل الأحدث بعدها إن وُجد.'),
      action: t('احذف'),
    }))
  )
    return
  try {
    await ensureCsrf()
    await api.DELETE('/admin/app-releases/{id}', { params: { path: { id: r.id } } })
    await load()
  } catch (e) {
    toast.show(asApiError(e).message, 'error')
  }
}
const field = 'min-h-touch rounded-lg border border-surface-raised bg-surface-sunk px-3 py-2 text-text'
</script>

<template>
  <section class="flex flex-col gap-5">
    <form class="flex flex-col gap-3 rounded-xl bg-surface p-4" @submit.prevent="upload">
      <h2 class="font-display text-xl font-bold">{{ $t('نسخة أندرويد جديدة') }}</h2>
      <label
        class="flex min-h-24 cursor-pointer flex-col items-center justify-center gap-1 rounded-xl border-2 border-dashed border-gold p-4 text-center text-sm text-text-soft"
      >
        <b class="text-gold"
          ><Icon name="download" :size="16" class="inline-block align-[-3px]" /> {{ file ? file.name : $t('اختر ملف APK من جهازك') }}</b
        >
        <span v-if="file" dir="ltr">{{ mb(file.size) }} MB</span>
        <input type="file" accept=".apk,application/vnd.android.package-archive" class="sr-only" @change="pick" />
      </label>
      <div class="grid gap-2 sm:grid-cols-[160px_1fr]">
        <label class="flex flex-col gap-1 text-sm text-text-muted"
          >{{ $t('النسخة') }}<input v-model="version" dir="ltr" placeholder="1.0.0" required :class="field"
        /></label>
        <label class="flex flex-col gap-1 text-sm text-text-muted"
          >{{ $t('ما الجديد (اختياري)') }}<input v-model="notes" maxlength="1000" :class="field"
        /></label>
      </div>
      <div
        v-if="progress !== null"
        class="h-3 overflow-hidden rounded-full bg-surface-sunk"
        role="progressbar"
        :aria-valuenow="progress"
        aria-valuemin="0"
        aria-valuemax="100"
        :aria-label="$t('رفع النسخة')"
      >
        <div class="h-full bg-gold transition-all" :style="{ width: progress + '%' }" />
      </div>
      <UiButton type="submit" :loading="progress !== null" :disabled="!file">{{
        progress !== null ? `${progress}%` : $t('ارفع وانشر')
      }}</UiButton>
    </form>
    <div class="flex flex-col gap-2">
      <h2 class="font-display text-xl font-bold">{{ $t('النسخ') }}</h2>
      <p v-if="!releases.length" class="text-text-muted">{{ $t('لا نسخة بعد: صفحة التنزيل تقول «قريباً».') }}</p>
      <div v-for="r in releases" :key="r.id" class="flex flex-wrap items-center gap-3 rounded-xl bg-surface p-3">
        <div class="min-w-0 flex-1">
          <b dir="ltr">{{ r.version }}</b>
          <span class="block text-xs text-text-muted"
            >{{ r.status === 'ready' ? $t('منشورة') : $t('لم يكتمل رفعها') }} · <span dir="ltr">{{ mb(r.bytes) }} MB</span> ·
            {{ $t('{n} تنزيل', { n: r.downloads }) }}</span
          >
          <code v-if="r.sha256" class="block truncate text-[0.65rem] text-text-muted" dir="ltr">SHA-256 {{ r.sha256 }}</code>
        </div>
        <UiButton variant="danger" @click="remove(r)">{{ $t('احذف') }}</UiButton>
      </div>
    </div>
  </section>
</template>
