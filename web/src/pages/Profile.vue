<script setup lang="ts">
// The account (Sprint 10 W1). No approved design yet: built with the cards of WebHome.
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../api/client'
import NotificationsCard from '../components/NotificationsCard.vue'
import TextField from '../components/TextField.vue'
import { useAuth } from '../stores/auth'

const auth = useAuth()
const route = useRoute()
const router = useRouter()
// Kept after sign-out until the page changes, so nothing reads a missing account.
const user = computed(() => auth.user ?? last)
let last = auth.user!

const welcome = computed(() =>
  route.query.verified === '1' ? 'تم تأكيد بريدك. حسابك جاهز.' : route.query.welcome === '1' ? 'أهلاً بك! أرسلنا رسالة إلى بريدك، اضغط الرابط فيها لتأكيده.' : '',
)

const name = ref(user.value.name)
watch(() => auth.user, (u) => u && (last = u))
const nameMsg = ref('')
const nameErr = ref('')
async function saveName() {
  nameMsg.value = nameErr.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.PATCH('/auth/me', { body: { name: name.value.trim() } })
    auth.set(data!.user!)
    nameMsg.value = 'حُفظ الاسم.'
  } catch (e) {
    const err = asApiError(e)
    nameErr.value = err.field('name') || err.message
  }
}

const resendMsg = ref('')
async function resend() {
  try {
    await ensureCsrf()
    await api.POST('/auth/email/resend')
    resendMsg.value = 'أرسلنا الرسالة من جديد. تحقق من بريدك (والرسائل غير المرغوبة).'
  } catch (e) {
    resendMsg.value = asApiError(e).message
  }
}

const current = ref('')
const next = ref('')
const pwErrors = ref<Record<string, string>>({})
const pwMsg = ref('')
async function savePassword() {
  pwErrors.value = {}
  pwMsg.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/auth/password', { body: { current_password: current.value || undefined, password: next.value } })
    auth.set(data!.user!)
    current.value = next.value = ''
    pwMsg.value = 'تغيّرت كلمة المرور.'
  } catch (e) {
    const err = asApiError(e)
    pwErrors.value = { current: err.field('current_password'), next: err.field('password') || (err.field('current_password') ? '' : err.message) }
  }
}

async function logout() {
  await auth.logout()
  router.replace('/login')
}

const deleting = ref(false)
const confirmText = ref('')
const delErr = ref('')
async function remove() {
  delErr.value = ''
  try {
    await ensureCsrf()
    await api.DELETE('/auth/me', { body: user.value.has_password ? { password: confirmText.value } : { confirm: confirmText.value } })
    auth.set(null)
    router.replace('/login')
  } catch (e) {
    const err = asApiError(e)
    delErr.value = err.field('password') || err.field('confirm') || err.message
  }
}
</script>

<template>
  <div class="flex flex-col gap-5">
    <h1 class="font-display text-3xl font-extrabold">حسابي</h1>
    <p v-if="welcome" class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">{{ welcome }}</p>

    <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-account">
      <h2 id="h-account" class="font-display text-xl font-extrabold">الحساب</h2>
      <div class="flex flex-wrap items-center gap-2">
        <span class="text-sm text-text-muted">البريد</span>
        <span dir="ltr" class="font-bold">{{ user.email }}</span>
        <span v-if="user.email_verified" class="rounded-pill bg-success/15 px-2.5 py-0.5 text-xs text-success">مؤكد</span>
        <span v-else class="rounded-pill bg-warning/15 px-2.5 py-0.5 text-xs text-warning">غير مؤكد</span>
        <span v-if="user.google" class="rounded-pill bg-surface-raised px-2.5 py-0.5 text-xs">مرتبط بجوجل</span>
      </div>
      <div v-if="!user.email_verified" class="flex flex-col gap-2 rounded-lg bg-warning/10 p-3 text-sm">
        <p>أكّد بريدك من الرابط الذي أرسلناه، لتستطيع استعادة حسابك إن نسيت كلمة المرور.</p>
        <button type="button" class="h-touch self-start rounded-md bg-surface-raised px-4 font-bold" @click="resend">أرسل الرابط من جديد</button>
        <p v-if="resendMsg" role="status">{{ resendMsg }}</p>
      </div>
      <form class="flex flex-col gap-3 sm:flex-row sm:items-end" novalidate @submit.prevent="saveName">
        <div class="flex-1"><TextField v-model="name" label="اسمك في اللعبة" autocomplete="nickname" :error="nameErr" /></div>
        <button type="submit" class="h-12 rounded-lg bg-surface-raised px-5 font-bold">احفظ</button>
      </form>
      <p v-if="nameMsg" class="text-sm text-success" role="status">{{ nameMsg }}</p>
    </section>

    <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-password">
      <h2 id="h-password" class="font-display text-xl font-extrabold">{{ user.has_password ? 'تغيير كلمة المرور' : 'أضف كلمة مرور' }}</h2>
      <p v-if="!user.has_password" class="text-sm text-text-muted">حسابك بجوجل فقط. أضف كلمة مرور لتدخل بالبريد أيضاً.</p>
      <form class="grid gap-3 sm:grid-cols-2" novalidate @submit.prevent="savePassword">
        <TextField v-if="user.has_password" v-model="current" label="كلمة المرور الحالية" type="password" autocomplete="current-password" :error="pwErrors.current" />
        <TextField v-model="next" label="كلمة المرور الجديدة" type="password" autocomplete="new-password" :error="pwErrors.next" hint="8 أحرف على الأقل، فيها حروف وأرقام" />
        <button type="submit" class="h-12 rounded-lg bg-surface-raised px-5 font-bold sm:col-span-2 sm:justify-self-start">احفظ كلمة المرور</button>
      </form>
      <p v-if="pwMsg" class="text-sm text-success" role="status">{{ pwMsg }}</p>
    </section>

    <button type="button" class="h-12 rounded-lg border border-text/15 font-bold" @click="logout">تسجيل الخروج</button>

    <NotificationsCard />

    <section class="flex flex-col gap-3 rounded-xl border border-live/40 p-4" aria-labelledby="h-delete">
      <h2 id="h-delete" class="font-display text-xl font-extrabold text-[#FF8A8A]">حذف الحساب</h2>
      <p class="text-sm text-text-muted">يُحذف حسابك وكل ما يخصه نهائياً، وفرقك في الدوريات تعود للحاسوب. لا يمكن التراجع.</p>
      <button v-if="!deleting" type="button" class="h-touch self-start rounded-md bg-live/15 px-4 font-bold text-[#FF8A8A]" @click="deleting = true">أريد حذف حسابي</button>
      <form v-else class="flex flex-col gap-3" novalidate @submit.prevent="remove">
        <TextField
          v-model="confirmText"
          :label="user.has_password ? 'اكتب كلمة المرور للتأكيد' : 'اكتب بريدك للتأكيد'"
          :type="user.has_password ? 'password' : 'email'"
          :autocomplete="user.has_password ? 'current-password' : 'off'"
          :error="delErr"
        />
        <div class="flex gap-2">
          <button type="submit" class="h-12 flex-1 rounded-lg bg-live px-4 font-bold text-white">احذف حسابي نهائياً</button>
          <button type="button" class="h-12 rounded-lg bg-surface-raised px-4 font-bold" @click="deleting = false; confirmText = ''">تراجع</button>
        </div>
      </form>
    </section>
  </div>
</template>
