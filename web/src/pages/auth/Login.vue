<script setup lang="ts">
// docs/design/legends-ui: WebLogin, MobileLogin.
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { asApiError } from '../../api/client'
import GoogleButton from '../../components/GoogleButton.vue'
import TextField from '../../components/TextField.vue'
import SupportLinks from '../../components/SupportLinks.vue'
import { useAuth } from '../../stores/auth'

const auth = useAuth()
const route = useRoute()
const router = useRouter()
const email = ref('')
const password = ref('')
const remember = ref(true)
const busy = ref(false)
const errors = ref<Record<string, string>>({})
const error = ref('')

// Messages from the links that come back to this screen (Google, the email confirmation).
const notice = computed(() => {
  const q = route.query
  if (q.google === 'off') return 'الدخول بحساب جوجل غير مفعّل بعد. استخدم البريد وكلمة المرور.'
  if (q.google === 'unverified') return 'بريدك في جوجل غير مؤكد، أكّده عند جوجل أولاً.'
  if (q.google === 'failed') return 'لم يكتمل الدخول بجوجل. حاول مجدداً.'
  if (q.verified === 'invalid') return 'رابط التأكيد غير صحيح أو منتهٍ. سجّل الدخول واطلب رابطاً جديداً.'
  if (q.reset === '1') return 'تغيّرت كلمة المرور. ادخل بالجديدة.'
  return ''
})

async function submit() {
  busy.value = true
  errors.value = {}
  error.value = ''
  try {
    await auth.login(email.value.trim(), password.value, remember.value)
    router.replace(typeof route.query.next === 'string' && route.query.next.startsWith('/') ? route.query.next : '/')
  } catch (e) {
    const err = asApiError(e)
    errors.value = { email: err.field('email'), password: err.field('password') }
    if (!errors.value.email && !errors.value.password) error.value = err.message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div>
    <h1 class="font-display text-3xl font-extrabold">أهلاً بعودتك</h1>
    <p class="mt-1 text-text-muted">ادخل لتكمل موسمك</p>
  </div>
  <p v-if="notice" class="rounded-lg bg-surface px-4 py-3 text-sm" role="status">{{ notice }}</p>
  <GoogleButton label="المتابعة بحساب Google" />
  <div class="flex items-center gap-3 text-sm text-text-muted"><span class="h-px flex-1 bg-text/10" />أو بالبريد<span class="h-px flex-1 bg-text/10" /></div>
  <form class="flex flex-col gap-4" novalidate @submit.prevent="submit">
    <TextField v-model="email" label="البريد أو اسم المستخدم" type="username" autocomplete="username" placeholder="you@example.com" :error="errors.email" />
    <TextField v-model="password" label="كلمة المرور" type="password" autocomplete="current-password" :error="errors.password">
      <template #aside><RouterLink to="/forgot-password" class="text-sm text-gold">نسيت كلمة المرور؟</RouterLink></template>
    </TextField>
    <label class="flex min-h-touch items-center gap-3 text-sm"><input v-model="remember" type="checkbox" class="size-5 accent-[var(--color-gold)]" />تذكرني على هذا الجهاز</label>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <button type="submit" class="h-12 rounded-lg bg-gold text-lg font-bold text-on-gold disabled:opacity-60" :disabled="busy">{{ busy ? 'جارٍ الدخول…' : 'دخول' }}</button>
  </form>
  <p class="text-center text-sm text-text-muted">ليس لديك حساب؟ <RouterLink to="/register" class="font-bold text-gold">أنشئ حساباً</RouterLink></p>
  <SupportLinks />
</template>
