<script setup lang="ts">
// [Sprint 39 N1] The first time a signed-in coach opens the game on a device: a small card asks to turn on the game's
// sound and its notifications. «فعّلها» is the tap browsers ask for before any sound (autoplay policy): it unlocks the
// tone and plays it once, and, where the server sends push notifications and the browser has them, asks the browser's
// own permission and subscribes this device (the same as the account page's card). «بدون صوت» mutes it; «لاحقاً» only
// closes. Asked once a device; the top bar's speaker and the account page change it later.
import { ref } from 'vue'
import { api, ensureCsrf } from '../../api/client'
import { pushSupported, subscribe } from '../../lib/pwa'
import { askLater, setTone, toneAsked } from '../../lib/tone'

const busy = ref(false)

async function enable() {
  busy.value = true
  setTone(true)
  try {
    if (pushSupported() && Notification.permission === 'default') {
      const settings = (await api.GET('/notifications')).data
      if (settings?.enabled && settings.public_key) {
        const sub = await subscribe(settings.public_key)
        if (sub) {
          await ensureCsrf()
          const json = sub.toJSON() as { endpoint: string; keys: { p256dh: string; auth: string } }
          await api.POST('/notifications/subscriptions', { body: { endpoint: json.endpoint, keys: json.keys } })
        }
      }
    }
  } catch {
    // The sound is on; the push can be turned on later from the account page.
  }
  busy.value = false
}
</script>

<template>
  <Transition name="drop">
    <section v-if="!toneAsked" class="fixed inset-x-3 bottom-24 z-40 mx-auto flex max-w-md flex-col gap-3 rounded-2xl border border-gold/40 bg-surface p-4 shadow-2xl md:bottom-6"
      role="dialog" aria-labelledby="sound-prompt-title">
      <div class="flex items-start gap-3">
        <span class="grid size-11 shrink-0 place-items-center rounded-xl bg-gold/15 text-gold" aria-hidden="true">
          <svg viewBox="0 0 24 24" class="size-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 9v6h4l5 4V5L8 9zM16.5 8.5a5 5 0 0 1 0 7M19 6a8.5 8.5 0 0 1 0 12" /></svg>
        </span>
        <div class="min-w-0">
          <h2 id="sound-prompt-title" class="font-display text-lg font-extrabold">{{ $t('فعّل الأصوات والإشعارات') }}</h2>
          <p class="text-sm text-text-muted">{{ $t('نغمة قصيرة حين يُباع لاعبك، أو يصلك عرض أو رسالة أو كود، أو تبدأ مباراتك أو تنتهي. تكتمها متى شئت من زر السماعة في الأعلى.') }}</p>
        </div>
      </div>
      <div class="flex flex-wrap gap-2">
        <button type="button" class="h-touch flex-1 rounded-lg bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="enable">{{ busy ? '...' : $t('فعّلها') }}</button>
        <button type="button" class="h-touch rounded-lg bg-surface-raised px-4 font-bold" :disabled="busy" @click="askLater">{{ $t('لاحقاً') }}</button>
        <button type="button" class="h-touch rounded-lg px-3 text-sm text-text-muted hover:text-text" :disabled="busy" @click="setTone(false)">{{ $t('بدون صوت') }}</button>
      </div>
    </section>
  </Transition>
</template>
