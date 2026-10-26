<script setup lang="ts">
// The account (Sprint 10 W1). No approved design yet: built with the cards of WebHome.
import UiToggle from '../components/ui/UiToggle.vue'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../api/client'
import NotificationsCard from '../components/NotificationsCard.vue'
import TextField from '../components/TextField.vue'
import UsernameField from '../components/UsernameField.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
import SupportLinks from '../components/SupportLinks.vue'
import { useAuth } from '../stores/auth'
import { useWallet } from '../stores/wallet'
import { AR_VOICES, arVoiceName, type ArVoice } from '../match/voice'
import { ARABIC_COMMENTARY, MATCH_VIEWS, useViewing, type MatchView } from '../match/viewing'
import { namesLang, setNamesLang } from '../lib/names'
import { t } from '../lib/i18n'
import LanguageSwitch from '../components/LanguageSwitch.vue'

const auth = useAuth()
const route = useRoute()
const router = useRouter()
// Kept after sign-out until the page changes, so nothing reads a missing account.
const user = computed(() => auth.user ?? last)
let last = auth.user!

const welcome = computed(() =>
  route.query.verified === '1' ? 'تم تأكيد بريدك. حسابك جاهز.' : route.query.welcome === '1' ? 'أهلاً بك! أرسلنا رسالة إلى بريدك، اضغط الرابط فيها لتأكيده.' : route.query.welcome === 'unsent' ? 'أهلاً بك! تعذر إرسال رسالة التأكيد الآن، اضغط «أرسل الرابط من جديد» بعد قليل.' : '',
)

// The simulator and the commentator [X9, X10].
const viewing = useViewing()
const viewMsg = ref('')
const viewErr = ref(false)
async function saveViewing(body: { commentator?: ArVoice; match_view?: MatchView }) {
  viewMsg.value = ''
  try {
    await viewing.save(body)
    viewErr.value = false
    viewMsg.value = t('حُفظ.')
  } catch (e) {
    viewErr.value = true
    viewMsg.value = asApiError(e).message
  }
}

const name = ref(user.value.name)
const username = ref(user.value.username)
watch(() => auth.user, (u) => u && (last = u))
const nameMsg = ref('')
const nameErr = ref('')
async function saveName() {
  nameMsg.value = nameErr.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.PATCH('/auth/me', { body: { name: name.value.trim(), username: username.value } })
    auth.set(data!.user!)
    nameMsg.value = t('حُفظ.')
  } catch (e) {
    const err = asApiError(e)
    nameErr.value = err.field('name') || (err.field('username') ? '' : err.message)
    userErr.value = err.field('username')
  }
}
const userErr = ref('')

// The picture [X4]: the server cuts it square and keeps it small.
const picture = ref<HTMLInputElement | null>(null)
const picErr = ref('')
const picBusy = ref(false)
async function upload(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  picErr.value = ''
  picBusy.value = true
  try {
    await ensureCsrf()
    const form = new FormData()
    form.append('image', file)
    const { data } = await api.POST('/auth/avatar', { body: form as never, bodySerializer: (b) => b as unknown as FormData })
    auth.set(data!.user!)
  } catch (err) {
    const ae = asApiError(err)
    picErr.value = ae.field('image') || ae.message
  } finally {
    picBusy.value = false
    if (picture.value) picture.value.value = ''
  }
}
async function removePicture() {
  picErr.value = ''
  try {
    await ensureCsrf()
    const { data } = await api.DELETE('/auth/avatar')
    auth.set(data!.user!)
  } catch (err) {
    picErr.value = asApiError(err).message
  }
}

// The account's holiday [X4, UP13]: every league at once, so no team is lost while away. The days and the reason:
// up to 5 days start at once (twice a season), a longer one waits for the developers.
const holidayDays = ref(3)
const holidayReason = ref('')
const holidayMsg = ref('')
const holidayDone = ref('')
const dateText = (iso: string | null) => (iso ? new Date(iso).toLocaleString('ar-EG', { dateStyle: 'medium', timeStyle: 'short' }) : '')
async function holiday(start: boolean) {
  holidayMsg.value = ''
  try {
    await ensureCsrf()
    const { data } = start ? await api.POST('/auth/vacation', { body: { days: holidayDays.value, reason: holidayReason.value.trim() } }) : await api.DELETE('/auth/vacation')
    auth.set(data!.user!)
    holidayDone.value = start && (data as any)?.vacation?.status === 'pending' ? 'أُرسل طلبك لفريق التطوير، وسيصلك ردهم في صندوق الرسائل.' : ''
  } catch (err) {
    holidayMsg.value = asApiError(err).message
  }
}

// [UP6] The WhatsApp code: verifies the account and the welcome coins arrive.
const verifyCode = ref('')
const verifyErr = ref('')
const verifyBusy = ref(false)
const verifiedNow = ref(0)
async function verifyAccount() {
  verifyErr.value = ''
  verifyBusy.value = true
  try {
    await ensureCsrf()
    const { data } = await api.POST('/auth/verify-account', { body: { code: verifyCode.value.trim() } })
    auth.set(data!.user)
    verifiedNow.value = data!.coins
    void useWallet().load()
  } catch (e) {
    const err = asApiError(e)
    verifyErr.value = err.field('code') || err.message
  } finally {
    verifyBusy.value = false
  }
}

const resendMsg = ref('')
async function resend() {
  try {
    await ensureCsrf()
    await api.POST('/auth/email/resend')
    resendMsg.value = t('أرسلنا الرسالة من جديد. تحقق من بريدك (والرسائل غير المرغوبة).')
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
    pwMsg.value = t('تغيّرت كلمة المرور.')
  } catch (e) {
    const err = asApiError(e)
    pwErrors.value = { current: err.field('current_password'), next: err.field('password') || (err.field('current_password') ? '' : err.message) }
  }
}

async function logout() {
  await auth.logout()
  router.replace('/login')
}

const confirmText = ref('')
const delErr = ref('')
const deleteStep = ref<0 | 1 | 2>(0)
const understood = ref(false)
const phrase = ref('')
const phraseErr = ref('')
function cancelDelete() {
  deleteStep.value = 0
  understood.value = false
  phrase.value = confirmText.value = delErr.value = phraseErr.value = ''
}
async function remove() {
  delErr.value = phraseErr.value = ''
  try {
    await ensureCsrf()
    const proof = user.value.has_password ? { password: confirmText.value } : { confirm: confirmText.value }
    await api.DELETE('/auth/me', { body: { ...proof, phrase: phrase.value.trim() as 'احذف' } })
    auth.set(null)
    router.replace('/login')
  } catch (e) {
    const err = asApiError(e)
    phraseErr.value = err.field('phrase')
    delErr.value = err.field('password') || err.field('confirm') || (phraseErr.value ? '' : err.message)
  }
}
</script>

<template>
  <div class="flex flex-col gap-5">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <h1 class="font-display text-3xl font-extrabold">{{ $t('حسابي') }}</h1>
      <!-- [UP2] The game's language, kept on the account. -->
      <LanguageSwitch />
    </div>
    <p v-if="welcome" class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">{{ welcome }}</p>

    <!-- [UP6] The welcome coins wait for the account to be verified: this stays until it is. -->
    <section v-if="!user.verification?.verified" class="flex flex-col gap-3 rounded-xl border border-warning/50 bg-warning/10 p-4" aria-labelledby="h-verify">
      <h2 id="h-verify" class="font-display text-lg font-extrabold text-warning">{{ $t('تنبيه: لن يتم تحصيل مكافأة الـ {v0} كوينز في رصيدك إلا عند توثيق الحساب.', { v0: user.verification?.welcome_coins ?? 1000 }) }}</h2>
      <a v-if="user.verification?.whatsapp" :href="user.verification.whatsapp" target="_blank" rel="noopener" class="flex h-12 items-center justify-center gap-2 self-start rounded-lg bg-[#25D366] px-5 font-bold text-[#0B2E13]">
        {{ $t('وثّق حسابك الآن عبر WhatsApp') }}
      </a>
      <p v-else class="text-sm text-text-muted">{{ $t('راسل الدعم ليرسل لك كود التفعيل.') }}</p>
      <form class="flex flex-wrap items-end gap-2" novalidate @submit.prevent="verifyAccount">
        <div class="min-w-40 flex-1"><TextField v-model="verifyCode" :label="$t('كود التوثيق')" inputmode="numeric" autocomplete="one-time-code" dir="ltr" :error="verifyErr" /></div>
        <button type="submit" class="h-12 rounded-lg bg-gold px-5 font-bold text-on-gold disabled:opacity-60" :disabled="verifyBusy || !verifyCode.trim()">{{ $t('تأكيد وتفعيل') }}</button>
      </form>
    </section>
    <p v-else-if="verifiedNow" class="rounded-xl bg-success/15 p-4 font-bold text-success" role="status">{{ $t('تم توثيق حسابك، وأُضيفت {v0} كوينز إلى رصيدك.', { v0: verifiedNow }) }}</p>

    <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-account">
      <h2 id="h-account" class="font-display text-xl font-extrabold">{{ $t('الحساب') }}</h2>
      <div class="flex items-center gap-4">
        <img v-if="user.avatar_url" :src="user.avatar_url" :alt="$t('صورتك')" class="size-20 rounded-full object-cover" />
        <span v-else class="flex size-20 items-center justify-center rounded-full bg-gold font-display text-3xl font-extrabold text-on-gold">{{ user.name.trim().charAt(0) }}</span>
        <div class="flex flex-col gap-2">
          <span class="font-bold" dir="ltr">@{{ user.username }}</span> <OfficialBadge v-if="user.official" />
          <div class="flex flex-wrap gap-2">
            <label class="flex h-touch cursor-pointer items-center rounded-md bg-surface-raised px-4 font-bold" :class="picBusy ? 'opacity-60' : ''">
              {{ picBusy ? $t('جارٍ الرفع…') : user.avatar_url ? $t('غيّر الصورة') : $t('أضف صورة') }}
              <input ref="picture" type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="sr-only" :disabled="picBusy" @change="upload" />
            </label>
            <button v-if="user.avatar_url" type="button" class="h-touch rounded-md px-3 text-sm text-text-muted" @click="removePicture">{{ $t('احذف الصورة') }}</button>
          </div>
          <p v-if="picErr" class="text-sm text-[#FF8A8A]" role="alert">{{ picErr }}</p>
        </div>
      </div>
      <div v-if="user.email" class="flex flex-wrap items-center gap-2">
        <span class="text-sm text-text-muted">{{ $t('البريد') }}</span>
        <span dir="ltr" class="font-bold">{{ user.email }}</span>
        <span v-if="user.email_verified" class="rounded-pill bg-success/15 px-2.5 py-0.5 text-xs text-success">{{ $t('مؤكد') }}</span>
        <span v-else class="rounded-pill bg-warning/15 px-2.5 py-0.5 text-xs text-warning">{{ $t('غير مؤكد') }}</span>
        <span v-if="user.google" class="rounded-pill bg-surface-raised px-2.5 py-0.5 text-xs">{{ $t('مرتبط بجوجل') }}</span>
      </div>
      <div v-if="user.email && !user.email_verified" class="flex flex-col gap-2 rounded-lg bg-warning/10 p-3 text-sm">
        <p>{{ $t('أكّد بريدك من الرابط الذي أرسلناه، لتستطيع استعادة حسابك إن نسيت كلمة المرور.') }}</p>
        <button type="button" class="h-touch self-start rounded-md bg-surface-raised px-4 font-bold" @click="resend">{{ $t('أرسل الرابط من جديد') }}</button>
        <p v-if="resendMsg" role="status">{{ $t(resendMsg) }}</p>
      </div>
      <form class="flex flex-col gap-3 sm:flex-row sm:items-end" novalidate @submit.prevent="saveName">
        <div class="flex-1"><TextField v-model="name" :label="$t('اسمك في اللعبة')" autocomplete="nickname" :error="nameErr" /></div>
        <div class="flex-1"><UsernameField v-model="username" :error="userErr" :current="user.username" /></div>
        <button type="submit" class="h-12 rounded-lg bg-surface-raised px-5 font-bold">{{ $t('احفظ') }}</button>
      </form>
      <p v-if="nameMsg" class="text-sm text-success" role="status">{{ $t(nameMsg) }}</p>
    </section>

    <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-password">
      <h2 id="h-password" class="font-display text-xl font-extrabold">{{ user.has_password ? $t('تغيير كلمة المرور') : $t('أضف كلمة مرور') }}</h2>
      <p v-if="!user.has_password" class="text-sm text-text-muted">{{ $t('حسابك بجوجل فقط. أضف كلمة مرور لتدخل بالبريد أيضاً.') }}</p>
      <form class="grid gap-3 sm:grid-cols-2" novalidate @submit.prevent="savePassword">
        <TextField v-if="user.has_password" v-model="current" :label="$t('كلمة المرور الحالية')" type="password" autocomplete="current-password" :error="pwErrors.current" />
        <TextField v-model="next" :label="$t('كلمة المرور الجديدة')" type="password" autocomplete="new-password" :error="pwErrors.next" :hint="$t('4 أحرف أو أرقام على الأقل')" />
        <button type="submit" class="h-12 rounded-lg bg-surface-raised px-5 font-bold sm:col-span-2 sm:justify-self-start">{{ $t('احفظ كلمة المرور') }}</button>
      </form>
      <p v-if="pwMsg" class="text-sm text-success" role="status">{{ $t(pwMsg) }}</p>
    </section>

    <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-viewing">
      <h2 id="h-viewing" class="font-display text-xl font-extrabold">{{ $t('مشاهدة المباريات') }}</h2>
      <fieldset class="flex flex-col gap-2">
        <legend class="mb-1 text-sm font-bold">{{ $t('المحاكي') }}</legend>
        <label v-for="v in MATCH_VIEWS" :key="v.id" class="flex min-h-touch cursor-pointer items-center gap-3 rounded-lg border px-3 py-2" :class="viewing.chosenView.value === v.id ? 'border-gold bg-gold/10' : 'border-text/10'">
          <input type="radio" name="match-view" class="size-5 accent-[var(--color-gold)]" :value="v.id" :checked="viewing.chosenView.value === v.id" @change="saveViewing({ match_view: v.id })" />
          <span class="flex flex-col">
            <span class="font-bold">{{ $nm(v.name) }} <span v-if="v.id === 'unity' && !viewing.unityReady.value" class="rounded-pill bg-warning/15 px-2 py-0.5 text-xs text-warning">{{ $t('قريباً') }}</span></span>
            <span class="text-xs text-text-muted">{{ $t(v.hint) }}</span>
          </span>
        </label>
        <p v-if="viewing.chosenView.value === 'unity' && !viewing.unityReady.value" class="text-xs text-text-muted">{{ $t('حتى يجهز المطوّر تُعرض مبارياتك بالكرتوني، وتنتقل إليه تلقائياً حين يجهز.') }}</p>
      </fieldset>
      <label v-if="ARABIC_COMMENTARY" class="flex flex-col gap-1.5">
        <span class="text-sm font-bold">{{ $t('المعلق العربي') }}</span>
        <select class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-3" :value="viewing.commentator.value" @change="saveViewing({ commentator: ($event.target as HTMLSelectElement).value as ArVoice })">
          <option v-for="v in AR_VOICES" :key="v" :value="v">{{ arVoiceName(v) }}</option>
        </select>
        <span class="text-xs text-text-muted">{{ $t('يُسمع في كل مبارياتك، ويُبدَّل أثناء المباراة أيضاً.') }}</span>
      </label>
      <!-- [X40] The names switch: the leagues, clubs and players in Arabic or in English, on this device. -->
      <fieldset class="flex flex-col gap-2">
        <legend class="mb-1 text-sm font-bold">{{ $t('أسماء الدوريات والأندية واللاعبين') }}</legend>
        <div class="grid grid-cols-2 gap-2" role="radiogroup" :aria-label="$t('لغة الأسماء')">
          <button v-for="[k, l] in ([['ar', 'العربية'], ['en', 'English']] as const)" :key="k" type="button" role="radio" :aria-checked="namesLang === k"
            class="h-12 rounded-lg font-bold" :class="namesLang === k ? 'bg-brand' : 'bg-surface-sunk text-text-soft'" @click="setNamesLang(k)">{{ l }}</button>
        </div>
        <span class="text-xs text-text-muted">{{ $t('ما لا نعرف له اسماً عربياً يبقى كما هو. والتعليق الإنجليزي ينطق الأسماء الإنجليزية دائماً.') }}</span>
      </fieldset>
      <p v-if="viewMsg" class="text-sm" :class="viewErr ? 'text-[#FF8A8A]' : 'text-success'" role="status">{{ $t(viewMsg) }}</p>
    </section>

    <RouterLink :to="{ name: 'developers' }" class="flex min-h-touch items-center justify-between rounded-xl bg-surface px-4 py-3"><span><b class="block">{{ $t('فريق التطوير') }}</b><span class="text-sm text-text-muted">{{ $t('تعرّف على من صنع اللعبة') }}</span></span><span class="font-bold text-gold">←</span></RouterLink>

    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-holiday">
      <h2 id="h-holiday" class="font-display text-xl font-extrabold">{{ $t('إجازة الحساب') }}</h2>
      <!-- [UP13] The owner's spec (7): said plainly where the coach sees it. -->
      <p class="rounded-lg border border-warning/50 bg-warning/10 px-4 py-3 text-sm font-bold text-warning" role="note">
        {{ $t('تنبيه رسمي: إذا لم يتم استخدام حسابك أو تسجيل الدخول لمدة {v0} يوماً متواصلة (دون تفعيل إجازة رسمية)، فسيتم حذف الحساب وبيانات الفرق نهائياً وتلقائياً.', { v0: user.inactivity_days }) }}
      </p>
      <p class="text-sm text-text-muted">{{ $t('إجازة لحسابك كله تحميه من الحذف: لا يُحسب غيابك في أي دوري، والمدرب المساعد يقود فرقك. حتى {v0} أيام تبدأ فوراً (مرتين في الموسم)، والأطول يراجعها فريق التطوير. ولإجازة في دوري واحد اطلبها من صفحة الدوري.', { v0: user.vacation.auto_days }) }}</p>
      <template v-if="user.vacation.on">
        <p class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">{{ $t('أنت في إجازة حتى {v0}.', { v0: dateText(user.vacation.until) }) }}</p>
        <button type="button" class="h-touch self-start rounded-md bg-surface-raised px-4 font-bold" @click="holiday(false)">{{ $t('عدت، أنهِ الإجازة') }}</button>
      </template>
      <p v-else-if="user.vacation.pending" class="rounded-lg bg-surface-sunk px-4 py-3 text-sm" role="status">{{ $t('طلب إجازتك ({v0} يوماً) ينتظر رد فريق التطوير.', { v0: user.vacation.pending }) }}</p>
      <form v-else class="flex flex-col gap-3" @submit.prevent="holiday(true)">
        <div class="flex flex-wrap items-end gap-2">
          <label class="flex flex-col gap-1.5 text-sm font-bold">{{ $t('عدد الأيام') }}
            <input v-model.number="holidayDays" type="number" min="1" :max="user.vacation.max_days" inputmode="numeric" class="h-12 w-28 rounded-lg border border-text/10 bg-surface-sunk px-3 font-numbers" />
          </label>
          <label class="flex min-w-60 flex-1 flex-col gap-1.5 text-sm font-bold">{{ $t('السبب') }}
            <input v-model="holidayReason" type="text" maxlength="300" :placeholder="$t('مثلاً: سفر، امتحانات')" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-3" />
          </label>
        </div>
        <p class="text-xs text-text-muted">{{ holidayDays > user.vacation.auto_days ? $t('أكثر من ') + user.vacation.auto_days + $t(' أيام: يُرسل الطلب لفريق التطوير ليراجعه.') : $t('تبدأ فوراً.') }}</p>
        <button type="submit" class="h-12 self-start rounded-lg bg-gold px-5 font-bold text-on-gold" :disabled="!holidayReason.trim()">{{ holidayDays > user.vacation.auto_days ? $t('أرسل الطلب') : $t('ابدأ الإجازة') }}</button>
      </form>
      <p v-if="holidayDone" class="text-sm text-success" role="status">{{ $t(holidayDone) }}</p>
      <p v-if="holidayMsg" class="text-sm text-[#FF8A8A]" role="alert">{{ $t(holidayMsg) }}</p>
    </section>

    <NotificationsCard />

    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-support">
      <h2 id="h-support" class="font-display text-xl font-extrabold">{{ $t('الدعم الفني') }}</h2>
      <SupportLinks />
      <p class="text-xs text-text-muted">{{ $t('إن لم تظهر الأزرار فالدعم لم يُفعَّل على الخادم بعد.') }}</p>
    </section>

    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-signout">
      <h2 id="h-signout" class="font-display text-xl font-extrabold">{{ $t('تسجيل الخروج') }}</h2>
      <p class="text-sm text-text-muted">{{ $t('تخرج من هذا الجهاز فقط، وحسابك وفرقك باقية كما هي.') }}</p>
      <button type="button" class="h-touch self-start rounded-md border border-text/15 px-4 font-bold" @click="logout">{{ $t('تسجيل الخروج') }}</button>
    </section>

    <!-- Deleting is apart from signing out, and asks twice [X12]: what is lost, then the word and the password. -->
    <section class="flex flex-col gap-3 rounded-xl border border-live/40 p-4" aria-labelledby="h-delete">
      <h2 id="h-delete" class="font-display text-xl font-extrabold text-[#FF8A8A]">{{ $t('حذف الحساب نهائياً') }}</h2>
      <p class="text-sm text-text-muted">{{ $t('لا علاقة له بتسجيل الخروج: الحذف لا يمكن التراجع عنه.') }}</p>
      <button v-if="deleteStep === 0" type="button" class="h-touch self-start rounded-md bg-live/15 px-4 font-bold text-[#FF8A8A]" @click="deleteStep = 1">{{ $t('أريد حذف حسابي') }}</button>
      <div v-else-if="deleteStep === 1" class="flex flex-col gap-3 rounded-lg bg-live/10 p-3 text-sm" role="alertdialog" aria-labelledby="h-delete-1">
        <b id="h-delete-1">{{ $t('الخطوة 1 من 2: هذا ما سيضيع للأبد') }}</b>
        <ul class="list-disc ps-5 text-text-soft">
          <li>{{ $t('فرقك في كل الدوريات تعود للحاسوب، ولا تعود إليها هذا الموسم.') }}</li>
          <li>{{ $t('كوينزك ورسائلك وصورتك وسجل نشاطك.') }}</li>
          <li>{{ $t('اسمك يُمحى من الألقاب والأهداف المسجلة.') }}</li>
        </ul>
        <UiToggle v-model="understood" tone="live" :label="$t('فهمت، ولن أستطيع استرجاع حسابي')" />
        <div class="flex gap-2">
          <button type="button" class="h-12 flex-1 rounded-lg bg-live/80 px-4 font-bold text-white disabled:opacity-50" :disabled="!understood" @click="deleteStep = 2">{{ $t('متابعة') }}</button>
          <button type="button" class="h-12 rounded-lg bg-surface-raised px-4 font-bold" @click="cancelDelete">{{ $t('تراجع') }}</button>
        </div>
      </div>
      <form v-else class="flex flex-col gap-3" novalidate @submit.prevent="remove">
        <b class="text-sm">{{ $t('الخطوة 2 من 2: التأكيد الأخير') }}</b>
        <TextField v-model="phrase" :label="$t('اكتب كلمة «احذف»')" autocomplete="off" :error="phraseErr" />
        <TextField
          v-model="confirmText"
          :label="user.has_password ? $t('وكلمة المرور') : $t('وبريدك كما هو')"
          :type="user.has_password ? 'password' : 'email'"
          :autocomplete="user.has_password ? 'current-password' : 'off'"
          :error="delErr"
        />
        <div class="flex gap-2">
          <button type="submit" class="h-12 flex-1 rounded-lg bg-live px-4 font-bold text-white disabled:opacity-50" :disabled="phrase.trim() !== $t('احذف') || !confirmText">{{ $t('احذف حسابي نهائياً') }}</button>
          <button type="button" class="h-12 rounded-lg bg-surface-raised px-4 font-bold" @click="cancelDelete">{{ $t('تراجع') }}</button>
        </div>
      </form>
    </section>
  </div>
</template>
