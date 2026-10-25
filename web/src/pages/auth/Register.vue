<script setup lang="ts">
// docs/design/legends-ui: WebRegister, MobileRegister.
import UiToggle from '../../components/ui/UiToggle.vue'
import { computed, ref } from 'vue'
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
const email = ref('')
const password = ref('')
const confirm = ref('')
const mismatch = computed(() => confirm.value !== '' && confirm.value !== password.value)
const terms = ref(false)
const busy = ref(false)
const errors = ref<Record<string, string>>({})
const error = ref('')

/** 0 to 4 bars: length, letters, numbers, and a mix of cases or a symbol. */
const strength = computed(() => {
  const p = password.value
  if (!p) return 0
  return [p.length >= 8, /\p{L}/u.test(p), /\d/.test(p), p.length >= 12 || /[^\p{L}\d]/u.test(p) || (/[a-z]/.test(p) && /[A-Z]/.test(p))].filter(Boolean).length
})

async function submit() {
  errors.value = {}
  error.value = ''
  if (password.value !== confirm.value) {
    errors.value = { confirm: 'تأكيد كلمة المرور غير مطابق.' }
    return
  }
  busy.value = true
  try {
    await usernameField.value?.settle()
    const sent = await auth.register(name.value.trim(), username.value.trim(), email.value.trim(), password.value, confirm.value, terms.value)
    router.replace(sent ? '/profile?welcome=1' : '/profile?welcome=unsent')
  } catch (e) {
    const err = asApiError(e)
    errors.value = Object.fromEntries(['name', 'username', 'email', 'password', 'terms'].map((k) => [k, err.field(k)]))
    if (!Object.values(errors.value).some(Boolean)) error.value = err.message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <h1 class="font-display text-3xl font-extrabold">أنشئ حسابك</h1>
  <GoogleButton label="التسجيل بحساب Google" />
  <div class="flex items-center gap-3 text-sm text-text-muted"><span class="h-px flex-1 bg-text/10" />أو بالبريد<span class="h-px flex-1 bg-text/10" /></div>
  <form class="flex flex-col gap-4" novalidate @submit.prevent="submit">
    <TextField v-model="name" label="اسمك في اللعبة" autocomplete="nickname" placeholder="مثلاً: كوتش حمزة" :error="errors.name" />
    <UsernameField ref="usernameField" v-model="username" :error="errors.username" />
    <TextField v-model="email" label="البريد الإلكتروني" type="email" autocomplete="email" placeholder="you@example.com" :error="errors.email" />
    <div class="flex flex-col gap-2">
      <TextField v-model="password" label="كلمة المرور" type="password" autocomplete="new-password" :error="errors.password" hint="8 أحرف على الأقل، فيها حروف وأرقام" />
      <div class="grid grid-cols-4 gap-2" role="meter" aria-label="قوة كلمة المرور" :aria-valuenow="strength" aria-valuemin="0" aria-valuemax="4">
        <span v-for="i in 4" :key="i" class="h-1.5 rounded-pill" :class="i <= strength ? (strength >= 3 ? 'bg-success' : 'bg-warning') : 'bg-surface-raised'" />
      </div>
    </div>
    <TextField v-model="confirm" label="تأكيد كلمة المرور" type="password" autocomplete="new-password" :error="errors.confirm || (mismatch ? 'كلمتا المرور غير متطابقتين' : '')" />
    <UiToggle v-model="terms" label="أوافق على الشروط وسياسة الخصوصية" />
    <p v-if="errors.terms" class="-mt-3 text-sm text-[#FF8A8A]">{{ errors.terms }}</p>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <button type="submit" class="h-12 rounded-lg bg-gold text-lg font-bold text-on-gold disabled:opacity-60" :disabled="busy">{{ busy ? 'جارٍ الإنشاء…' : 'إنشاء الحساب' }}</button>
  </form>
  <p class="text-center text-sm text-text-muted">عندك حساب؟ <RouterLink to="/login" class="font-bold text-gold">سجّل الدخول</RouterLink></p>
</template>
