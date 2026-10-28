<script setup lang="ts">
// The admin panel (Sprint 37 B2, PLAN 2.17 and 2.22): the admin only, after the two-step code from an authenticator
// app. The counts and the return indicator, the accounts, the leagues, the backups, and the commentary templates.
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import { intlLocale } from '../lib/i18n'

type S = components['schemas']
const state = ref<S['AdminTwoFactor'] | null>(null)
const secret = ref<{ secret: string; uri: string } | null>(null)
const code = ref('')
const error = ref('')
const busy = ref(false)
const tab = ref<'overview' | 'users' | 'vacations' | 'leagues' | 'alliances' | 'backups' | 'commentary'>('overview')
// The alliance tournaments waiting for the developers [X27].
const alliances = ref<components['responses']['AdminAlliances']['content']['application/json']['tournaments']>([])
const allianceNote = ref<Record<number, string>>({})
const overview = ref<any>(null)
const users = ref<any[]>([])
const leagues = ref<any[]>([])
const backups = ref<S['AdminBackups']['backups']>([])
const commentary = ref<{ key: string; count: number; lines: string[] }[]>([])
const TABS = { overview: 'النشاط', users: 'المستخدمون', vacations: 'الإجازات', leagues: 'الدوريات', alliances: 'بطولات التحالفات', backups: 'النسخ', commentary: 'قوالب التعليق' } as const

// [X46] The panel opens at once when the code is not asked.
const open = computed(() => state.value?.passed && (!state.value.required || state.value.enabled))
const size = (b: number) => (b > 1048576 ? (b / 1048576).toFixed(1) + ' MB' : Math.ceil(b / 1024) + ' KB')
const day = (iso: string) => new Intl.DateTimeFormat('ar-EG-u-nu-latn', { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(iso))

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

const mailTo = ref('')
const mail = ref<{ mailer: string; from: string; key: 'none' | 'api' | 'smtp' | 'other'; problems: string[]; sent: boolean; error: string | null; fix: string | null } | null>(null)
const mailTest = () => run(async () => {
  mail.value = (await api.POST('/admin/mail-test', { body: { to: mailTo.value } })).data ?? null
})
const annTitle = ref('')
const annBody = ref('')
const annMsg = ref('')
const announce = () => run(async () => {
  const { data } = await api.POST('/admin/announcements', { body: { title: annTitle.value, body: annBody.value } })
  annMsg.value = `أُرسل إلى ${data!.sent} حساب.`
  annTitle.value = annBody.value = ''
})
const makeOfficial = (id: number, name: string) => name && run(async () => {
  await api.POST('/admin/users/{user}/official', { params: { path: { user: id } }, body: { name: name as 'Owner-Sizar' | 'Owner-Sliman' } })
  annMsg.value = `صار اسم الحساب ${name}.`
})

// [UP6] A code for the coach who wrote on WhatsApp: shown here once, to send back to them.
const codes = ref<Record<number, string>>({})
const issueCode = (id: number) => run(async () => {
  const { data } = await api.POST('/admin/users/{user}/verification-code', { params: { path: { user: id } } })
  codes.value = { ...codes.value, [id]: data!.code }
})

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
async function show(t: typeof tab.value) {
  tab.value = t
  if (t === 'overview') overview.value = (await api.GET('/admin/overview')).data
  if (t === 'users') users.value = (await api.GET('/admin/users')).data!.users
  if (t === 'vacations') vacations.value = (await api.GET('/admin/vacations')).data!.vacations
  if (t === 'leagues') leagues.value = (await api.GET('/admin/leagues')).data!.leagues
  if (t === 'alliances') alliances.value = (await api.GET('/admin/alliances')).data!.tournaments
  if (t === 'backups') backups.value = (await api.GET('/admin/backups')).data!.backups
  if (t === 'commentary') commentary.value = (await api.GET('/admin/commentary')).data!.keys
}
// [UP13] The long holidays: approve (it starts now) or refuse; the coach is told either way.
const vacations = ref<any[]>([])
const decide = (id: number, approve: boolean) => run(async () => {
  await api.POST('/admin/vacations/{id}/decide', { params: { path: { id } }, body: { approve } })
  vacations.value = (await api.GET('/admin/vacations')).data!.vacations
})
const review = (id: number, approve: boolean) => run(async () => {
  alliances.value = (await api.POST('/admin/alliances/{id}/review', { params: { path: { id } }, body: { approve, note: allianceNote.value[id] || null } })).data!.tournaments
})
const backupNow = () => run(async () => { backups.value = (await api.POST('/admin/backups')).data!.backups })
onMounted(load)
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="font-display text-3xl font-extrabold">{{ $t('لوحة الإدارة') }}</h1>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
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

    <template v-if="open">
      <nav class="flex flex-wrap gap-2" :aria-label="$t('أقسام اللوحة')">
        <button v-for="(label, t) in TABS" :key="t" type="button" class="h-touch rounded-md px-4 text-sm font-bold"
                :class="tab === t ? 'bg-gold text-on-gold' : 'bg-surface'" @click="run(() => show(t))">{{ $t(label) }}</button>
      </nav>

      <section v-if="tab === 'overview' && overview" :aria-label="$t('النشاط')" class="flex flex-col gap-3">
        <!-- [X33] Before pressing Manual Deploy on Render: nothing live nor about to kick off. -->
        <div class="flex items-center gap-3 rounded-xl p-4" :class="overview.deploy.busy ? 'bg-live/15' : 'bg-success/15'" role="status">
          <span class="text-2xl" aria-hidden="true">{{ overview.deploy.busy ? '⛔' : '✅' }}</span>
          <div class="text-sm">
            <b class="block">{{ overview.deploy.busy ? $t('لا تنشر الآن: {v0} مباراة مباشرة أو تبدأ خلال نصف ساعة', { v0: overview.deploy.busy }) : $t('آمن للنشر الآن') }}</b>
            <span class="text-text-muted">{{ overview.deploy.next_kickoff ? $t('أقرب مباراة: {v0}', { v0: new Date(overview.deploy.next_kickoff).toLocaleString(intlLocale(), { weekday: 'long', hour: 'numeric', minute: '2-digit' }) }) : $t('لا مباريات مجدولة') }}</span>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-2 sm:grid-cols-4">
          <div v-for="[label, n] in [['المستخدمون', overview.users], ['الدوريات الجارية', overview.leagues.running], ['مباريات حية', overview.live_matches], ['نشطون اليوم', overview.active_today]]" :key="label" class="rounded-xl bg-surface p-4">
            <span class="block text-sm text-text-muted">{{ $t(label) }}</span><b class="font-numbers text-3xl" dir="ltr">{{ n }}</b>
          </div>
        </div>
        <div class="overflow-x-auto rounded-xl bg-surface p-4">
          <h2 class="mb-2 font-display text-lg font-bold">{{ $t('العودة أسبوعاً بعد أسبوع') }}</h2>
          <table class="w-full text-sm">
            <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('الأسبوع حتى') }}</th><th>{{ $t('نشطون') }}</th><th>{{ $t('عادوا من الأسبوع قبله') }}</th><th>{{ $t('تابعوا مباراة حية') }}</th></tr></thead>
            <tbody>
              <tr v-for="w in overview.weeks" :key="w.week" class="border-t border-text/5 text-center font-numbers">
                <td class="py-2 text-start">{{ w.week }}</td><td>{{ w.active }}</td><td>{{ w.returning }}</td><td>{{ w.live }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- The email check [X8]: Render's free plan has no shell, so the test is here. -->
      <section v-if="tab === 'overview'" :aria-label="$t('اختبار البريد')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-bold">{{ $t('اختبار البريد') }}</h2>
        <div class="flex flex-wrap gap-2">
          <input v-model="mailTo" type="email" dir="ltr" placeholder="you@gmail.com" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3" />
          <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-50" :disabled="busy || !mailTo" @click="mailTest">{{ $t('أرسل رسالة تجربة') }}</button>
        </div>
        <div v-if="mail" class="flex flex-col gap-1 text-sm">
          <p>{{ $t('الطريقة:') }} <b dir="ltr">{{ mail.mailer }}</b> {{ $t('· المرسل:') }} <b dir="ltr">{{ mail.from || '-' }}</b> {{ $t('· المفتاح:') }} <b>{{ { none: $t('لا يوجد'), api: $t('API (صحيح)'), smtp: $t('SMTP (خطأ)'), other: $t('غير معروف') }[mail.key] }}</b></p>
          <p v-if="mail.sent" class="rounded-lg bg-success/15 px-3 py-2 text-success">{{ $t('أُرسلت. افحص البريد الوارد والرسائل غير المرغوبة.') }}</p>
          <p v-if="mail.error" class="rounded-lg bg-live/15 px-3 py-2 font-mono text-xs" dir="ltr">{{ $t(mail.error) }}</p>
          <p v-if="mail.fix" class="rounded-lg bg-warning/15 px-3 py-2"><b>{{ $t('الحل:') }}</b> {{ mail.fix }}</p>
          <p v-for="p in mail.problems" :key="p" class="rounded-lg bg-warning/10 px-3 py-2">{{ p }}</p>
        </div>
      </section>

      <!-- The developers' official names and their announcements [X11]. -->
      <section v-if="tab === 'users'" :aria-label="$t('إعلان للجميع')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-bold">{{ $t('إعلان لكل اللاعبين') }}</h2>
        <p class="text-xs text-text-muted">{{ $t('يُرسل من حسابك بالشارة الرسمية، فيلزم أن يكون اسمه Owner-Sizar أو Owner-Sliman (من الجدول تحت).') }}</p>
        <input v-model="annTitle" maxlength="120" :placeholder="$t('العنوان')" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" />
        <textarea v-model="annBody" maxlength="2000" rows="3" :placeholder="$t('النص')" class="rounded-md border border-text/10 bg-surface-sunk p-3" />
        <button type="button" class="h-touch self-start rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-50" :disabled="busy || !annTitle || !annBody" @click="announce">{{ $t('أرسل للجميع') }}</button>
        <p v-if="annMsg" class="text-sm text-success" role="status">{{ $t(annMsg) }}</p>
      </section>

      <section v-if="tab === 'users'" :aria-label="$t('المستخدمون')" class="overflow-x-auto rounded-xl bg-surface p-4">
        <table class="w-full text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('الاسم') }}</th><th class="text-start">{{ $t('البريد') }}</th><th>{{ $t('انضم') }}</th><th>{{ $t('آخر يوم') }}</th><th>{{ $t('مباريات حية') }}</th><th>{{ $t('التوثيق') }}</th><th>{{ $t('اسم رسمي') }}</th></tr></thead>
          <tbody>
            <tr v-for="u in users" :key="u.id" class="border-t border-text/5">
              <td class="py-2">{{ u.name }} <span dir="ltr" class="text-xs text-text-muted">@{{ u.username }} · #{{ u.id }}</span><span v-if="u.role === 'admin'" class="ms-1 text-xs text-gold">{{ $t('مدير') }}</span></td>
              <td dir="ltr" class="text-start">{{ u.email ?? '-' }}</td><td class="whitespace-nowrap text-center">{{ day(u.joined) }}</td>
              <td class="whitespace-nowrap text-center font-numbers">{{ u.last_day ?? '-' }}</td><td class="text-center font-numbers">{{ u.matches_watched }}</td>
              <td class="whitespace-nowrap text-center">
                <span v-if="u.verified" class="text-xs text-success">{{ $t('موثّق') }}</span>
                <b v-else-if="codes[u.id]" dir="ltr" class="font-numbers text-lg text-gold" :title="$t('أرسله للمدرب على واتساب')">{{ codes[u.id] }}</b>
                <button v-else type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" @click="issueCode(u.id)">{{ $t('كود توثيق') }}</button>
              </td>
              <td class="text-center">
                <select class="h-10 rounded-md bg-surface-sunk px-2 text-xs" :aria-label="$t('أعطه اسماً رسمياً')" @change="makeOfficial(u.id, ($event.target as HTMLSelectElement).value)">
                  <option value="">-</option><option>Owner-Sizar</option><option>Owner-Sliman</option>
                </select>
              </td>
            </tr>
          </tbody>
        </table>
      </section>

      <section v-if="tab === 'vacations'" :aria-label="$t('الإجازات الطويلة')" class="flex flex-col gap-2">
        <p v-if="!vacations.length" class="rounded-xl bg-surface p-4 text-sm text-text-muted">{{ $t('لا طلبات إجازة طويلة.') }}</p>
        <article v-for="v in vacations" :key="v.id" class="flex flex-wrap items-center gap-3 rounded-xl bg-surface p-4">
          <span class="min-w-0 flex-1"><b>{{ v.user.name }}</b> <span dir="ltr" class="text-xs text-text-muted">@{{ v.user.username }}</span>
            <span class="block text-sm">{{ $t('{v0} يوماً · {v1}', { v0: v.days, v1: v.reason }) }}</span></span>
          <template v-if="v.status === 'pending'">
            <button type="button" class="h-touch rounded-md bg-success/20 px-4 font-bold text-success" @click="decide(v.id, true)">{{ $t('موافقة') }}</button>
            <button type="button" class="h-touch rounded-md bg-live/15 px-4 font-bold text-[#FF8A8A]" @click="decide(v.id, false)">{{ $t('رفض') }}</button>
          </template>
          <span v-else class="text-sm" :class="v.status === 'approved' ? 'text-success' : 'text-text-muted'">{{ v.status === 'approved' ? $t('وُوفق عليها') : $t('رُفضت') }}</span>
        </article>
      </section>

      <section v-if="tab === 'leagues'" :aria-label="$t('الدوريات')" class="overflow-x-auto rounded-xl bg-surface p-4">
        <table class="w-full text-sm">
          <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('الدوري') }}</th><th>{{ $t('الحالة') }}</th><th>{{ $t('الموسم') }}</th><th>{{ $t('مدربون') }}</th><th>{{ $t('المنشئ') }}</th></tr></thead>
          <tbody>
            <tr v-for="l in leagues" :key="l.id" class="border-t border-text/5 text-center">
              <td class="py-2 text-start">{{ l.name }}<span v-if="l.dev" class="ms-1 text-xs text-text-muted">{{ $t('تطوير') }}</span></td>
              <td>{{ $t(l.status) }}</td><td class="font-numbers">{{ l.season }}</td><td class="font-numbers">{{ l.coaches }} / {{ l.teams }}</td><td>{{ l.owner ?? '-' }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section v-if="tab === 'alliances'" :aria-label="$t('بطولات التحالفات')" class="flex flex-col gap-2">
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
      </section>

      <section v-if="tab === 'backups'" :aria-label="$t('النسخ')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
        <div class="flex items-center justify-between gap-2">
          <h2 class="font-display text-lg font-bold">{{ $t('النسخ على هذا الجهاز') }}</h2>
          <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="backupNow">{{ $t('نسخة الآن') }}</button>
        </div>
        <p class="text-xs text-text-muted">{{ $t('نسخة يومية تلقائية، ونسخة قبل كل نشر. على Render تبقى حتى إعادة التشغيل فقط: نزّل ما تريد الاحتفاظ به. والاسترجاع:') }} <code dir="ltr">{{ $t('php artisan db:restore &lt;الاسم&gt;') }}</code> {{ $t('واللعبة متوقفة، أو') }} <code dir="ltr">RESTORE_AT</code> {{ $t('على Render لأي لحظة من آخر 3 أيام.') }}</p>
        <p v-if="!backups.length" class="text-sm text-text-muted">{{ $t('لا نسخ بعد.') }}</p>
        <div v-for="b in backups" :key="b.name" class="flex min-h-touch items-center justify-between border-b border-text/5 text-sm last:border-0">
          <span class="font-numbers" dir="ltr">{{ b.name }}</span>
          <span class="flex items-center gap-3"><span class="font-numbers text-text-muted" dir="ltr">{{ size(b.bytes) }}</span>
            <a :href="`/api/v1/admin/backups/${b.name}/download`" class="flex h-touch items-center rounded-md bg-brand px-3 font-bold" download>{{ $t('تنزيل') }}</a></span>
        </div>
      </section>

      <section v-if="tab === 'commentary'" :aria-label="$t('قوالب التعليق')" class="flex flex-col gap-2">
        <details v-for="k in commentary" :key="k.key" class="rounded-xl bg-surface p-4">
          <summary class="flex min-h-touch cursor-pointer items-center justify-between"><span dir="ltr">{{ k.key }}</span><span class="font-numbers text-text-muted">{{ k.count }}</span></summary>
          <ul class="mt-2 flex flex-col gap-1 text-sm"><li v-for="(l, i) in k.lines" :key="i">{{ l }}</li></ul>
        </details>
      </section>
    </template>
  </div>
</template>
