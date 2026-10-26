<script setup lang="ts">
// docs/design/legends-ui: WebRegister, MobileRegister. [UP5] The owner's spec (1): Google in one tap first, else three
// fields on one screen (the name, the username, the password typed once and as simple as the coach likes).
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { asApiError } from '../../api/client'
import GoogleButton from '../../components/GoogleButton.vue'
import TextField from '../../components/TextField.vue'
import UsernameField from '../../components/UsernameField.vue'
import { useAuth } from '../../stores/auth'

const auth = useAuth()
const router = useRouter()
const name = ref('')
const username = ref('')
const usernameField = ref<InstanceType<typeof UsernameField> | null>(null)
const password = ref('')
const busy = ref(false)
const errors = ref<Record<string, string>>({})
const error = ref('')

async function submit() {
  errors.value = {}
  error.value = ''
  busy.value = true
  try {
    await usernameField.value?.settle()
    await auth.register(name.value.trim(), username.value.trim(), password.value)
    router.replace('/profile?welcome=1')
  } catch (e) {
    const err = asApiError(e)
    errors.value = Object.fromEntries(['name', 'username', 'password'].map((k) => [k, err.field(k)]))
    if (!Object.values(errors.value).some(Boolean)) error.value = err.message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <h1 class="font-display text-3xl font-extrabold">{{ $t('أنشئ حسابك') }}</h1>
  <GoogleButton :label="$t('الدخول السريع بحساب Google')" />
  <div class="flex items-center gap-3 text-sm text-text-muted"><span class="h-px flex-1 bg-text/10" />{{ $t('أو بثلاث خانات') }}<span class="h-px flex-1 bg-text/10" /></div>
  <form class="flex flex-col gap-4" novalidate @submit.prevent="submit">
    <TextField v-model="name" :label="$t('الاسم')" autocomplete="nickname" :placeholder="$t('مثلاً: كوتش حمزة')" :error="errors.name" :hint="$t('يظهر للآخرين في اللعبة')" />
    <UsernameField ref="usernameField" v-model="username" :error="errors.username" />
    <TextField v-model="password" :label="$t('كلمة المرور')" type="password" autocomplete="new-password" :error="errors.password" :hint="$t('4 أحرف أو أرقام على الأقل، كما تحب')" />
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <button type="submit" class="h-12 rounded-lg bg-gold text-lg font-bold text-on-gold disabled:opacity-60" :disabled="busy">{{ busy ? $t('جارٍ الإنشاء…') : $t('إنشاء الحساب') }}</button>
  </form>
  <p class="text-center text-sm text-text-muted">{{ $t('عندك حساب؟') }} <RouterLink to="/login" class="font-bold text-gold">{{ $t('سجّل الدخول') }}</RouterLink></p>
</template>
