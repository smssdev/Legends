<script setup lang="ts">
// The app and its notifications (Sprint 36 W1, PLAN 2.13): install the site on the home screen (with the
// iPhone's own steps), turn this browser's notifications on, and choose the kinds. A tap on a notification
// opens its screen (public/sw.js).
import { setTone, toneOn } from '../lib/tone'
import UiToggle from './ui/UiToggle.vue'
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import { currentSubscription, install, installable, isIos, pushSupported, standalone, subscribe } from '../lib/pwa'

type Settings = components['schemas']['NotificationSettings']
const settings = ref<Settings | null>(null)
const here = ref(false)
const error = ref('')
const busy = ref(false)
const LABELS: Record<string, [string, string]> = {
  referee: ['الحكم', 'قبل المباراة بنصف ساعة'],
  match_soon: ['المباراة بعد نصف ساعة', 'لتستعد وتدخل وتدير فريقك'],
  offers: ['العروض', 'عرض وارد أو رد على عرضك'],
  done: ['انتهى شيء', 'تدريب أو جزء ملعب أو تقرير كشاف'],
  absence: ['الغياب', 'تحذير قبل أن يعود فريقك للحاسوب'],
}
const ios = isIos()
const app = standalone()

async function load() {
  try {
    settings.value = (await api.GET('/notifications')).data!
    here.value = !!(await currentSubscription())
  } catch (e) {
    error.value = asApiError(e).message
  }
}

async function enable() {
  busy.value = true
  error.value = ''
  try {
    const sub = await subscribe(settings.value!.public_key!)
    if (!sub) {
      error.value = 'لم يُسمح بالإشعارات في هذا المتصفح. اسمح بها من إعدادات الموقع ثم أعد المحاولة.'
    } else {
      await ensureCsrf()
      const json = sub.toJSON() as { endpoint: string; keys: { p256dh: string; auth: string } }
      settings.value = (await api.POST('/notifications/subscriptions', { body: { endpoint: json.endpoint, keys: json.keys } })).data!
      here.value = true
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

async function disable() {
  busy.value = true
  const sub = await currentSubscription()
  if (sub) {
    await ensureCsrf()
    settings.value = (await api.DELETE('/notifications/subscriptions', { body: { endpoint: sub.endpoint } })).data!
    await sub.unsubscribe()
  }
  here.value = false
  busy.value = false
}

async function toggle(kind: string, on: boolean) {
  await ensureCsrf()
  settings.value = (await api.PUT('/notifications', { body: { kinds: { [kind]: on } } })).data!
}

onMounted(load)
</script>

<template>
  <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-app">
    <h2 id="h-app" class="font-display text-xl font-extrabold">{{ $t('التطبيق والإشعارات') }}</h2>
    <p v-if="error" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>

    <div v-if="!app" class="flex flex-col gap-2 rounded-lg bg-surface-sunk p-3 text-sm">
      <b>{{ $t('ثبّت GLM على شاشتك الرئيسية') }}</b>
      <span class="text-text-muted">{{ $t('يفتح كتطبيق بملء الشاشة، وتصلك الإشعارات.') }}</span>
      <button v-if="installable" type="button" class="h-touch rounded-md bg-gold font-bold text-on-gold" @click="install">{{ $t('ثبّت الآن') }}</button>
      <ol v-else-if="ios" class="list-decimal ps-5 text-text-muted">
        <li>{{ $t('افتح الموقع في Safari.') }}</li>
        <li>{{ $t('اضغط زر المشاركة (المربع والسهم).') }}</li>
        <li>{{ $t('اختر «إضافة إلى الشاشة الرئيسية».') }}</li>
      </ol>
      <span v-else class="text-text-muted">{{ $t('من قائمة المتصفح: «تثبيت التطبيق» أو «إضافة إلى الشاشة الرئيسية».') }}</span>
    </div>

    <!-- [Sprint 21 E3.6] The game's own tone when a message arrives, on this device. -->
    <UiToggle class="rounded-lg px-1" :model-value="toneOn" :label="$t('نغمة الإشعارات')" :hint="$t('نغمة GLM حين تصلك رسالة واللعبة مفتوحة')" @update:model-value="(on: boolean) => setTone(on)" />

    <template v-if="settings">
      <p v-if="!settings.enabled" class="text-sm text-text-muted">{{ $t('الإشعارات غير مفعلة على الخادم بعد.') }}</p>
      <p v-else-if="!pushSupported()" class="text-sm text-text-muted">
        {{ ios && !app ? $t('على iPhone تعمل الإشعارات بعد تثبيت الموقع على الشاشة الرئيسية.') : $t('هذا المتصفح لا يدعم الإشعارات.') }}
      </p>
      <div v-else class="flex flex-wrap items-center gap-3">
        <span class="flex-1 text-sm">{{ here ? $t('الإشعارات تعمل على هذا الجهاز') : $t('الإشعارات متوقفة على هذا الجهاز') }}
          <span v-if="settings.devices" class="text-text-muted"> {{ $t('· {v0} جهاز', { v0: settings.devices }) }}</span></span>
        <button v-if="!here" type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="enable">{{ $t('فعّلها') }}</button>
        <button v-else type="button" class="h-touch rounded-md px-4 text-text-muted hover:text-text" :disabled="busy" @click="disable">{{ $t('أوقفها هنا') }}</button>
      </div>
      <div class="flex flex-col gap-1">
        <UiToggle v-for="k in settings.kinds" :key="k.kind" class="rounded-lg px-1" :model-value="k.on" :label="LABELS[k.kind]?.[0]" :hint="LABELS[k.kind]?.[1]" @update:model-value="(on: boolean) => toggle(k.kind, on)" />
      </div>
    </template>
  </section>
</template>
