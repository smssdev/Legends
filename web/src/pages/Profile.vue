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
import { AR_VOICES, arVoiceName, type ArVoice } from '../match/voice'
import { MATCH_VIEWS, useViewing, type MatchView } from '../match/viewing'

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
    viewMsg.value = 'حُفظ.'
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
    nameMsg.value = 'حُفظ.'
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

// The account's holiday [X4]: every league at once, so no team is lost while away.
const holidayDays = ref(7)
const holidayMsg = ref('')
const canHoliday = computed(() => !user.value.vacation.next_from || new Date(user.value.vacation.next_from) <= new Date())
const dateText = (iso: string | null) => (iso ? new Date(iso).toLocaleString('ar-EG', { dateStyle: 'medium', timeStyle: 'short' }) : '')
async function holiday(start: boolean) {
  holidayMsg.value = ''
  try {
    await ensureCsrf()
    const { data } = start ? await api.POST('/auth/vacation', { body: { days: holidayDays.value } }) : await api.DELETE('/auth/vacation')
    auth.set(data!.user!)
  } catch (err) {
    holidayMsg.value = asApiError(err).message
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
    <h1 class="font-display text-3xl font-extrabold">حسابي</h1>
    <p v-if="welcome" class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">{{ welcome }}</p>

    <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-account">
      <h2 id="h-account" class="font-display text-xl font-extrabold">الحساب</h2>
      <div class="flex items-center gap-4">
        <img v-if="user.avatar_url" :src="user.avatar_url" alt="صورتك" class="size-20 rounded-full object-cover" />
        <span v-else class="flex size-20 items-center justify-center rounded-full bg-gold font-display text-3xl font-extrabold text-on-gold">{{ user.name.trim().charAt(0) }}</span>
        <div class="flex flex-col gap-2">
          <span class="font-bold" dir="ltr">@{{ user.username }}</span> <OfficialBadge v-if="user.official" />
          <div class="flex flex-wrap gap-2">
            <label class="flex h-touch cursor-pointer items-center rounded-md bg-surface-raised px-4 font-bold" :class="picBusy ? 'opacity-60' : ''">
              {{ picBusy ? 'جارٍ الرفع…' : user.avatar_url ? 'غيّر الصورة' : 'أضف صورة' }}
              <input ref="picture" type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="sr-only" :disabled="picBusy" @change="upload" />
            </label>
            <button v-if="user.avatar_url" type="button" class="h-touch rounded-md px-3 text-sm text-text-muted" @click="removePicture">احذف الصورة</button>
          </div>
          <p v-if="picErr" class="text-sm text-[#FF8A8A]" role="alert">{{ picErr }}</p>
        </div>
      </div>
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
        <div class="flex-1"><UsernameField v-model="username" :error="userErr" :current="user.username" /></div>
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

    <section class="flex flex-col gap-4 rounded-xl bg-surface p-4" aria-labelledby="h-viewing">
      <h2 id="h-viewing" class="font-display text-xl font-extrabold">مشاهدة المباريات</h2>
      <fieldset class="flex flex-col gap-2">
        <legend class="mb-1 text-sm font-bold">المحاكي</legend>
        <label v-for="v in MATCH_VIEWS" :key="v.id" class="flex min-h-touch cursor-pointer items-center gap-3 rounded-lg border px-3 py-2" :class="viewing.chosenView.value === v.id ? 'border-gold bg-gold/10' : 'border-text/10'">
          <input type="radio" name="match-view" class="size-5 accent-[var(--color-gold)]" :value="v.id" :checked="viewing.chosenView.value === v.id" @change="saveViewing({ match_view: v.id })" />
          <span class="flex flex-col">
            <span class="font-bold">{{ v.name }} <span v-if="v.id === 'unity' && !viewing.unityReady.value" class="rounded-pill bg-warning/15 px-2 py-0.5 text-xs text-warning">قريباً</span></span>
            <span class="text-xs text-text-muted">{{ v.hint }}</span>
          </span>
        </label>
        <p v-if="viewing.chosenView.value === 'unity' && !viewing.unityReady.value" class="text-xs text-text-muted">حتى يجهز المطوّر تُعرض مبارياتك بالكرتوني، وتنتقل إليه تلقائياً حين يجهز.</p>
      </fieldset>
      <label class="flex flex-col gap-1.5">
        <span class="text-sm font-bold">المعلق العربي</span>
        <select class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-3" :value="viewing.commentator.value" @change="saveViewing({ commentator: ($event.target as HTMLSelectElement).value as ArVoice })">
          <option v-for="v in AR_VOICES" :key="v" :value="v">{{ arVoiceName(v) }}</option>
        </select>
        <span class="text-xs text-text-muted">يُسمع في كل مبارياتك، ويُبدَّل أثناء المباراة أيضاً.</span>
      </label>
      <p v-if="viewMsg" class="text-sm" :class="viewErr ? 'text-[#FF8A8A]' : 'text-success'" role="status">{{ viewMsg }}</p>
    </section>

    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-holiday">
      <h2 id="h-holiday" class="font-display text-xl font-extrabold">إجازة الحساب</h2>
      <p class="text-sm text-text-muted">إجازة لحسابك كله: لا يُحسب غيابك في أي دوري، فلا يعود فريقك للحاسوب ولا تخسر شيئاً، والمساعد يدير فرقك. حتى {{ user.vacation.max_days }} يوماً، والتالية بعد 14 يوماً من نهايتها. ولإجازة في دوري واحد فقط اطلبها من صفحة الدوري بسبب يوافق عليه مسؤوله.</p>
      <template v-if="user.vacation.on">
        <p class="rounded-lg bg-success/15 px-4 py-3 text-sm" role="status">أنت في إجازة حتى {{ dateText(user.vacation.until) }}.</p>
        <button type="button" class="h-touch self-start rounded-md bg-surface-raised px-4 font-bold" @click="holiday(false)">عدت، أنهِ الإجازة</button>
      </template>
      <form v-else-if="canHoliday" class="flex flex-wrap items-end gap-2" @submit.prevent="holiday(true)">
        <label class="flex flex-col gap-1.5 text-sm font-bold">عدد الأيام
          <select v-model.number="holidayDays" class="h-12 rounded-lg border border-text/10 bg-surface-sunk px-3">
            <option v-for="d in user.vacation.max_days" :key="d" :value="d">{{ d }}</option>
          </select>
        </label>
        <button type="submit" class="h-12 rounded-lg bg-gold px-5 font-bold text-on-gold">ابدأ الإجازة</button>
      </form>
      <p v-else class="text-sm text-text-muted">إجازتك التالية من {{ dateText(user.vacation.next_from) }}.</p>
      <p v-if="holidayMsg" class="text-sm text-[#FF8A8A]" role="alert">{{ holidayMsg }}</p>
    </section>

    <NotificationsCard />

    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-support">
      <h2 id="h-support" class="font-display text-xl font-extrabold">الدعم الفني</h2>
      <SupportLinks />
      <p class="text-xs text-text-muted">إن لم تظهر الأزرار فالدعم لم يُفعَّل على الخادم بعد.</p>
    </section>

    <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-signout">
      <h2 id="h-signout" class="font-display text-xl font-extrabold">تسجيل الخروج</h2>
      <p class="text-sm text-text-muted">تخرج من هذا الجهاز فقط، وحسابك وفرقك باقية كما هي.</p>
      <button type="button" class="h-touch self-start rounded-md border border-text/15 px-4 font-bold" @click="logout">تسجيل الخروج</button>
    </section>

    <!-- Deleting is apart from signing out, and asks twice [X12]: what is lost, then the word and the password. -->
    <section class="flex flex-col gap-3 rounded-xl border border-live/40 p-4" aria-labelledby="h-delete">
      <h2 id="h-delete" class="font-display text-xl font-extrabold text-[#FF8A8A]">حذف الحساب نهائياً</h2>
      <p class="text-sm text-text-muted">لا علاقة له بتسجيل الخروج: الحذف لا يمكن التراجع عنه.</p>
      <button v-if="deleteStep === 0" type="button" class="h-touch self-start rounded-md bg-live/15 px-4 font-bold text-[#FF8A8A]" @click="deleteStep = 1">أريد حذف حسابي</button>
      <div v-else-if="deleteStep === 1" class="flex flex-col gap-3 rounded-lg bg-live/10 p-3 text-sm" role="alertdialog" aria-labelledby="h-delete-1">
        <b id="h-delete-1">الخطوة 1 من 2: هذا ما سيضيع للأبد</b>
        <ul class="list-disc ps-5 text-text-soft">
          <li>فرقك في كل الدوريات تعود للحاسوب، ولا تعود إليها هذا الموسم.</li>
          <li>كوينزك ورسائلك وصورتك وسجل نشاطك.</li>
          <li>اسمك يُمحى من الألقاب والأهداف المسجلة.</li>
        </ul>
        <UiToggle v-model="understood" tone="live" label="فهمت، ولن أستطيع استرجاع حسابي" />
        <div class="flex gap-2">
          <button type="button" class="h-12 flex-1 rounded-lg bg-live/80 px-4 font-bold text-white disabled:opacity-50" :disabled="!understood" @click="deleteStep = 2">متابعة</button>
          <button type="button" class="h-12 rounded-lg bg-surface-raised px-4 font-bold" @click="cancelDelete">تراجع</button>
        </div>
      </div>
      <form v-else class="flex flex-col gap-3" novalidate @submit.prevent="remove">
        <b class="text-sm">الخطوة 2 من 2: التأكيد الأخير</b>
        <TextField v-model="phrase" label="اكتب كلمة «احذف»" autocomplete="off" :error="phraseErr" />
        <TextField
          v-model="confirmText"
          :label="user.has_password ? 'وكلمة المرور' : 'وبريدك كما هو'"
          :type="user.has_password ? 'password' : 'email'"
          :autocomplete="user.has_password ? 'current-password' : 'off'"
          :error="delErr"
        />
        <div class="flex gap-2">
          <button type="submit" class="h-12 flex-1 rounded-lg bg-live px-4 font-bold text-white disabled:opacity-50" :disabled="phrase.trim() !== 'احذف' || !confirmText">احذف حسابي نهائياً</button>
          <button type="button" class="h-12 rounded-lg bg-surface-raised px-4 font-bold" @click="cancelDelete">تراجع</button>
        </div>
      </form>
    </section>
  </div>
</template>
