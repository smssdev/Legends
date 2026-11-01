<script setup lang="ts">
// [Sprint 30 G1] The match reminder half an hour before kick-off (MatchPrep, Web Push) works only once the coach allows
// notifications, and the switch was deep in «حسابي». A coach with a club who has not allowed them on this device sees
// one card on the home screen: allow, or «لاحقاً» (hidden on this device for a week).
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import { currentSubscription, pushSupported, subscribe } from '../lib/pwa'
import { useToast } from '../stores/toast'
import { t } from '../lib/i18n'
import UiButton from './ui/UiButton.vue'

const KEY = 'glm.reminder.later'
const show = ref(false)
const busy = ref(false)
let key: string | null = null

onMounted(async () => {
  try {
    if (!pushSupported() || Notification.permission === 'denied') return
    const later = Number(localStorage.getItem(KEY) ?? 0)
    if (later && Date.now() - later < 7 * 86400_000) return
    if (await currentSubscription()) return
    const s = (await api.GET('/notifications')).data
    key = s?.public_key ?? null
    show.value = !!key
  } catch { /* no push here: nothing to offer */ }
})

async function allow() {
  busy.value = true
  try {
    const sub = await subscribe(key!)
    if (!sub) {
      useToast().show(t('لم يُسمح بالإشعارات في هذا المتصفح. اسمح بها من إعدادات الموقع ثم أعد المحاولة.'), 'error', 6000)
    } else {
      await ensureCsrf()
      const json = sub.toJSON() as { endpoint: string; keys: { p256dh: string; auth: string } }
      await api.POST('/notifications/subscriptions', { body: { endpoint: json.endpoint, keys: json.keys } })
      useToast().show(t('تم. سنذكّرك قبل كل مباراة بنصف ساعة.'))
      show.value = false
    }
  } catch (e) {
    useToast().show(asApiError(e).message, 'error')
  }
  busy.value = false
}
function later() {
  try { localStorage.setItem(KEY, String(Date.now())) } catch { /* private mode */ }
  show.value = false
}
</script>

<template>
  <section v-if="show" class="flex animate-fade-up flex-wrap items-center gap-3 rounded-2xl border border-brand-light/40 bg-brand/15 p-4" :aria-label="$t('تذكير المباراة')">
    <span class="text-3xl" aria-hidden="true">⏰</span>
    <span class="min-w-0 flex-1">
      <b class="block">{{ $t('ذكّرني قبل مباراتي') }}</b>
      <span class="text-sm text-text-muted">{{ $t('إشعار قبل كل مباراة بنصف ساعة، لتضبط تشكيلتك في وقتها.') }}</span>
    </span>
    <div class="flex gap-2">
      <UiButton variant="brand" :loading="busy" @click="allow">{{ $t('فعّل التذكير') }}</UiButton>
      <UiButton variant="quiet" @click="later">{{ $t('لاحقاً') }}</UiButton>
    </div>
  </section>
</template>
