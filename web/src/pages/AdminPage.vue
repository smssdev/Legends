<script setup lang="ts">
// The admin panel (Sprint 37 B2, PLAN 2.17 and 2.22; rebuilt in Sprint 21 E7): the admin only, after the two-step code
// when it is asked. A side list of sections (a scrolling row on the phone), each one page of its own: the overview,
// the activity day by day, the accounts (admins apart, search by number, suspend, delete), the leagues, the
// announcements (each opened whole with its sender and time), the holidays, the conversations with the coaches,
// the alliances, the backups and the commentary templates.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import { intlLocale, t } from '../lib/i18n'
import Icon from '../components/Icon.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
import VerifiedBadge from '../components/VerifiedBadge.vue'

type S = components['schemas']
type AdminUser = S['AdminUser']
const state = ref<S['AdminTwoFactor'] | null>(null)
const secret = ref<{ secret: string; uri: string } | null>(null)
const code = ref('')
const error = ref('')
const notice = ref('')
const busy = ref(false)

const SECTIONS = {
  overview: { label: 'الرئيسية', icon: 'home' },
  activity: { label: 'النشاط', icon: 'league' },
  users: { label: 'المستخدمون', icon: 'team' },
  leagues: { label: 'الدوريات', icon: 'leagues' },
  announcements: { label: 'الإعلانات', icon: 'bell' },
  vacations: { label: 'الإجازات', icon: 'stadium' },
  conversations: { label: 'الرسائل', icon: 'inbox' },
  alliances: { label: 'بطولات التحالفات', icon: 'match' },
  backups: { label: 'النسخ', icon: 'finance' },
  commentary: { label: 'قوالب التعليق', icon: 'news' },
} as const
type Section = keyof typeof SECTIONS
const tab = ref<Section>('overview')

const overview = ref<any>(null)
const activity = ref<any>(null)
const activityDays = ref(14)
const admins = ref<AdminUser[]>([])
const users = ref<AdminUser[]>([])
const userTab = ref<'users' | 'admins'>('users')
const search = ref('')
const leagues = ref<any[]>([])
const announcements = ref<any[]>([])
const openAnnouncement = ref<number | null>(null)
const vacations = ref<any[]>([])
const vacationFilter = ref<'pending' | 'decided'>('pending')
const conversations = ref<any[]>([])
const thread = ref<any | null>(null)
const reply = ref('')
const alliances = ref<any[]>([])
const allianceNote = ref<Record<number, string>>({})
const backups = ref<S['AdminBackups']['backups']>([])
const commentary = ref<{ key: string; count: number; lines: string[] }[]>([])

// [X46] The panel opens at once when the code is not asked.
const open = computed(() => state.value?.passed && (!state.value.required || state.value.enabled))
const size = (b: number) => (b > 1048576 ? (b / 1048576).toFixed(1) + ' MB' : Math.ceil(b / 1024) + ' KB')
const day = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(iso))
const when = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

async function run(fn: () => Promise<void>) {
  busy.value = true
  error.value = ''
  try {
    await ensureCsrf()
    await fn()
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

const load = () => run(async () => {
  state.value = (await api.GET('/admin/2fa')).data!
  if (open.value) await show('overview')
})
const setup = () => run(async () => { secret.value = (await api.POST('/admin/2fa/setup')).data! })
const prove = () => run(async () => {
  const path = state.value?.enabled ? '/admin/2fa/verify' : '/admin/2fa/confirm'
  state.value = (await api.POST(path, { body: { code: code.value } })).data!
  code.value = ''
  secret.value = null
  if (open.value) await show('overview')
})

async function show(s: Section) {
  tab.value = s
  notice.value = ''
  if (s === 'overview') overview.value = (await api.GET('/admin/overview')).data
  if (s === 'activity') { activity.value = (await api.GET('/admin/activity', { params: { query: { days: activityDays.value } } })).data; overview.value ??= (await api.GET('/admin/overview')).data }
  if (s === 'users') await loadUsers()
  if (s === 'leagues') leagues.value = (await api.GET('/admin/leagues')).data!.leagues
  if (s === 'announcements') announcements.value = (await api.GET('/admin/announcements')).data!.announcements
  if (s === 'vacations') vacations.value = (await api.GET('/admin/vacations')).data!.vacations
  if (s === 'conversations') { conversations.value = (await api.GET('/admin/conversations')).data!.conversations; thread.value = null }
  if (s === 'alliances') alliances.value = (await api.GET('/admin/alliances')).data!.tournaments
  if (s === 'backups') backups.value = (await api.GET('/admin/backups')).data!.backups
  if (s === 'commentary') commentary.value = (await api.GET('/admin/commentary')).data!.keys
}
const go = (s: Section) => run(() => show(s))

// The accounts [Sprint 21 E7.3].
async function loadUsers() {
  const data = (await api.GET('/admin/users', { params: { query: search.value.trim() ? { q: search.value.trim() } : {} } })).data!
  admins.value = data.admins
  users.value = data.users
}
const shownUsers = computed(() => (userTab.value === 'admins' ? admins.value : users.value))
const codes = ref<Record<number, string>>({})
const issueCode = (id: number) => run(async () => {
  const { data } = await api.POST('/admin/users/{user}/verification-code', { params: { path: { user: id } } })
  codes.value = { ...codes.value, [id]: data!.code }
})
const makeOfficial = (id: number, name: string) => name && run(async () => {
  await api.POST('/admin/users/{user}/official', { params: { path: { user: id } }, body: { name: name as 'Owner-Sizar' | 'Owner-Sliman' } })
  notice.value = t('صار اسم الحساب {v0}.', { v0: name })
  await loadUsers()
})
const acting = ref<{ id: number; kind: 'suspend' | 'delete'; text: string } | null>(null)
const suspend = (u: AdminUser) => run(async () => {
  await api.POST('/admin/users/{user}/suspend', { params: { path: { user: u.id } }, body: { reason: acting.value!.text.trim() } })
  acting.value = null
  notice.value = t('عُلّق حساب {v0}.', { v0: u.name })
  await loadUsers()
})
const unsuspend = (u: AdminUser) => run(async () => {
  await api.DELETE('/admin/users/{user}/suspend', { params: { path: { user: u.id } } })
  notice.value = t('رُفع التعليق عن {v0}.', { v0: u.name })
  await loadUsers()
})
const remove = (u: AdminUser) => run(async () => {
  await api.DELETE('/admin/users/{user}', { params: { path: { user: u.id } }, body: { confirm: Number(acting.value!.text) } })
  acting.value = null
  notice.value = t('حُذف حساب {v0} نهائياً.', { v0: u.name })
  await loadUsers()
})
const writeTo = (u: AdminUser) => run(async () => {
  tab.value = 'conversations'
  conversations.value = (await api.GET('/admin/conversations')).data!.conversations
  thread.value = (await api.GET('/admin/conversations/{user}', { params: { path: { user: u.id } } })).data
})

// The announcements [Sprint 21 E7.2]: written here, each opened whole with its sender and time.
const annTitle = ref('')
const annBody = ref('')
const announce = () => run(async () => {
  const { data } = await api.POST('/admin/announcements', { body: { title: annTitle.value, body: annBody.value } })
  notice.value = t('أُرسل إلى {v0} حساب، ووصل إشعاراً لكل الأجهزة المشتركة.', { v0: data!.sent })
  annTitle.value = annBody.value = ''
  announcements.value = (await api.GET('/admin/announcements')).data!.announcements
})

// The holidays [Sprint 21 E7.4].
const shownVacations = computed(() => vacations.value.filter((v) => (vacationFilter.value === 'pending' ? v.status === 'pending' : v.status !== 'pending')))
const decide = (id: number, approve: boolean) => run(async () => {
  await api.POST('/admin/vacations/{id}/decide', { params: { path: { id } }, body: { approve } })
  vacations.value = (await api.GET('/admin/vacations')).data!.vacations
})

// The conversations [Sprint 21 E7.7].
const openThread = (id: number) => run(async () => { thread.value = (await api.GET('/admin/conversations/{user}', { params: { path: { user: id } } })).data })
const send = () => run(async () => {
  thread.value = (await api.POST('/admin/conversations/{user}', { params: { path: { user: thread.value.user.id } }, body: { body: reply.value.trim() } })).data
  reply.value = ''
  conversations.value = (await api.GET('/admin/conversations')).data!.conversations
})

const mailTo = ref('')
const mail = ref<{ mailer: string; from: string; key: 'none' | 'api' | 'smtp' | 'other'; problems: string[]; sent: boolean; error: string | null; fix: string | null } | null>(null)
const mailTest = () => run(async () => { mail.value = (await api.POST('/admin/mail-test', { body: { to: mailTo.value } })).data ?? null })
const review = (id: number, approve: boolean) => run(async () => {
  alliances.value = (await api.POST('/admin/alliances/{id}/review', { params: { path: { id } }, body: { approve, note: allianceNote.value[id] || null } })).data!.tournaments
})
const backupNow = () => run(async () => { backups.value = (await api.POST('/admin/backups')).data!.backups })
const ACTIONS: Record<string, string> = { suspend: 'علّق', unsuspend: 'رفع التعليق عن', delete: 'حذف' }
const peak = computed(() => Math.max(1, ...((activity.value?.days ?? []) as { active: number }[]).map((d) => d.active)))
onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="font-display text-3xl font-extrabold">{{ $t('لوحة الإدارة') }}</h1>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!state && !error" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>

    <section v-if="state && !open" :aria-label="$t('التحقق بخطوتين')" class="flex max-w-md flex-col gap-3 rounded-xl bg-surface p-5">
      <h2 class="font-display text-lg font-bold">{{ $t('التحقق بخطوتين') }}</h2>
      <template v-if="!state.enabled && !secret">
        <p class="text-sm text-text-muted">{{ $t('اللوحة تحتاج رمزاً من تطبيق مصادقة على جوالك (Google Authenticator أو Microsoft Authenticator أو غيرهما، مجاناً).') }}</p>
        <button type="button" class="h-12 rounded-md bg-gold font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="setup">{{ $t('فعّل التحقق بخطوتين') }}</button>
      </template>
      <template v-else>
        <div v-if="secret" class="flex flex-col gap-2 text-sm">
          <p class="text-text-muted">{{ $t('في التطبيق: «إضافة حساب» ثم «إدخال مفتاح يدوياً»، واكتب هذا المفتاح:') }}</p>
          <code class="select-all break-all rounded-md bg-surface-sunk p-3 font-numbers text-base" dir="ltr">{{ secret.secret }}</code>
          <a :href="secret.uri" class="text-gold underline">{{ $t('أو افتحه في تطبيق المصادقة على هذا الجهاز') }}</a>
        </div>
        <p v-else class="text-sm text-text-muted">{{ $t('اكتب الرمز الظاهر الآن في تطبيق المصادقة.') }}</p>
        <form class="flex gap-2" @submit.prevent="prove">
          <input v-model="code" inputmode="numeric" autocomplete="one-time-code" maxlength="6" dir="ltr" placeholder="000000" :aria-label="$t('الرمز')"
                 class="h-12 w-36 rounded-md bg-surface-sunk px-3 text-center font-numbers text-xl tracking-widest" />
          <button type="submit" class="h-12 flex-1 rounded-md bg-gold font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy || code.length < 6">{{ $t('تحقق') }}</button>
        </form>
      </template>
    </section>

    <div v-if="open" class="grid gap-4 lg:grid-cols-[13rem_minmax(0,1fr)]">
      <!-- The sections: a side list on the computer, a scrolling row on the phone. -->
      <nav class="flex gap-1 overflow-x-auto rounded-xl bg-surface p-1 lg:sticky lg:top-24 lg:flex-col lg:self-start lg:overflow-visible lg:p-2" :aria-label="$t('أقسام اللوحة')">
        <button v-for="(s, key) in SECTIONS" :key="key" type="button" :data-section="key" class="flex h-touch shrink-0 items-center gap-2 rounded-lg px-3 text-sm font-bold"
          :class="tab === key ? 'bg-gold text-on-gold' : 'text-text-soft hover:bg-surface-raised'" :aria-current="tab === key ? 'page' : undefined" @click="go(key)">
          <Icon :name="s.icon" :size="18" />{{ $t(s.label) }}
        </button>
      </nav>

      <div class="flex min-w-0 flex-col gap-4">
        <!-- The overview: deploy safety, the counts, and the email test. -->
        <template v-if="tab === 'overview' && overview">
          <div class="flex items-center gap-3 rounded-xl p-4" :class="overview.deploy.busy ? 'bg-live/15' : 'bg-success/15'" role="status">
            <span class="text-2xl" aria-hidden="true">{{ overview.deploy.busy ? '⛔' : '✅' }}</span>
            <div class="text-sm">
              <b class="block">{{ overview.deploy.busy ? $t('لا تنشر الآن: {v0} مباراة مباشرة أو تبدأ خلال نصف ساعة', { v0: overview.deploy.busy }) : $t('آمن للنشر الآن') }}</b>
              <span class="text-text-muted">{{ overview.deploy.next_kickoff ? $t('أقرب مباراة: {v0}', { v0: when(overview.deploy.next_kickoff) }) : $t('لا مباريات مجدولة') }}</span>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-2 sm:grid-cols-4">
            <div v-for="[label, n] in [['المستخدمون', overview.users], ['الدوريات الجارية', overview.leagues.running], ['مباريات حية', overview.live_matches], ['نشطون اليوم', overview.active_today]]" :key="label" class="rounded-xl bg-surface p-4">
              <span class="block text-sm text-text-muted">{{ $t(label) }}</span><b class="font-numbers text-3xl" dir="ltr">{{ n }}</b>
            </div>
          </div>
          <section :aria-label="$t('اختبار البريد')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <h2 class="font-display text-lg font-bold">{{ $t('اختبار البريد') }}</h2>
            <div class="flex flex-wrap gap-2">
              <input v-model="mailTo" type="email" dir="ltr" placeholder="you@gmail.com" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3" />
              <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-50" :disabled="busy || !mailTo" @click="mailTest">{{ $t('أرسل رسالة تجربة') }}</button>
            </div>
            <div v-if="mail" class="flex flex-col gap-1 text-sm">
              <p>{{ $t('الطريقة:') }} <b dir="ltr">{{ mail.mailer }}</b> {{ $t('· المرسل:') }} <b dir="ltr">{{ mail.from || '-' }}</b></p>
              <p v-if="mail.sent" class="rounded-lg bg-success/15 px-3 py-2 text-success">{{ $t('أُرسلت. افحص البريد الوارد والرسائل غير المرغوبة.') }}</p>
              <p v-if="mail.error" class="rounded-lg bg-live/15 px-3 py-2 font-mono text-xs" dir="ltr">{{ mail.error }}</p>
              <p v-if="mail.fix" class="rounded-lg bg-warning/15 px-3 py-2"><b>{{ $t('الحل:') }}</b> {{ mail.fix }}</p>
              <p v-for="p in mail.problems" :key="p" class="rounded-lg bg-warning/10 px-3 py-2">{{ p }}</p>
            </div>
          </section>
        </template>

        <!-- [Sprint 21 E7.5] The activity: day by day, the weeks' return, and what the admins did. -->
        <template v-if="tab === 'activity' && activity">
          <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" :aria-label="$t('النشاط اليومي')">
            <div class="flex flex-wrap items-center gap-2">
              <h2 class="flex-1 font-display text-lg font-bold">{{ $t('النشاط اليومي') }}</h2>
              <button v-for="n in [7, 14, 30, 90]" :key="n" type="button" class="h-10 rounded-md px-3 text-sm font-bold" :class="activityDays === n ? 'bg-gold text-on-gold' : 'bg-surface-sunk'"
                @click="activityDays = n; go('activity')">{{ $t('{v0} يوماً', { v0: n }) }}</button>
            </div>
            <div class="overflow-x-auto">
              <table class="w-full min-w-[560px] text-sm">
                <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('اليوم') }}</th><th class="text-start">{{ $t('نشطون') }}</th><th>{{ $t('دخول') }}</th><th>{{ $t('مباريات حية') }}</th><th>{{ $t('أوامر') }}</th><th>{{ $t('حسابات جديدة') }}</th></tr></thead>
                <tbody class="font-numbers">
                  <tr v-for="d in activity.days" :key="d.day" class="border-t border-text/5 text-center">
                    <td class="py-2 text-start" dir="ltr">{{ d.day }}</td>
                    <td class="text-start"><span class="flex items-center gap-2"><span class="h-2 rounded-full bg-brand" :style="{ width: `${Math.max(2, (100 * d.active) / peak)}%`, maxWidth: '8rem' }" />{{ d.active }}</span></td>
                    <td>{{ d.logins }}</td><td>{{ d.watched }}</td><td>{{ d.orders }}</td><td :class="d.joined ? 'text-success' : ''">{{ d.joined }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
          <section v-if="overview?.weeks" class="overflow-x-auto rounded-xl bg-surface p-4" :aria-label="$t('العودة أسبوعاً بعد أسبوع')">
            <h2 class="mb-2 font-display text-lg font-bold">{{ $t('العودة أسبوعاً بعد أسبوع') }}</h2>
            <table class="w-full text-sm">
              <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('الأسبوع حتى') }}</th><th>{{ $t('نشطون') }}</th><th>{{ $t('عادوا من الأسبوع قبله') }}</th><th>{{ $t('تابعوا مباراة حية') }}</th></tr></thead>
              <tbody><tr v-for="w in overview.weeks" :key="w.week" class="border-t border-text/5 text-center font-numbers"><td class="py-2 text-start">{{ w.week }}</td><td>{{ w.active }}</td><td>{{ w.returning }}</td><td>{{ w.live }}</td></tr></tbody>
            </table>
          </section>
          <section class="flex flex-col gap-1 rounded-xl bg-surface p-4" :aria-label="$t('سجل الإدارة')">
            <h2 class="mb-1 font-display text-lg font-bold">{{ $t('سجل الإدارة') }}</h2>
            <p v-if="!activity.log.length" class="text-sm text-text-muted">{{ $t('لا شيء بعد.') }}</p>
            <p v-for="(l, i) in activity.log" :key="i" class="flex flex-wrap gap-2 border-t border-text/5 py-2 text-sm first:border-0">
              <span class="font-numbers text-text-muted" dir="ltr">{{ when(l.at) }}</span>
              <b>{{ l.admin ?? '-' }}</b> {{ $t(ACTIONS[l.action] ?? l.action) }} <b>{{ l.target ?? '-' }}</b><span v-if="l.details" class="text-text-muted">· {{ l.details }}</span>
            </p>
          </section>
        </template>

        <!-- [Sprint 21 E7.3] The accounts: the admins apart, search by number or name, and the actions. -->
        <template v-if="tab === 'users'">
          <form class="flex flex-wrap gap-2" role="search" @submit.prevent="run(loadUsers)">
            <input v-model="search" :placeholder="$t('رقم الحساب أو الاسم أو البريد')" class="h-touch min-w-0 flex-1 rounded-lg bg-surface px-3" :aria-label="$t('بحث')" />
            <button type="submit" class="h-touch rounded-lg bg-gold px-5 font-bold text-on-gold">{{ $t('بحث') }}</button>
          </form>
          <div class="flex gap-1 self-start rounded-xl bg-surface p-1" role="tablist">
            <button v-for="[k, l, n] in ([['users', 'المدربون', users.length], ['admins', 'المشرفون', admins.length]] as const)" :key="k" type="button" role="tab" :aria-selected="userTab === k"
              class="h-10 rounded-lg px-4 text-sm font-bold" :class="userTab === k ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="userTab = k">{{ $t(l) }} <span class="font-numbers">{{ n }}</span></button>
          </div>
          <p v-if="!shownUsers.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا نتائج.') }}</p>
          <article v-for="u in shownUsers" :key="u.id" class="flex flex-col gap-2 rounded-xl bg-surface p-3" :class="u.suspended ? 'border border-live/40' : ''">
            <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
              <span class="rounded-md bg-surface-sunk px-2 py-1 font-numbers text-sm tracking-wider" dir="ltr">#{{ u.account_no }}</span>
              <b class="font-display">{{ u.name }}</b><OfficialBadge v-if="u.official" /><VerifiedBadge v-else-if="u.verified" />
              <span class="text-xs text-text-muted" dir="ltr">@{{ u.username }}</span>
              <span v-if="u.suspended" class="rounded-pill bg-live/20 px-2 text-xs text-[#FF8A8A]">{{ $t('معلّق') }}</span>
              <span class="ms-auto text-xs text-text-muted">{{ $t('انضم {v0} · آخر يوم {v1} · {v2} مباراة حية', { v0: day(u.joined), v1: u.last_day ?? '-', v2: u.matches_watched }) }}</span>
            </div>
            <p v-if="u.email" class="text-xs text-text-muted" dir="ltr">{{ u.email }}</p>
            <p v-if="u.suspended?.reason" class="text-xs text-[#FF8A8A]">{{ $t('السبب: {v0}', { v0: u.suspended.reason }) }}</p>
            <div class="flex flex-wrap items-center gap-2">
              <template v-if="!u.verified">
                <b v-if="codes[u.id]" dir="ltr" class="font-numbers text-lg text-gold">{{ codes[u.id] }}</b>
                <button v-else type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" @click="issueCode(u.id)">{{ $t('كود توثيق') }}</button>
              </template>
              <button type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" @click="writeTo(u)">{{ $t('راسله') }}</button>
              <select v-if="u.role === 'admin'" class="h-10 rounded-md bg-surface-sunk px-2 text-xs" :aria-label="$t('أعطه اسماً رسمياً')" @change="makeOfficial(u.id, ($event.target as HTMLSelectElement).value)">
                <option value="">{{ $t('اسم رسمي') }}</option><option>Owner-Sizar</option><option>Owner-Sliman</option>
              </select>
              <template v-if="u.role !== 'admin'">
                <button v-if="u.suspended" type="button" class="h-10 rounded-md bg-success/20 px-3 text-xs font-bold text-success" @click="unsuspend(u)">{{ $t('ارفع التعليق') }}</button>
                <button v-else type="button" class="h-10 rounded-md bg-warning/15 px-3 text-xs font-bold text-warning" @click="acting = { id: u.id, kind: 'suspend', text: '' }">{{ $t('علّق الحساب') }}</button>
                <button type="button" class="h-10 rounded-md bg-live/15 px-3 text-xs font-bold text-[#FF8A8A]" @click="acting = { id: u.id, kind: 'delete', text: '' }">{{ $t('احذف الحساب') }}</button>
              </template>
            </div>
            <form v-if="acting?.id === u.id" class="flex flex-wrap items-end gap-2 rounded-lg bg-surface-sunk p-3" @submit.prevent="acting.kind === 'suspend' ? suspend(u) : remove(u)">
              <label class="flex min-w-60 flex-1 flex-col gap-1 text-xs font-bold">
                {{ acting.kind === 'suspend' ? $t('سبب التعليق (يراه المدرب)') : $t('للتأكيد اكتب رقم الحساب {v0}', { v0: u.account_no }) }}
                <input v-model="acting.text" :inputmode="acting.kind === 'delete' ? 'numeric' : 'text'" class="h-touch rounded-md bg-surface px-3 text-sm" :dir="acting.kind === 'delete' ? 'ltr' : undefined" />
              </label>
              <button type="submit" class="h-touch rounded-md px-4 text-sm font-bold disabled:opacity-40" :class="acting.kind === 'delete' ? 'bg-live text-white' : 'bg-warning text-on-gold'"
                :disabled="busy || (acting.kind === 'suspend' ? acting.text.trim().length < 3 : acting.text !== String(u.account_no))">{{ acting.kind === 'delete' ? $t('احذف نهائياً') : $t('علّق') }}</button>
              <button type="button" class="h-touch rounded-md px-3 text-sm text-text-muted" @click="acting = null">{{ $t('تراجع') }}</button>
            </form>
          </article>
        </template>

        <!-- [Sprint 21 E7.6] The leagues, each creator with his account number. -->
        <section v-if="tab === 'leagues'" :aria-label="$t('الدوريات')" class="overflow-x-auto rounded-xl bg-surface p-4">
          <table class="w-full min-w-[560px] text-sm">
            <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('الدوري') }}</th><th>{{ $t('الحالة') }}</th><th>{{ $t('الموسم') }}</th><th>{{ $t('مدربون') }}</th><th class="text-start">{{ $t('المنشئ') }}</th></tr></thead>
            <tbody>
              <tr v-for="l in leagues" :key="l.id" class="border-t border-text/5 text-center">
                <td class="py-2 text-start">{{ l.name }}<span v-if="l.dev" class="ms-1 text-xs text-text-muted">{{ $t('تطوير') }}</span></td>
                <td>{{ $t(l.status) }}</td><td class="font-numbers">{{ l.season }}</td><td class="font-numbers">{{ l.coaches }} / {{ l.teams }}</td>
                <td class="text-start">{{ l.owner ?? '-' }} <span v-if="l.owner_no" class="rounded bg-surface-sunk px-1.5 font-numbers text-xs" dir="ltr">#{{ l.owner_no }}</span></td>
              </tr>
            </tbody>
          </table>
        </section>

        <!-- [Sprint 21 E7.2] The announcements: write one, and open any to read it whole. -->
        <template v-if="tab === 'announcements'">
          <section :aria-label="$t('إعلان جديد')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <h2 class="font-display text-lg font-bold">{{ $t('إعلان جديد لكل اللاعبين') }}</h2>
            <p class="text-xs text-text-muted">{{ $t('يُرسل من حسابك الرسمي (Owner-Sizar أو Owner-Sliman) بشارته، ويصل رسالة وإشعاراً لكل الحسابات.') }}</p>
            <input v-model="annTitle" maxlength="120" :placeholder="$t('العنوان')" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" />
            <textarea v-model="annBody" maxlength="2000" rows="4" :placeholder="$t('النص')" class="rounded-md border border-text/10 bg-surface-sunk p-3" />
            <button type="button" class="h-touch self-start rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-50" :disabled="busy || !annTitle || !annBody" @click="announce">{{ $t('أرسل للجميع') }}</button>
          </section>
          <p v-if="!announcements.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا إعلانات بعد.') }}</p>
          <article v-for="a in announcements" :key="a.id" class="rounded-xl bg-surface">
            <button type="button" class="flex w-full flex-wrap items-center gap-2 p-4 text-start" :aria-expanded="openAnnouncement === a.id" @click="openAnnouncement = openAnnouncement === a.id ? null : a.id">
              <b class="min-w-0 flex-1 font-display">{{ a.title }}</b>
              <span class="text-xs text-text-muted">{{ a.sender?.name }} <OfficialBadge v-if="a.sender?.official" /> · <span dir="ltr">{{ when(a.at) }}</span></span>
              <span class="text-gold" aria-hidden="true">{{ openAnnouncement === a.id ? '▲' : '▼' }}</span>
            </button>
            <div v-if="openAnnouncement === a.id" class="flex flex-col gap-2 border-t border-text/5 px-4 pb-4 pt-3 text-sm">
              <p class="whitespace-pre-line">{{ a.body }}</p>
              <p class="text-xs text-text-muted">{{ $t('أرسله {v0} (@{v1}) في {v2} إلى {v3} حساب.', { v0: a.sender?.name ?? '-', v1: a.sender?.username ?? '-', v2: when(a.at), v3: a.sent }) }}</p>
            </div>
          </article>
        </template>

        <!-- [Sprint 21 E7.4] The holidays: the waiting ones, or those decided, each with its dates. -->
        <template v-if="tab === 'vacations'">
          <div class="flex gap-1 self-start rounded-xl bg-surface p-1" role="tablist">
            <button v-for="[k, l] in ([['pending', 'تنتظر القرار'], ['decided', 'قُرر فيها']] as const)" :key="k" type="button" role="tab" :aria-selected="vacationFilter === k"
              class="h-10 rounded-lg px-4 text-sm font-bold" :class="vacationFilter === k ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="vacationFilter = k">{{ $t(l) }}</button>
          </div>
          <p v-if="!shownVacations.length" class="rounded-xl bg-surface p-4 text-sm text-text-muted">{{ $t('لا طلبات هنا.') }}</p>
          <article v-for="v in shownVacations" :key="v.id" class="grid gap-3 rounded-xl bg-surface p-4 sm:grid-cols-[minmax(0,1fr)_auto]">
            <div class="flex flex-col gap-1">
              <div class="flex flex-wrap items-center gap-2"><b class="font-display">{{ v.user.name }}</b><span class="text-xs text-text-muted" dir="ltr">@{{ v.user.username }}</span>
                <span v-if="v.user.account_no" class="rounded bg-surface-sunk px-1.5 font-numbers text-xs" dir="ltr">#{{ v.user.account_no }}</span></div>
              <dl class="grid grid-cols-2 gap-x-4 gap-y-1 text-sm sm:grid-cols-4">
                <div><dt class="text-xs text-text-muted">{{ $t('المدة') }}</dt><dd class="font-bold">{{ $t('{v0} يوماً', { v0: v.days }) }}</dd></div>
                <div><dt class="text-xs text-text-muted">{{ $t('طُلبت') }}</dt><dd>{{ when(v.asked_at) }}</dd></div>
                <div v-if="v.starts_at"><dt class="text-xs text-text-muted">{{ $t('من') }}</dt><dd>{{ when(v.starts_at) }}</dd></div>
                <div v-if="v.ends_at"><dt class="text-xs text-text-muted">{{ $t('إلى') }}</dt><dd>{{ when(v.ends_at) }}</dd></div>
              </dl>
              <p class="rounded-lg bg-surface-sunk px-3 py-2 text-sm"><span class="text-xs text-text-muted">{{ $t('السبب') }}:</span> {{ v.reason }}</p>
              <p v-if="v.decided_by" class="text-xs text-text-muted">{{ $t('قرر {v0} في {v1}', { v0: v.decided_by, v1: v.decided_at ? when(v.decided_at) : '-' }) }}</p>
            </div>
            <div class="flex items-start gap-2">
              <template v-if="v.status === 'pending'">
                <button type="button" class="h-touch rounded-md bg-success/20 px-4 font-bold text-success" @click="decide(v.id, true)">{{ $t('موافقة') }}</button>
                <button type="button" class="h-touch rounded-md bg-live/15 px-4 font-bold text-[#FF8A8A]" @click="decide(v.id, false)">{{ $t('رفض') }}</button>
              </template>
              <span v-else class="rounded-pill px-3 py-1 text-sm font-bold" :class="v.status === 'approved' ? 'bg-success/15 text-success' : 'bg-surface-sunk text-text-muted'">{{ v.status === 'approved' ? $t('وُوفق عليها') : $t('رُفضت') }}</span>
            </div>
          </article>
        </template>

        <!-- [Sprint 21 E7.7] The conversations with the coaches, from the developers' official accounts. -->
        <div v-if="tab === 'conversations'" class="grid gap-3 xl:grid-cols-[18rem_minmax(0,1fr)]">
          <section class="flex flex-col gap-1 rounded-xl bg-surface p-2" :aria-label="$t('المحادثات')">
            <p v-if="!conversations.length" class="p-3 text-sm text-text-muted">{{ $t('لا محادثات بعد. راسل مدرباً من قسم المستخدمين.') }}</p>
            <button v-for="c in conversations" :key="c.user.id" type="button" class="flex flex-col gap-0.5 rounded-lg p-3 text-start hover:bg-surface-raised" :class="thread?.user.id === c.user.id ? 'bg-surface-raised' : ''" @click="openThread(c.user.id)">
              <span class="flex items-center gap-2"><b class="truncate">{{ c.user.name }}</b><span class="font-numbers text-xs text-text-muted" dir="ltr">#{{ c.user.account_no }}</span>
                <span v-if="c.unread" class="ms-auto min-w-5 rounded-pill bg-live px-1.5 text-center font-numbers text-xs text-white">{{ c.unread }}</span></span>
              <span class="truncate text-xs text-text-muted">{{ c.from_team ? $t('أنتم: ') : '' }}{{ c.last }}</span>
            </button>
          </section>
          <section v-if="thread" class="flex flex-col gap-2 rounded-xl bg-surface p-4" :aria-label="$t('المحادثة')">
            <h2 class="font-display text-lg font-bold">{{ thread.user.name }} <span class="font-numbers text-sm text-text-muted" dir="ltr">#{{ thread.user.account_no }} @{{ thread.user.username }}</span></h2>
            <div class="flex max-h-[28rem] flex-col gap-2 overflow-y-auto">
              <p v-for="m in thread.messages" :key="m.id" class="max-w-[85%] whitespace-pre-line rounded-xl px-3 py-2 text-sm" :class="m.from_team ? 'self-end bg-gold/15' : 'self-start bg-surface-sunk'">
                <span v-if="m.sender" class="mb-0.5 block text-xs font-bold text-gold">{{ m.sender.username }}</span>{{ m.body }}
                <span class="mt-1 block text-[0.7rem] text-text-muted" dir="ltr">{{ when(m.at) }}</span>
              </p>
            </div>
            <form class="flex gap-2" @submit.prevent="send">
              <textarea v-model="reply" rows="2" maxlength="2000" :placeholder="$t('اكتب رسالتك من حسابك الرسمي')" class="min-w-0 flex-1 rounded-md bg-surface-sunk p-2" />
              <button type="submit" class="h-touch self-end rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy || !reply.trim()">{{ $t('أرسل') }}</button>
            </form>
          </section>
        </div>

        <template v-if="tab === 'alliances'">
          <p v-if="!alliances.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا طلبات.') }}</p>
          <article v-for="a in alliances" :key="a.id" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <div class="flex flex-wrap items-center justify-between gap-2"><b>{{ a.name }}</b><span class="text-sm text-text-muted">{{ a.league }} · {{ $t(a.status) }}</span></div>
            <p class="text-sm text-text-muted">{{ $t('{v0} ضد {v1} · القائدان', { v0: a.size, v1: a.size }) }} <span dir="ltr">{{ a.captains.join(' / ') }}</span> {{ $t('· الدور الأول {v0}', { v0: day(a.first_round_at) }) }}</p>
            <template v-if="a.status === 'pending'">
              <input v-model="allianceNote[a.id]" maxlength="200" :placeholder="$t('ملاحظة (اختيارية)')" class="h-touch rounded-md bg-surface-sunk px-3" />
              <div class="flex gap-2">
                <button type="button" class="h-touch flex-1 rounded-md bg-gold font-bold text-on-gold disabled:opacity-50" :disabled="busy" @click="review(a.id, true)">{{ $t('اعتمد') }}</button>
                <button type="button" class="h-touch flex-1 rounded-md bg-surface-sunk font-bold disabled:opacity-50" :disabled="busy" @click="review(a.id, false)">{{ $t('ارفض') }}</button>
              </div>
            </template>
            <p v-else-if="a.review_note" class="text-sm">{{ a.review_note }}</p>
          </article>
        </template>

        <section v-if="tab === 'backups'" :aria-label="$t('النسخ')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
          <div class="flex items-center justify-between gap-2">
            <h2 class="font-display text-lg font-bold">{{ $t('النسخ على هذا الجهاز') }}</h2>
            <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="backupNow">{{ $t('نسخة الآن') }}</button>
          </div>
          <p v-if="!backups.length" class="text-sm text-text-muted">{{ $t('لا نسخ بعد.') }}</p>
          <div v-for="b in backups" :key="b.name" class="flex min-h-touch items-center justify-between border-b border-text/5 text-sm last:border-0">
            <span class="font-numbers" dir="ltr">{{ b.name }}</span>
            <span class="flex items-center gap-3"><span class="font-numbers text-text-muted" dir="ltr">{{ size(b.bytes) }}</span>
              <a :href="`/api/v1/admin/backups/${b.name}/download`" class="flex h-touch items-center rounded-md bg-brand px-3 font-bold" download>{{ $t('تنزيل') }}</a></span>
          </div>
        </section>

        <template v-if="tab === 'commentary'">
          <details v-for="k in commentary" :key="k.key" class="rounded-xl bg-surface p-4">
            <summary class="flex min-h-touch cursor-pointer items-center justify-between"><span dir="ltr">{{ k.key }}</span><span class="font-numbers text-text-muted">{{ k.count }}</span></summary>
            <ul class="mt-2 flex flex-col gap-1 text-sm"><li v-for="(l, i) in k.lines" :key="i">{{ l }}</li></ul>
          </details>
        </template>
      </div>
    </div>
  </div>
</template>
