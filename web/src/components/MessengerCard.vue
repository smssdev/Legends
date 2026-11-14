<script setup lang="ts">
// [Sprint 67] The game's bots on Telegram and WhatsApp (official and free): link the account with a one-time code (the
// button opens the bot's chat with the code already written), silence its notifications, or unlink. WhatsApp writes
// only within 24 hours of the coach's own last message there, where it costs nothing. Shown only when a bot is on.
import UiButton from './ui/UiButton.vue'
import UiCard from './ui/UiCard.vue'
import UiToggle from './ui/UiToggle.vue'
import UiSelect from './ui/UiSelect.vue'
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'

type Status = components['schemas']['MessengerStatus']
type Platform = 'telegram' | 'whatsapp'
const status = ref<Status | null>(null)
const code = ref<{ platform: Platform; code: string } | null>(null)
const error = ref('')
const busy = ref(false)
const NAMES: Record<Platform, string> = { telegram: 'تيليجرام', whatsapp: 'واتساب' }

async function load() {
  try {
    status.value = (await api.GET('/messenger')).data!
    if (code.value && status.value[code.value.platform].linked) code.value = null
  } catch (e) {
    error.value = asApiError(e).message
  }
}

async function link(platform: Platform) {
  busy.value = true
  error.value = ''
  try {
    await ensureCsrf()
    const r = (await api.POST('/messenger/link', { body: { platform } })).data!
    code.value = { platform, code: r.code }
    if (r.url) window.open(r.url, '_blank', 'noopener')
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

async function save(platform: Platform, body: { muted?: boolean; live?: boolean; daily_hour?: number | null }) {
  await ensureCsrf()
  status.value = (await api.PUT('/messenger/{platform}', { params: { path: { platform } }, body })).data!
}
const mute = (platform: Platform, muted: boolean) => save(platform, { muted })
// [Sprint 68] The daily summary's hour (Cairo time), or off.
const HOURS = Array.from({ length: 24 }, (_, h) => ({ value: String(h), label: `${String(h).padStart(2, '0')}:00` }))

async function unlink(platform: Platform) {
  await ensureCsrf()
  status.value = (await api.DELETE('/messenger/{platform}', { params: { path: { platform } } })).data!
}

// Back from the bot's chat: the link shows at once.
const onFocus = () => code.value && load()
onMounted(() => (load(), window.addEventListener('focus', onFocus)))
onBeforeUnmount(() => window.removeEventListener('focus', onFocus))
</script>

<template>
  <UiCard v-if="status && (status.telegram.available || status.whatsapp.available)" :title="'بوت اللعبة'">
    <p class="text-body text-text-muted">
      {{ $t('اربط حسابك ببوت اللعبة لتصلك إشعاراتك هناك، واسأله عن مباراتك القادمة وترتيبك ورصيدك وعن أي شيء في اللعبة.') }}
    </p>
    <p v-if="error" class="text-body text-danger" role="alert">{{ $t(error) }}</p>

    <template v-for="p in ['telegram', 'whatsapp'] as Platform[]" :key="p">
      <div v-if="status[p].available" class="flex flex-col gap-2 border-t border-line pt-3">
        <div class="flex flex-wrap items-center gap-3">
          <b class="flex-1">{{ $t(NAMES[p]) }}</b>
          <span v-if="status[p].linked" class="text-caption text-brand-light">{{ $t('مربوط') }}</span>
          <UiButton v-if="!status[p].linked" size="sm" variant="brand" :loading="busy" @click="link(p)">{{ $t('اربط البوت') }}</UiButton>
          <UiButton v-else size="sm" variant="quiet" @click="unlink(p)">{{ $t('فك الربط') }}</UiButton>
        </div>
        <p v-if="code?.platform === p" class="text-body text-text-muted">
          {{ $t('لم تُفتح المحادثة؟ أرسل هذا الكود للبوت خلال 15 دقيقة:') }}
          <b dir="ltr" class="font-mono select-all">{{ code.code }}</b>
        </p>
        <UiToggle
          v-if="status[p].linked"
          class="rounded-lg px-1"
          :model-value="!status[p].muted"
          :label="$t('الإشعارات على البوت')"
          :hint="
            p === 'whatsapp'
              ? $t('تصلك خلال 24 ساعة من آخر رسالة ترسلها للبوت، فراسله مرة في اليوم لتبقى مجانية')
              : $t('الأنواع نفسها التي اخترتها في الإشعارات')
          "
          @update:model-value="(on: boolean) => mute(p, !on)"
        />
        <UiToggle
          v-if="status[p].linked"
          class="rounded-lg px-1"
          :model-value="status[p].live"
          :label="$t('مبارياتي الحية على البوت')"
          :hint="$t('الأهداف والطرد ونهاية الشوط والنتيجة، حين تظهر في المباراة')"
          @update:model-value="(on: boolean) => save(p, { live: on })"
        />
        <UiSelect
          v-if="status[p].linked"
          :model-value="status[p].daily_hour === null ? '' : String(status[p].daily_hour)"
          :options="HOURS"
          :label="$t('الملخص اليومي (بتوقيت القاهرة)')"
          none="متوقف"
          ltr
          @update:model-value="(v: string) => save(p, { daily_hour: v === '' ? null : Number(v) })"
        />
      </div>
    </template>

    <div v-if="status.channels.telegram || status.channels.whatsapp" class="flex flex-col gap-1 border-t border-line pt-3 text-body">
      <span class="text-text-muted">{{ $t('قنوات اللعبة: الإعلانات وترتيب المدربين كل أسبوع') }}</span>
      <div class="flex flex-wrap gap-4">
        <a
          v-if="status.channels.telegram"
          :href="status.channels.telegram"
          target="_blank"
          rel="noopener"
          class="text-brand-light underline"
          >{{ $t('قناة تيليجرام') }}</a
        >
        <a
          v-if="status.channels.whatsapp"
          :href="status.channels.whatsapp"
          target="_blank"
          rel="noopener"
          class="text-brand-light underline"
          >{{ $t('قناة واتساب') }}</a
        >
      </div>
    </div>
  </UiCard>
</template>
