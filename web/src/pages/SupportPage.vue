<script setup lang="ts">
// The coach's conversation with the game's developers [Sprint 21 E7.7]: their messages come from their official
// accounts (with the badge), and the coach answers here. Open to a suspended account too, to ask why.
import { nextTick, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import { intlLocale } from '../lib/i18n'
import OfficialBadge from '../components/OfficialBadge.vue'

type Message = components['schemas']['SupportMessage']
const messages = ref<Message[]>([])
const loaded = ref(false)
const body = ref('')
const busy = ref(false)
const error = ref('')
const list = ref<HTMLElement | null>(null)
const when = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))
const toEnd = () => nextTick(() => list.value?.scrollTo({ top: list.value.scrollHeight }))

onMounted(async () => {
  try {
    messages.value = (await api.GET('/support')).data!.messages
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
  toEnd()
})
async function send() {
  busy.value = true
  error.value = ''
  try {
    await ensureCsrf()
    messages.value = (await api.POST('/support', { body: { body: body.value.trim() } })).data!.messages
    body.value = ''
    toEnd()
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}
</script>

<template>
  <div class="mx-auto flex w-full max-w-3xl flex-col gap-4">
    <header>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('تواصل مع فريق التطوير') }}</h1>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <section ref="list" class="flex max-h-[60dvh] min-h-60 flex-col gap-2 overflow-y-auto rounded-xl bg-surface p-4" :aria-label="$t('المحادثة')" aria-live="polite">
      <p v-if="loaded && !messages.length" class="m-auto text-center text-sm text-text-muted">{{ $t('لا رسائل بعد. اكتب سؤالك أو اقتراحك وسيرد عليك الفريق.') }}</p>
      <p v-for="m in messages" :key="m.id" class="max-w-[85%] whitespace-pre-line rounded-xl px-3 py-2 text-sm" :class="m.from_team ? 'self-start bg-gold/15' : 'self-end bg-surface-sunk'">
        <span v-if="m.sender" class="mb-0.5 flex items-center gap-1 text-xs font-bold text-gold">{{ m.sender.username }} <OfficialBadge /></span>{{ m.body }}
        <span class="mt-1 block text-[0.7rem] text-text-muted" dir="ltr">{{ when(m.at) }}</span>
      </p>
    </section>
    <form class="flex gap-2" @submit.prevent="send">
      <textarea v-model="body" rows="3" maxlength="2000" :placeholder="$t('اكتب رسالتك')" :aria-label="$t('رسالتك')" class="min-w-0 flex-1 rounded-lg bg-surface p-3" />
      <button type="submit" class="h-12 self-end rounded-lg bg-gold px-5 font-bold text-on-gold disabled:opacity-40" :disabled="busy || !body.trim()">{{ $t('أرسل') }}</button>
    </form>
  </div>
</template>
