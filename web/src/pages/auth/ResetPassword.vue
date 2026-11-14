<script setup lang="ts">
// Opened from the reset email. No approved design yet: built in the style of WebLogin.
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'
import UiInput from '../../components/ui/UiInput.vue'

const route = useRoute()
const router = useRouter()
const password = ref('')
const busy = ref(false)
const errors = ref<Record<string, string>>({})
const token = String(route.query.token ?? '')
const email = String(route.query.email ?? '')

async function submit() {
  busy.value = true
  errors.value = {}
  try {
    await ensureCsrf()
    await api.POST('/auth/reset-password', { body: { token, email, password: password.value } })
    router.replace('/login?reset=1')
  } catch (e) {
    const err = asApiError(e)
    errors.value = { password: err.field('password'), other: err.field('email') || (err.field('password') ? '' : err.message) }
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div>
    <h1 class="font-display text-3xl font-extrabold">{{ $t('كلمة مرور جديدة') }}</h1>
    <p class="mt-1 text-text-muted" dir="auto">
      {{ $t('للحساب') }} <span dir="ltr" class="font-bold">{{ email }}</span>
    </p>
  </div>
  <p v-if="!token || !email" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">
    {{ $t('الرابط ناقص. افتحه من رسالة البريد كما هو، أو اطلب رابطاً جديداً.') }}
  </p>
  <form v-else class="flex flex-col gap-4" novalidate @submit.prevent="submit">
    <UiInput
      v-model="password"
      :label="$t('كلمة المرور الجديدة')"
      type="password"
      autocomplete="new-password"
      :error="errors.password"
      :hint="$t('8 أحرف على الأقل، فيها حروف وأرقام')"
    />
    <p v-if="errors.other" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">
      {{ errors.other }} <RouterLink to="/forgot-password" class="font-bold text-gold">{{ $t('اطلب رابطاً جديداً') }}</RouterLink>
    </p>
    <button type="submit" class="h-12 rounded-lg bg-gold text-lg font-bold text-on-gold disabled:opacity-60" :disabled="busy">
      {{ busy ? $t('جارٍ الحفظ…') : $t('احفظ كلمة المرور') }}
    </button>
  </form>
</template>
