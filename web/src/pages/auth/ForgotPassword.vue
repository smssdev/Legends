<script setup lang="ts">
// No approved design yet: built in the style of WebLogin (owner's decision, 2026-10-20).
import { ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import TextField from '../../components/TextField.vue'
import { t } from '../../lib/i18n'

const email = ref('')
const busy = ref(false)
const sent = ref('')
const error = ref('')

async function submit() {
  busy.value = true
  error.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.POST('/auth/forgot-password', { body: { email: email.value.trim() } })
    sent.value = (data as { message?: string } | undefined)?.message ?? t('تحقق من بريدك.')
  } catch (e) {
    const err = asApiError(e)
    error.value = err.field('email') || err.message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div>
    <h1 class="font-display text-3xl font-extrabold">{{ $t('نسيت كلمة المرور؟') }}</h1>
    <p class="mt-1 text-text-muted">{{ $t('اكتب بريدك ونرسل لك رابطاً لاختيار كلمة مرور جديدة.') }}</p>
  </div>
  <p v-if="sent" class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">{{ sent }}</p>
  <form v-else class="flex flex-col gap-4" novalidate @submit.prevent="submit">
    <TextField v-model="email" :label="$t('البريد الإلكتروني')" type="email" autocomplete="email" placeholder="you@example.com" :error="error" />
    <button type="submit" class="h-12 rounded-lg bg-gold text-lg font-bold text-on-gold disabled:opacity-60" :disabled="busy">{{ busy ? $t('جارٍ الإرسال…') : $t('أرسل الرابط') }}</button>
  </form>
  <p class="text-center text-sm text-text-muted"><RouterLink to="/login" class="font-bold text-gold">{{ $t('العودة للدخول') }}</RouterLink></p>
</template>
