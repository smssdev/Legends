<script setup lang="ts">
// The admin panel (Sprint 37 B2, PLAN 2.17 and 2.22; rebuilt in Sprint 21 E7): the admin only, with the password alone (Sprint 38 A1)
// A side list of sections (a scrolling row on the phone), each one page of its own: the overview,
// the activity day by day, the accounts (admins apart, search by number, suspend, delete), the leagues, the
// announcements (each opened whole with its sender and time), the holidays, the conversations with the coaches,
// the alliances, the backups and the commentary templates.
import { useAuth } from '../stores/auth'
import { statusLabel } from '../lib/statuses'
import DataEditor from './admin/DataEditor.vue'
import AnnouncementCard from '../components/AnnouncementCard.vue'
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import type { components } from '../api/schema'
import { intlLocale, t } from '../lib/i18n'
import Icon from '../components/Icon.vue'
import OfficialBadge from '../components/OfficialBadge.vue'
import VerifiedBadge from '../components/VerifiedBadge.vue'
import ConfirmDangerDialog from '../components/patterns/ConfirmDangerDialog.vue'
import { useConfirm } from '../stores/confirm'
import { useToast } from '../stores/toast'

type S = components['schemas']
type AdminUser = S['AdminUser']
const state = ref<S['AdminAccess'] | null>(null)
const error = ref('')
const notice = ref('')
const auth = useAuth()
// [Sprint 30 G6] The reported messages, and the decision on each (for all its reports at once).
const reports = ref<S['ChatReports']['reports']>([])
const REASON_NAMES: Record<string, string> = { abuse: 'سب أو إساءة', inappropriate: 'محتوى غير لائق', spam: 'إزعاج أو إعلانات', other: 'سبب آخر' }
const decideReport = (id: number, action: 'leave' | 'remove' | 'ban') => run(async () => {
  if (action === 'ban' && !(await useConfirm().ask({ title: 'حذف الرسالة وإيقاف كاتبها؟', text: 'لن يرسل في أي جروب حتى تسمح له الإدارة.', action: 'احذف وأوقفه' }))) return
  reports.value = (await api.POST('/admin/reports/{message}/decide', { params: { path: { message: id } }, body: { action } })).data!.reports
})
const unban = (id: number) => run(async () => {
  await api.DELETE('/admin/users/{user}/chat-ban', { params: { path: { user: id } } })
  notice.value = t('عاد إلى الجروبات.')
  reports.value = (await api.GET('/admin/reports')).data!.reports
})
// [Sprint 30 G6] An admin's scope, given by a full admin.
const SCOPES = { '': 'مشرف كامل', support: 'دعم', content: 'محتوى', finance: 'مالي' } as const
const setScope = (id: number, scope: string) => run(async () => {
  await api.PUT('/admin/users/{user}/scope', { params: { path: { user: id } }, body: { scope: (scope || null) as 'support' | null } })
  notice.value = t('تغيّرت صلاحيات المشرف.')
})
// [Sprint 30 P3] The test texts players can see (announcements, rewarded ads), with one button that removes them.
const junk = ref<S['JunkRow'][] | null>(null)
const junkLeagues = ref<S['JunkRow'][]>([])
const purging = ref(false)
async function loadJunk() {
  const d = (await api.GET('/admin/junk')).data!
  junk.value = [...d.announcements, ...d.house_ads]
  junkLeagues.value = d.leagues
}
const purgeJunk = () => run(async () => {
  const d = (await api.POST('/admin/junk/purge')).data!
  purging.value = false
  await show(tab.value)
  notice.value = t('حُذف {v0} إعلان و{v1} إعلان مكافأة تجريبي.', { v0: d.announcements, v1: d.house_ads })
})
// [X65] The chat groups: how long their messages are kept, and whether pictures and voice notes may be sent.
type ChatSettings = { retention_days: number; media: boolean; groups: number; messages: number; media_count: number; media_kb: number; oldest: string | null }
const chat = ref<ChatSettings | null>(null)
const busy = ref(false)

const SECTIONS = {
  overview: { label: 'الرئيسية', icon: 'home' },
  activity: { label: 'النشاط', icon: 'league' },
  users: { label: 'المستخدمون', icon: 'team' },
  leagues: { label: 'الدوريات', icon: 'leagues' },
  announcements: { label: 'الإعلانات', icon: 'bell' },
  houseAds: { label: 'إعلانات المكافأة', icon: 'match' },
  events: { label: 'الفعاليات', icon: 'league' },
  ideas: { label: 'الاقتراحات', icon: 'idea' },
  polls: { label: 'التصويت', icon: 'predict' },
  vacations: { label: 'الإجازات', icon: 'stadium' },
  conversations: { label: 'الرسائل', icon: 'inbox' },
  alliances: { label: 'بطولات التحالفات', icon: 'match' },
  backups: { label: 'النسخ', icon: 'finance' },
  commentary: { label: 'قوالب التعليق', icon: 'news' },
  data: { label: 'محرر البيانات', icon: 'team' },
  chat: { label: 'الجروبات', icon: 'chat' },
  // [Sprint 30 G6] The groups' moderation queue.
  reports: { label: 'البلاغات', icon: 'chat' },
} as const
// [Sprint 30 G6] Each section's path on the server, for an admin with a scope (the server says which it opens).
const PATHS: Record<string, string> = { houseAds: 'house-ads' }
const sectionsShown = computed(() => (Object.keys(SECTIONS) as Section[]).filter((k) => !state.value?.sections || state.value.sections.includes(PATHS[k] ?? k)))
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
// [Sprint 20 S4] The game's own rewarded ads.
const houseAds = ref<S['HouseAd'][]>([])
const houseDefaults = ref(0)
const draft = ref({ title: '', body: '', cta_label: '', cta_url: '', seconds: 30 })
// [Sprint 23] The timed events: what the admin turns on, where, and from when to when.
const events = ref<S['TimedEvent'][]>([])
const eventKinds = ref<Record<string, Record<string, number>>>({})
const eventMaxDays = ref(14)
const evDraft = ref<{ kind: S['TimedEvent']['kind']; league_id: number | null; starts: string; hours: number; power: number | null; count: number | null }>({ kind: 'madness', league_id: null, starts: '', hours: 48, power: null, count: null })
const vacationFilter = ref<'pending' | 'decided'>('pending')
// [Sprint 28] The coaches' suggestions (the answer and its reward) and the polls on what to build next.
type IdeaStatus = S['Suggestion']['status']
const ideas = ref<S['PanelSuggestion'][]>([])
const ideaCounts = ref<Record<IdeaStatus, number>>({ pending: 0, accepted: 0, built: 0, rejected: 0 })
const ideaFilter = ref<IdeaStatus>('pending')
const ideaReward = ref({ default: 50, max: 1000 })
const ideaAnswer = ref<Record<number, { coins: number; reply: string }>>({})
const IDEA_TABS: [IdeaStatus, string][] = [['pending', 'تنتظر الرد'], ['accepted', 'أعجبتنا'], ['built', 'نُفّذت'], ['rejected', 'لم تُعتمد']]
const polls = ref<S['Poll'][]>([])
const pollLimits = ref({ max_days: 30, options_min: 2, options_max: 6 })
const pollDraft = ref<{ question: string; body: string; starts: string; hours: number; options: { label: string; suggestion_id: number | null }[] }>(
  { question: '', body: '', starts: '', hours: 72, options: [{ label: '', suggestion_id: null }, { label: '', suggestion_id: null }] })
const conversations = ref<any[]>([])
const thread = ref<any | null>(null)
const reply = ref('')
const alliances = ref<any[]>([])
const allianceNote = ref<Record<number, string>>({})
const backups = ref<S['AdminBackups']['backups']>([])
const commentary = ref<{ key: string; count: number; lines: string[] }[]>([])

// [Sprint 38 A1] The panel opens once the admin's access is read: the password alone, no two-step code.
const open = computed(() => !!state.value)
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
  state.value = (await api.GET('/admin/access')).data!
  if (open.value) await show('overview')
})

async function show(s: Section) {
  tab.value = s
  notice.value = ''
  if (s === 'overview') overview.value = (await api.GET('/admin/overview')).data
  if (s === 'activity') { activity.value = (await api.GET('/admin/activity', { params: { query: { days: activityDays.value } } })).data; overview.value ??= (await api.GET('/admin/overview')).data }
  if (s === 'users') await loadUsers()
  if (s === 'chat') chat.value = (await api.GET('/admin/chat')).data!
  if (s === 'leagues') leagues.value = (await api.GET('/admin/leagues')).data!.leagues
  if (s === 'announcements') announcements.value = (await api.GET('/admin/announcements')).data!.announcements
  if (s === 'announcements' || s === 'houseAds') await loadJunk()
  if (s === 'vacations') vacations.value = (await api.GET('/admin/vacations')).data!.vacations
  if (s === 'houseAds') await loadHouseAds()
  if (s === 'events') await loadEvents()
  if (s === 'ideas') await loadIdeas()
  if (s === 'polls') await loadPolls()
  if (s === 'conversations') { conversations.value = (await api.GET('/admin/conversations')).data!.conversations; thread.value = null }
  if (s === 'alliances') alliances.value = (await api.GET('/admin/alliances')).data!.tournaments
  if (s === 'backups') backups.value = (await api.GET('/admin/backups')).data!.backups
  if (s === 'commentary') commentary.value = (await api.GET('/admin/commentary')).data!.keys
  if (s === 'reports') reports.value = (await api.GET('/admin/reports')).data!.reports
}
const go = (s: Section) => run(() => show(s))

// The accounts [Sprint 21 E7.3].
// The coaches a page at a time: «المزيد» adds the next page under the ones shown.
const usersPage = ref(1)
const moreUsers = ref(false)
async function loadUsers(page = 1) {
  const q = search.value.trim()
  const data = (await api.GET('/admin/users', { params: { query: { ...(q ? { q } : {}), ...(page > 1 ? { page } : {}) } } })).data!
  if (page === 1) admins.value = data.admins
  users.value = page === 1 ? data.users : [...users.value, ...data.users]
  usersPage.value = data.page
  moreUsers.value = data.has_more
}
// [X54] The coins form; a user's row fills its number.
const gift = ref({ account: '', amount: 100, reason: '' })
function fillGift(no: number) {
  gift.value.account = String(no)
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
const giveCoins = () => run(async () => {
  const { data } = await api.POST('/admin/coins', { body: { account_no: Number(gift.value.account), amount: gift.value.amount, reason: gift.value.reason.trim(), idempotency_key: crypto.randomUUID() } })
  notice.value = t('وصلت {v0} كوينز إلى {v1} (#{v2}). رصيده الآن {v3}.', { v0: gift.value.amount, v1: data!.user.name, v2: data!.user.account_no, v3: data!.balance })
  gift.value = { account: '', amount: 100, reason: '' }
})
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
// [X54] The card's optional picture and button, and its preview as the coaches will see it.
const annImage = ref<File | null>(null)
const annPreview = ref<string | null>(null)
const annCtaLabel = ref('')
const annCtaUrl = ref('')
function pickImage(e: Event) {
  const f = (e.target as HTMLInputElement).files?.[0] ?? null
  annImage.value = f
  if (annPreview.value) URL.revokeObjectURL(annPreview.value)
  annPreview.value = f ? URL.createObjectURL(f) : null
}
const announce = () => run(async () => {
  const form = new FormData()
  form.append('title', annTitle.value)
  form.append('body', annBody.value)
  if (annImage.value) form.append('image', annImage.value)
  if (annCtaLabel.value.trim() && annCtaUrl.value.trim()) {
    form.append('cta_label', annCtaLabel.value.trim())
    form.append('cta_url', annCtaUrl.value.trim())
  }
  const { data } = await api.POST('/admin/announcements', { body: form as never, bodySerializer: (b) => b as unknown as FormData })
  annImage.value = null
  annPreview.value = null
  annCtaLabel.value = annCtaUrl.value = ''
  notice.value = t('أُرسل إلى {v0} حساب، ووصل إشعاراً لكل الأجهزة المشتركة.', { v0: data!.sent })
  annTitle.value = annBody.value = ''
  announcements.value = (await api.GET('/admin/announcements')).data!.announcements
})

// The rewarded ads [Sprint 20 S4]: written here, shown to the coaches at random while active.
async function loadHouseAds() {
  const data = (await api.GET('/admin/house-ads')).data!
  houseAds.value = data.ads
  houseDefaults.value = data.defaults
}
const addHouseAd = () => run(async () => {
  const d = draft.value
  await api.POST('/admin/house-ads', { body: { title: d.title, body: d.body, cta_label: d.cta_label || null, cta_url: d.cta_url || null, seconds: d.seconds } })
  draft.value = { title: '', body: '', cta_label: '', cta_url: '', seconds: 30 }
  await loadHouseAds()
})
const toggleHouseAd = (a: S['HouseAd']) => run(async () => {
  await api.PATCH('/admin/house-ads/{id}', { params: { path: { id: a.id } }, body: { active: !a.active } })
  await loadHouseAds()
})
const deleteHouseAd = (a: S['HouseAd']) => run(async () => {
  if (!(await useConfirm().ask({ title: 'حذف إعلان المكافأة؟', text: a.title, action: 'احذف' }))) return
  await api.DELETE('/admin/house-ads/{id}', { params: { path: { id: a.id } } })
  await loadHouseAds()
})

// The timed events [Sprint 23]: the power is shown in its own unit (× for the multipliers, % for the discounts, points).
const EVENT_KINDS: { id: S['TimedEvent']['kind']; label: string }[] = [
  { id: 'madness', label: '⚡ جنون الانتقالات' }, { id: 'progression', label: '🚀 التقدم الفائق' }, { id: 'discount', label: '🏷️ خصم السوق' },
  { id: 'offers', label: '🎁 العروض الخاصة' }, { id: 'in_form', label: '🔥 نجوم الأسبوع' }, { id: 'legends', label: '👑 الأساطير' },
]
const EVENT_HELP: Record<string, string> = {
  madness: 'المشترون من خارج الدوري وتجديد السوق أسرع بهذا المضاعف.',
  progression: 'كل جلسة تدريب أكبر بهذا المضاعف.',
  discount: 'لاعبو العالم (مجموعة السوق) أرخص بهذه النسبة.',
  offers: 'في كل تجديد للسوق: هذا العدد من اللاعبين بخصم بهذه النسبة حتى التجديد التالي. يبدأ بتجديد السوق فوراً.',
  in_form: 'في كل تجديد: هذا العدد من اللاعبين في قمة مستواهم، بزيادة بهذه النقاط تبقى معهم. يبدأ بتجديد السوق فوراً.',
  legends: 'في كل تجديد: هذا العدد من اللاعبين أقوى من أفضل لاعبي الدوري حتى هذه النقاط، بسعر أعلى. يبدأ بتجديد السوق فوراً.',
}
const unit = (kind: string) => (kind === 'madness' || kind === 'progression' ? 'x' : kind === 'discount' || kind === 'offers' ? '%' : 'pt')
const toUi = (kind: string, power: number) => (unit(kind) === 'x' ? power / 10000 : unit(kind) === '%' ? power / 100 : power)
const fromUi = (kind: string, v: number) => Math.round(unit(kind) === 'x' ? v * 10000 : unit(kind) === '%' ? v * 100 : v)
const powerText = (kind: string, power: number) => (unit(kind) === 'x' ? `x${toUi(kind, power)}` : unit(kind) === '%' ? `${toUi(kind, power)}%` : `+${power}`)
const evKind = computed(() => eventKinds.value[evDraft.value.kind])
async function loadIdeas() {
  const data = (await api.GET('/admin/ideas', { params: { query: { status: ideaFilter.value } } })).data!
  ideas.value = data.suggestions
  ideaCounts.value = data.counts
  ideaReward.value = { default: data.reward_default, max: data.reward_max }
  ideaAnswer.value = Object.fromEntries(data.suggestions.map((x) => [x.id, { coins: x.coins ? 0 : data.reward_default, reply: x.reply ?? '' }]))
}
const filterIdeas = (f: IdeaStatus) => run(async () => { ideaFilter.value = f; await loadIdeas() })
const decideIdea = (x: S['PanelSuggestion'], status: 'accepted' | 'built' | 'rejected') => run(async () => {
  const a = ideaAnswer.value[x.id]
  const coins = status === 'rejected' || x.coins ? 0 : a.coins
  await api.POST('/admin/ideas/{id}/decide', { params: { path: { id: x.id } }, body: { status, coins, reply: a.reply.trim() || null } })
  notice.value = coins ? t('أُرسل الرد و{v0} كوينز لـ {v1}.', { v0: coins, v1: x.user.name }) : t('أُرسل الرد لـ {v0}.', { v0: x.user.name })
  await loadIdeas()
})
// A liked suggestion becomes an option of the next poll at once.
const toPoll = (x: S['PanelSuggestion']) => {
  const empty = pollDraft.value.options.find((o) => !o.label.trim())
  if (empty) Object.assign(empty, { label: x.title, suggestion_id: x.id })
  else if (pollDraft.value.options.length < pollLimits.value.options_max) pollDraft.value.options.push({ label: x.title, suggestion_id: x.id })
  return run(() => show('polls'))
}
async function loadPolls() {
  const data = (await api.GET('/admin/polls')).data!
  polls.value = data.polls
  pollLimits.value = { max_days: data.max_days, options_min: data.options_min, options_max: data.options_max }
}
const pollReady = computed(() => pollDraft.value.question.trim().length >= 4 && pollDraft.value.hours >= 1 && pollDraft.value.hours <= pollLimits.value.max_days * 24
  && pollDraft.value.options.filter((o) => o.label.trim()).length >= pollLimits.value.options_min)
const openPoll = () => run(async () => {
  const d = pollDraft.value
  await api.POST('/admin/polls', { body: { question: d.question.trim(), body: d.body.trim() || null, starts_at: d.starts ? new Date(d.starts).toISOString() : null, hours: d.hours,
    options: d.options.filter((o) => o.label.trim()).map((o) => ({ label: o.label.trim(), suggestion_id: o.suggestion_id })) } })
  pollDraft.value = { question: '', body: '', starts: '', hours: 72, options: [{ label: '', suggestion_id: null }, { label: '', suggestion_id: null }] }
  notice.value = t('فُتح التصويت.')
  await loadPolls()
})
const closePoll = (p: S['Poll']) => run(async () => {
  const ending = p.state === 'open' && p.total
  if (!(await useConfirm().ask({ title: ending ? 'إنهاء هذا التصويت الآن؟' : 'حذف هذا التصويت؟', action: ending ? 'أنهه' : 'احذف' }))) return
  await api.DELETE('/admin/polls/{id}', { params: { path: { id: p.id } } })
  await loadPolls()
})

async function loadEvents() {
  const data = (await api.GET('/admin/events')).data!
  events.value = data.events
  eventKinds.value = data.kinds
  eventMaxDays.value = data.max_days
  if (!leagues.value.length) leagues.value = (await api.GET('/admin/leagues')).data!.leagues
}
const addEvent = () => run(async () => {
  const d = evDraft.value
  const starts = d.starts ? new Date(d.starts) : new Date()
  const ends = new Date(starts.getTime() + d.hours * 3600_000)
  await api.POST('/admin/events', { body: { kind: d.kind, league_id: d.league_id, starts_at: d.starts ? starts.toISOString() : null, ends_at: ends.toISOString(),
    power: d.power === null ? null : fromUi(d.kind, d.power), count: evKind.value?.count ? d.count : null } })
  notice.value = t('بدأت الفعالية، وتنتهي وحدها في موعدها.')
  evDraft.value = { ...d, starts: '', power: null, count: null }
  await loadEvents()
})
const extendEvent = (e: S['TimedEvent']) => run(async () => {
  await api.PATCH('/admin/events/{id}', { params: { path: { id: e.id } }, body: { ends_at: new Date(new Date(e.ends_at).getTime() + 24 * 3600_000).toISOString() } })
  await loadEvents()
})
const stopEvent = (e: S['TimedEvent']) => run(async () => {
  if (!(await useConfirm().ask({ title: 'إيقاف الفعالية الآن؟', text: 'تنتهي للجميع في الحال.', action: 'أوقفها' }))) return
  await api.DELETE('/admin/events/{id}', { params: { path: { id: e.id } } })
  await loadEvents()
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
// [Sprint 30 Q3] The test's answer in the toast as well: sent, or why not (it used to fail without a word on top).
const mailTest = () => run(async () => {
  mail.value = (await api.POST('/admin/mail-test', { body: { to: mailTo.value } })).data ?? null
  if (mail.value?.sent) useToast().show(t('أُرسلت. افحص البريد الوارد والرسائل غير المرغوبة.'))
  else if (mail.value) useToast().show(mail.value.fix ?? mail.value.error ?? t('لم تُرسل الرسالة.'), 'error', 6000)
})
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
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!state && !error" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>

    <div v-if="open" class="grid gap-4 lg:grid-cols-[13rem_minmax(0,1fr)]">
      <!-- The sections: a side list on the computer, a scrolling row on the phone. -->
      <nav class="flex gap-1 overflow-x-auto rounded-xl bg-surface p-1 lg:sticky lg:top-24 lg:flex-col lg:self-start lg:overflow-visible lg:p-2" :aria-label="$t('أقسام اللوحة')">
        <button v-for="key in sectionsShown" :key="key" type="button" :data-section="key" class="flex h-touch shrink-0 items-center gap-2 rounded-lg px-3 text-sm font-bold"
          :class="tab === key ? 'bg-gold text-on-gold' : 'text-text-soft hover:bg-surface-raised'" :aria-current="tab === key ? 'page' : undefined" @click="go(key)">
          <Icon :name="SECTIONS[key].icon" :size="18" />{{ $t(SECTIONS[key].label) }}
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
          <!-- [X54] Coins to any account by its number. -->
          <form class="flex flex-wrap items-end gap-2 rounded-xl bg-surface p-3" :aria-label="$t('أضف كوينز لحساب')" @submit.prevent="giveCoins">
            <b class="basis-full font-display text-sm">{{ $t('أضف كوينز لحساب') }}</b>
            <label class="flex flex-col gap-1 text-xs">{{ $t('رقم الحساب') }}<input v-model="gift.account" inputmode="numeric" maxlength="5" dir="ltr" class="h-touch w-28 rounded-md bg-surface-sunk px-3 font-numbers" /></label>
            <label class="flex flex-col gap-1 text-xs">{{ $t('الكوينز') }}<input v-model.number="gift.amount" type="number" min="1" dir="ltr" class="h-touch w-28 rounded-md bg-surface-sunk px-3 font-numbers" /></label>
            <label class="flex min-w-48 flex-1 flex-col gap-1 text-xs">{{ $t('السبب (يراه المدرب)') }}<input v-model="gift.reason" maxlength="200" class="h-touch rounded-md bg-surface-sunk px-3 text-sm" /></label>
            <button type="submit" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="busy || !/^\d{5}$/.test(gift.account) || !(gift.amount > 0) || gift.reason.trim().length < 3">{{ $t('أضف') }}</button>
          </form>
          <form class="flex flex-wrap gap-2" role="search" @submit.prevent="run(() => loadUsers())">
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
              <span v-if="u.suspended" class="rounded-pill bg-live/20 px-2 text-xs text-danger">{{ $t('معلّق') }}</span>
              <span class="ms-auto text-xs text-text-muted">{{ $t('انضم {v0} · آخر يوم {v1} · {v2} مباراة حية', { v0: day(u.joined), v1: u.last_day ?? '-', v2: u.matches_watched }) }}</span>
            </div>
            <p v-if="u.email" class="text-xs text-text-muted" dir="ltr">{{ u.email }}</p>
            <p v-if="u.suspended?.reason" class="text-xs text-danger">{{ $t('السبب: {v0}', { v0: u.suspended.reason }) }}</p>
            <div class="flex flex-wrap items-center gap-2">
              <template v-if="!u.verified">
                <b v-if="codes[u.id]" dir="ltr" class="font-numbers text-lg text-gold">{{ codes[u.id] }}</b>
                <button v-else type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" @click="issueCode(u.id)">{{ $t('كود توثيق') }}</button>
              </template>
              <button type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" @click="writeTo(u)">{{ $t('راسله') }}</button>
              <button type="button" class="h-10 rounded-md bg-gold/15 px-3 text-xs font-bold text-gold" @click="fillGift(u.account_no ?? 0)">{{ $t('أضف كوينز') }}</button>
              <select v-if="u.role === 'admin' && !state?.scope && u.id !== auth.user?.id" class="h-10 rounded-md bg-surface-sunk px-2 text-xs" :aria-label="$t('صلاحيات المشرف')" :value="(u as any).admin_scope ?? ''" @change="setScope(u.id, ($event.target as HTMLSelectElement).value)">
                <option v-for="(label, k) in SCOPES" :key="k" :value="k">{{ $t(label) }}</option>
              </select>
              <select v-if="u.role === 'admin'" class="h-10 rounded-md bg-surface-sunk px-2 text-xs" :aria-label="$t('أعطه اسماً رسمياً')" @change="makeOfficial(u.id, ($event.target as HTMLSelectElement).value)">
                <option value="">{{ $t('اسم رسمي') }}</option><option>Owner-Sizar</option><option>Owner-Sliman</option>
              </select>
              <template v-if="u.role !== 'admin'">
                <button v-if="u.suspended" type="button" class="h-10 rounded-md bg-success/20 px-3 text-xs font-bold text-success" @click="unsuspend(u)">{{ $t('ارفع التعليق') }}</button>
                <button v-else type="button" class="h-10 rounded-md bg-warning/15 px-3 text-xs font-bold text-warning" @click="acting = { id: u.id, kind: 'suspend', text: '' }">{{ $t('علّق الحساب') }}</button>
                <button type="button" class="h-10 rounded-md bg-live/15 px-3 text-xs font-bold text-danger" @click="acting = { id: u.id, kind: 'delete', text: '' }">{{ $t('احذف الحساب') }}</button>
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
          <button v-if="userTab === 'users' && moreUsers" type="button" class="h-touch self-center rounded-lg bg-surface-raised px-6 text-sm font-bold disabled:opacity-40" :disabled="busy"
            @click="run(() => loadUsers(usersPage + 1))">{{ $t('المزيد من المدربين') }}</button>
        </template>

        <!-- [Sprint 21 E7.6] The leagues, each creator with his account number. -->
        <section v-if="tab === 'leagues'" :aria-label="$t('الدوريات')" class="overflow-x-auto rounded-xl bg-surface p-4">
          <table class="w-full min-w-[560px] text-sm">
            <thead class="text-text-muted"><tr><th class="py-2 text-start">{{ $t('الدوري') }}</th><th>{{ $t('الحالة') }}</th><th>{{ $t('الموسم') }}</th><th>{{ $t('مدربون') }}</th><th class="text-start">{{ $t('المنشئ') }}</th></tr></thead>
            <tbody>
              <tr v-for="l in leagues" :key="l.id" class="border-t border-text/5 text-center">
                <td class="py-2 text-start">{{ l.name }}<span v-if="l.dev" class="ms-1 text-xs text-text-muted">{{ $t('تطوير') }}</span></td>
                <td>{{ $t(statusLabel(l.status)) }}</td><td class="font-numbers">{{ l.season }}</td><td class="font-numbers">{{ l.coaches }} / {{ l.teams }}</td>
                <td class="text-start">{{ l.owner ?? '-' }} <span v-if="l.owner_no" class="rounded bg-surface-sunk px-1.5 font-numbers text-xs" dir="ltr">#{{ l.owner_no }}</span></td>
              </tr>
            </tbody>
          </table>
        </section>

        <!-- [Sprint 21 E7.2] The announcements: write one, and open any to read it whole. -->
        <template v-if="tab === 'announcements'">
          <section v-if="junk?.length" class="flex flex-col gap-2 rounded-xl border border-live/40 bg-live/10 p-4" role="alert">
            <h2 class="font-display text-lg font-bold">{{ $t('نصوص تجريبية يراها المدربون: {v0}', { v0: junk.length }) }}</h2>
            <p class="text-sm"><bdi v-for="(j, i) in junk" :key="i" class="me-2 inline-block rounded-pill bg-surface px-2 py-0.5" dir="auto">{{ j.title }}</bdi></p>
            <p v-if="junkLeagues.length" class="text-xs text-text-muted">{{ $t('ودوريات بأسماء تجريبية (تُنهى يدوياً): {v0}', { v0: junkLeagues.map((l) => l.title).join('، ') }) }}</p>
            <button type="button" class="h-touch self-start rounded-md bg-live px-4 font-bold text-white" :disabled="busy" @click="purging = true">{{ $t('امسحها من الإعلانات وإعلانات المكافأة') }}</button>
          </section>
          <section :aria-label="$t('إعلان جديد')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <h2 class="font-display text-lg font-bold">{{ $t('إعلان جديد لكل اللاعبين') }}</h2>
            <p class="text-xs text-text-muted">{{ $t('يُرسل من حسابك الرسمي (Owner-Sizar أو Owner-Sliman) بشارته، ويصل رسالة وإشعاراً لكل الحسابات.') }}</p>
            <input v-model="annTitle" maxlength="120" :placeholder="$t('العنوان')" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" />
            <textarea v-model="annBody" maxlength="2000" rows="5" :placeholder="$t('النص (سطر فارغ بين الفقرات)')" class="rounded-md border border-text/10 bg-surface-sunk p-3" />
            <!-- [X54] An optional wide picture, and an optional button to a page of the game or a site. -->
            <label class="flex flex-wrap items-center gap-2 text-sm">{{ $t('صورة (اختيارية)') }}
              <input type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="text-xs" @change="pickImage" />
            </label>
            <div class="grid gap-2 sm:grid-cols-[1fr_2fr]">
              <input v-model="annCtaLabel" maxlength="40" :placeholder="$t('نص الزر (اختياري)')" class="h-touch min-w-0 rounded-md border border-text/10 bg-surface-sunk px-3" />
              <input v-model="annCtaUrl" maxlength="300" dir="ltr" :placeholder="$t('/leagues أو https://…')" class="h-touch min-w-0 rounded-md border border-text/10 bg-surface-sunk px-3" />
            </div>
            <div v-if="annTitle || annBody" class="flex flex-col gap-1">
              <span class="text-xs text-text-muted">{{ $t('كما سيراه المدربون') }}</span>
              <AnnouncementCard :title="annTitle" :body="annBody" :at="new Date().toISOString()" :image-url="annPreview" :cta="annCtaLabel.trim() && annCtaUrl.trim() ? { label: annCtaLabel.trim(), url: annCtaUrl.trim() } : null" />
            </div>
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
              <AnnouncementCard :title="a.title" :body="a.body" :at="a.at" :image-url="a.image_url" :cta="a.cta" />
              <p class="text-xs text-text-muted">{{ $t('أرسله {v0} (@{v1}) في {v2} إلى {v3} حساب.', { v0: a.sender?.name ?? '-', v1: a.sender?.username ?? '-', v2: when(a.at), v3: a.sent }) }}</p>
            </div>
          </article>
        </template>

        <!-- [Sprint 20 S4] The rewarded ads: each watch cuts 30 minutes off a training or stadium wait. -->
        <template v-if="tab === 'houseAds'">
          <section v-if="junk?.length" class="flex flex-col gap-2 rounded-xl border border-live/40 bg-live/10 p-4" role="alert">
            <h2 class="font-display text-lg font-bold">{{ $t('نصوص تجريبية يراها المدربون: {v0}', { v0: junk.length }) }}</h2>
            <p class="text-sm"><bdi v-for="(j, i) in junk" :key="i" class="me-2 inline-block rounded-pill bg-surface px-2 py-0.5" dir="auto">{{ j.title }}</bdi></p>
            <p v-if="junkLeagues.length" class="text-xs text-text-muted">{{ $t('ودوريات بأسماء تجريبية (تُنهى يدوياً): {v0}', { v0: junkLeagues.map((l) => l.title).join('، ') }) }}</p>
            <button type="button" class="h-touch self-start rounded-md bg-live px-4 font-bold text-white" :disabled="busy" @click="purging = true">{{ $t('امسحها من الإعلانات وإعلانات المكافأة') }}</button>
          </section>
          <section :aria-label="$t('إعلان مكافأة جديد')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <h2 class="font-display text-lg font-bold">{{ $t('إعلان مكافأة جديد') }}</h2>
            <p class="text-xs text-text-muted">{{ $t('يظهر للمدربين حين يضغطون «شاهد إعلاناً» في التدريب أو الملعب، ويقلّص 30 دقيقة بعد انتهاء وقته. وحين لا يوجد إعلان مفعّل تظهر إعلانات اللعبة ({v0}).', { v0: houseDefaults }) }}</p>
            <input v-model="draft.title" maxlength="80" :placeholder="$t('العنوان')" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" />
            <textarea v-model="draft.body" maxlength="300" rows="3" :placeholder="$t('النص')" class="rounded-md border border-text/10 bg-surface-sunk p-3" />
            <div class="grid gap-2 sm:grid-cols-[1fr_2fr_auto]">
              <input v-model="draft.cta_label" maxlength="40" :placeholder="$t('نص الرابط (اختياري)')" class="h-touch min-w-0 rounded-md border border-text/10 bg-surface-sunk px-3" />
              <input v-model="draft.cta_url" maxlength="300" type="url" dir="ltr" placeholder="https://" class="h-touch min-w-0 rounded-md border border-text/10 bg-surface-sunk px-3" />
              <label class="flex items-center gap-2 text-sm">{{ $t('الثواني') }}<input v-model.number="draft.seconds" type="number" min="15" max="60" class="h-touch w-20 rounded-md border border-text/10 bg-surface-sunk px-2 font-numbers" /></label>
            </div>
            <button type="button" class="h-touch self-start rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-50" :disabled="busy || draft.title.length < 3 || draft.body.length < 3" @click="addHouseAd">{{ $t('أضف الإعلان') }}</button>
          </section>
          <p v-if="!houseAds.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا إعلانات منك بعد: تظهر إعلانات اللعبة.') }}</p>
          <article v-for="a in houseAds" :key="a.id" class="flex flex-col gap-2 rounded-xl bg-surface p-4" :class="a.active ? '' : 'opacity-60'">
            <div class="flex flex-wrap items-center gap-2">
              <b class="min-w-0 flex-1 font-display">{{ a.title }}</b>
              <span class="text-xs text-text-muted">{{ $t('{v0} ث · ظهر {v1} مرة', { v0: a.seconds, v1: a.views }) }}</span>
            </div>
            <p class="text-sm">{{ a.body }}</p>
            <p v-if="a.cta_url" class="truncate text-xs text-ring" dir="ltr">{{ a.cta_label ? a.cta_label + ' · ' : '' }}{{ a.cta_url }}</p>
            <div class="flex gap-2">
              <button type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" :disabled="busy" @click="toggleHouseAd(a)">{{ a.active ? $t('أوقفه') : $t('فعّله') }}</button>
              <button type="button" class="h-10 rounded-md bg-live/15 px-3 text-xs font-bold text-danger" :disabled="busy" @click="deleteHouseAd(a)">{{ $t('احذف') }}</button>
            </div>
          </article>
        </template>

        <!-- [Sprint 23] The timed events: none permanent, each with its start and end, in every league or one. -->
        <template v-if="tab === 'events'">
          <section :aria-label="$t('فعالية جديدة')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <h2 class="font-display text-lg font-bold">{{ $t('فعالية جديدة') }}</h2>
            <div class="grid gap-2 sm:grid-cols-2">
              <label class="flex flex-col gap-1 text-sm">{{ $t('النوع') }}
                <select v-model="evDraft.kind" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" @change="evDraft.power = evDraft.count = null">
                  <option v-for="k in EVENT_KINDS" :key="k.id" :value="k.id">{{ $t(k.label) }}</option>
                </select></label>
              <label class="flex flex-col gap-1 text-sm">{{ $t('أين') }}
                <select v-model="evDraft.league_id" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3">
                  <option :value="null">{{ $t('كل الدوريات') }}</option>
                  <option v-for="l in leagues" :key="l.id" :value="l.id">{{ l.name }} (#{{ l.id }})</option>
                </select></label>
              <label class="flex flex-col gap-1 text-sm">{{ $t('البداية (فارغة = الآن)') }}
                <input v-model="evDraft.starts" type="datetime-local" dir="ltr" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" /></label>
              <label class="flex flex-col gap-1 text-sm">{{ $t('المدة بالساعات (حتى {v0} يوماً)', { v0: eventMaxDays }) }}
                <input v-model.number="evDraft.hours" type="number" min="1" :max="eventMaxDays * 24" dir="ltr" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3 font-numbers" /></label>
              <label v-if="evKind" class="flex flex-col gap-1 text-sm">{{ $t('القوة: من {v0} إلى {v1}', { v0: powerText(evDraft.kind, evKind.min), v1: powerText(evDraft.kind, evKind.max) }) }}
                <input v-model.number="evDraft.power" type="number" :step="unit(evDraft.kind) === 'x' ? 0.25 : 1" :min="toUi(evDraft.kind, evKind.min)" :max="toUi(evDraft.kind, evKind.max)"
                  :placeholder="String(toUi(evDraft.kind, evKind.power))" dir="ltr" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3 font-numbers" /></label>
              <label v-if="evKind?.count" class="flex flex-col gap-1 text-sm">{{ $t('عدد اللاعبين في كل تجديد (حتى {v0})', { v0: evKind.count_max }) }}
                <input v-model.number="evDraft.count" type="number" min="1" :max="evKind.count_max" :placeholder="String(evKind.count)" dir="ltr" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3 font-numbers" /></label>
            </div>
            <p class="text-xs text-text-muted">{{ $t(EVENT_HELP[evDraft.kind]) }}</p>
            <button type="button" class="h-touch self-start rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-50" :disabled="busy || !evDraft.hours || evDraft.hours > eventMaxDays * 24" @click="addEvent">{{ $t('ابدأ الفعالية') }}</button>
          </section>
          <p v-if="!events.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا فعاليات بعد.') }}</p>
          <article v-for="e in events" :key="e.id" class="flex flex-col gap-2 rounded-xl bg-surface p-4" :class="e.state === 'ended' ? 'opacity-60' : ''">
            <div class="flex flex-wrap items-center gap-2">
              <b class="min-w-0 flex-1 font-display">{{ $t(EVENT_KINDS.find((k) => k.id === e.kind)?.label ?? e.kind) }} <span class="font-numbers text-gold" dir="ltr">{{ powerText(e.kind, e.power) }}</span></b>
              <span class="rounded-pill px-2 text-xs font-bold" :class="e.state === 'running' ? 'bg-success/15 text-success' : e.state === 'upcoming' ? 'bg-gold/15 text-gold' : 'bg-text/10 text-text-muted'">{{ $t(e.state === 'running' ? 'جارية' : e.state === 'upcoming' ? 'قادمة' : 'انتهت') }}</span>
            </div>
            <p class="text-xs text-text-muted">{{ e.league ? e.league.name : $t('كل الدوريات') }} · {{ when(e.starts_at) }} ← {{ when(e.ends_at) }}<template v-if="e.count"> · {{ $t('{v0} لاعبين في كل تجديد', { v0: e.count }) }}</template></p>
            <div v-if="e.state !== 'ended'" class="flex gap-2">
              <button type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" :disabled="busy" @click="extendEvent(e)">{{ $t('مدّها 24 ساعة') }}</button>
              <button type="button" class="h-10 rounded-md bg-live/15 px-3 text-xs font-bold text-danger" :disabled="busy" @click="stopEvent(e)">{{ $t(e.state === 'running' ? 'أنهِها الآن' : 'احذف') }}</button>
            </div>
          </article>
        </template>

        <!-- [Sprint 28] The coaches' suggestions: answer each with a word, and a reward for one the team likes. -->
        <template v-if="tab === 'ideas'">
          <div class="flex gap-1 self-start overflow-x-auto rounded-xl bg-surface p-1" role="tablist">
            <button v-for="[k, l] in IDEA_TABS" :key="k" type="button" role="tab" :aria-selected="ideaFilter === k" class="flex h-touch shrink-0 items-center gap-1 rounded-lg px-3 text-sm font-bold"
              :class="ideaFilter === k ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="filterIdeas(k)">{{ $t(l) }} <span class="font-numbers text-xs">{{ ideaCounts[k] }}</span></button>
          </div>
          <p v-if="!ideas.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا اقتراحات هنا.') }}</p>
          <article v-for="x in ideas" :key="x.id" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <div class="flex flex-wrap items-center gap-2">
              <b class="min-w-0 flex-1 font-display">{{ x.title }}</b>
              <span class="text-xs text-text-muted">{{ x.user.name }} · <span dir="ltr">#{{ x.user.account_no }}</span> · {{ when(x.at) }}</span>
            </div>
            <p class="whitespace-pre-line text-sm text-text-soft">{{ x.body }}</p>
            <p v-if="x.coins" class="text-xs font-bold text-gold">{{ $t('أخذ مكافأة {v0} كوينز', { v0: x.coins }) }}</p>
            <template v-if="ideaAnswer[x.id] && x.status !== 'rejected' && x.status !== 'built'">
              <div class="grid gap-2 sm:grid-cols-[8rem_minmax(0,1fr)]">
                <label v-if="!x.coins" class="flex flex-col gap-1 text-xs">{{ $t('المكافأة (حتى {v0})', { v0: ideaReward.max }) }}
                  <input v-model.number="ideaAnswer[x.id].coins" type="number" min="0" :max="ideaReward.max" dir="ltr" class="h-touch rounded-md bg-surface-sunk px-3 font-numbers" /></label>
                <label class="flex flex-col gap-1 text-xs" :class="x.coins ? 'sm:col-span-2' : ''">{{ $t('كلمة للمدرب (اختيارية)') }}
                  <input v-model="ideaAnswer[x.id].reply" maxlength="500" class="h-touch rounded-md bg-surface-sunk px-3" /></label>
              </div>
              <div class="flex flex-wrap gap-2">
                <button v-if="x.status === 'pending'" type="button" class="h-10 rounded-md bg-gold px-3 text-xs font-bold text-on-gold" :disabled="busy" @click="decideIdea(x, 'accepted')">{{ $t('أعجبنا') }}</button>
                <button type="button" class="h-10 rounded-md bg-success/20 px-3 text-xs font-bold" :disabled="busy" @click="decideIdea(x, 'built')">{{ $t('نُفّذ في اللعبة') }}</button>
                <button v-if="x.status === 'pending'" type="button" class="h-10 rounded-md bg-live/15 px-3 text-xs font-bold text-danger" :disabled="busy" @click="decideIdea(x, 'rejected')">{{ $t('لم يُعتمد') }}</button>
                <button v-if="x.status !== 'pending'" type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" :disabled="busy" @click="toPoll(x)">{{ $t('أضفه لتصويت') }}</button>
              </div>
            </template>
            <p v-else-if="x.reply" class="text-xs text-text-muted">{{ $t('ردنا:') }} {{ x.reply }}</p>
          </article>
        </template>

        <!-- [Sprint 28] The polls: the options, the start and how long it runs; the counts at any time here. -->
        <template v-if="tab === 'polls'">
          <section :aria-label="$t('تصويت جديد')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <h2 class="font-display text-lg font-bold">{{ $t('تصويت جديد') }}</h2>
            <label class="flex flex-col gap-1 text-sm">{{ $t('السؤال') }}
              <input v-model="pollDraft.question" maxlength="160" :placeholder="$t('ما الميزة التي نبنيها أولاً؟')" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" /></label>
            <label class="flex flex-col gap-1 text-sm">{{ $t('شرح قصير (اختياري)') }}
              <textarea v-model="pollDraft.body" rows="2" maxlength="1000" class="rounded-md border border-text/10 bg-surface-sunk p-3" /></label>
            <div class="flex flex-col gap-2">
              <span class="text-sm">{{ $t('الخيارات (من {v0} إلى {v1})', { v0: pollLimits.options_min, v1: pollLimits.options_max }) }}</span>
              <div v-for="(o, i) in pollDraft.options" :key="i" class="flex gap-2">
                <input v-model="o.label" maxlength="120" :placeholder="$t('الخيار {v0}', { v0: i + 1 })" :aria-label="$t('الخيار {v0}', { v0: i + 1 })" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3" />
                <button v-if="pollDraft.options.length > pollLimits.options_min" type="button" class="size-touch shrink-0 rounded-md bg-surface-raised" :aria-label="$t('احذف الخيار')" @click="pollDraft.options.splice(i, 1)">✕</button>
              </div>
              <button v-if="pollDraft.options.length < pollLimits.options_max" type="button" class="h-10 self-start rounded-md bg-surface-raised px-3 text-xs font-bold" @click="pollDraft.options.push({ label: '', suggestion_id: null })">{{ $t('+ خيار') }}</button>
            </div>
            <div class="grid gap-2 sm:grid-cols-2">
              <label class="flex flex-col gap-1 text-sm">{{ $t('البداية (فارغة = الآن)') }}
                <input v-model="pollDraft.starts" type="datetime-local" dir="ltr" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" /></label>
              <label class="flex flex-col gap-1 text-sm">{{ $t('المدة بالساعات (حتى {v0} يوماً)', { v0: pollLimits.max_days }) }}
                <input v-model.number="pollDraft.hours" type="number" min="1" :max="pollLimits.max_days * 24" dir="ltr" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3 font-numbers" /></label>
            </div>
            <button type="button" class="h-touch self-start rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-50" :disabled="busy || !pollReady" @click="openPoll">{{ $t('افتح التصويت') }}</button>
          </section>
          <p v-if="!polls.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا تصويت بعد.') }}</p>
          <article v-for="p in polls" :key="p.id" class="flex flex-col gap-2 rounded-xl bg-surface p-4" :class="p.state === 'ended' ? 'opacity-80' : ''">
            <div class="flex flex-wrap items-center gap-2">
              <b class="min-w-0 flex-1 font-display">{{ p.question }}</b>
              <span class="rounded-pill px-2 text-xs font-bold" :class="p.state === 'open' ? 'bg-success/15 text-success' : p.state === 'upcoming' ? 'bg-gold/15 text-gold' : 'bg-text/10 text-text-muted'">{{ $t(p.state === 'open' ? 'مفتوح' : p.state === 'upcoming' ? 'قادم' : 'انتهى') }}</span>
            </div>
            <p class="text-xs text-text-muted">{{ when(p.starts_at) }} ← {{ when(p.ends_at) }} · {{ $t('{v0} صوتاً', { v0: p.total ?? 0 }) }}</p>
            <ul class="flex flex-col gap-1 text-sm">
              <li v-for="o in p.options" :key="o.id" class="flex items-center gap-2 rounded-md bg-surface-sunk px-3 py-2" :class="p.winners.includes(o.id) ? 'ring-1 ring-gold' : ''">
                <span class="min-w-0 flex-1">{{ o.label }}<span v-if="p.winners.includes(o.id)" class="ms-1">🏆</span></span><b class="font-numbers" dir="ltr">{{ o.votes ?? 0 }}</b>
              </li>
            </ul>
            <button v-if="p.state !== 'ended'" type="button" class="h-10 self-start rounded-md bg-live/15 px-3 text-xs font-bold text-danger" :disabled="busy" @click="closePoll(p)">{{ $t(p.state === 'open' && p.total ? 'أنهِه الآن' : 'احذف') }}</button>
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
                <button type="button" class="h-touch rounded-md bg-live/15 px-4 font-bold text-danger" @click="decide(v.id, false)">{{ $t('رفض') }}</button>
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
            <div class="flex flex-wrap items-center justify-between gap-2"><b>{{ a.name }}</b><span class="text-sm text-text-muted">{{ a.league }} · {{ $t(statusLabel(a.status)) }}</span></div>
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

        <!-- [Sprint 30 G6] The groups' moderation: each reported message once, with how many reported it and why. -->
        <section v-if="tab === 'reports'" class="flex flex-col gap-2" :aria-label="$t('البلاغات')">
          <p v-if="!reports.length" class="rounded-xl bg-surface p-4 text-text-muted">{{ $t('لا بلاغات تنتظر.') }}</p>
          <article v-for="r in reports" :key="r.message_id" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
            <div class="flex flex-wrap items-center gap-2 text-sm">
              <b>{{ r.writer.name }}</b><span class="text-text-muted" dir="ltr">@{{ r.writer.username }}</span><span class="text-text-muted">· {{ r.group }}</span>
              <span class="ms-auto rounded-pill bg-live/15 px-2 font-numbers text-xs font-bold text-danger">{{ $t('{v0} بلاغ', { v0: r.reports }) }}</span>
            </div>
            <p class="rounded-lg bg-surface-sunk p-3 text-sm" dir="auto">{{ r.body ?? (r.kind === 'image' ? $t('صورة') : $t('رسالة صوتية')) }}</p>
            <p class="text-xs text-text-muted">{{ Object.entries(r.reasons).map(([k, n]) => `${$t(REASON_NAMES[k] ?? k)} (${n})`).join('، ') }}<template v-if="r.notes.length"> · {{ r.notes.join(' · ') }}</template></p>
            <div class="flex flex-wrap gap-2">
              <button type="button" class="h-10 rounded-md bg-surface-raised px-3 text-xs font-bold" :disabled="busy" @click="decideReport(r.message_id, 'leave')">{{ $t('اتركها') }}</button>
              <button type="button" class="h-10 rounded-md bg-warning/15 px-3 text-xs font-bold text-warning" :disabled="busy" @click="decideReport(r.message_id, 'remove')">{{ $t('احذف الرسالة') }}</button>
              <button v-if="!r.writer.banned" type="button" class="h-10 rounded-md bg-live/15 px-3 text-xs font-bold text-danger" :disabled="busy" @click="decideReport(r.message_id, 'ban')">{{ $t('احذف وأوقف كاتبها') }}</button>
              <button v-else type="button" class="h-10 rounded-md bg-success/15 px-3 text-xs font-bold text-success" :disabled="busy" @click="unban(r.writer.id)">{{ $t('أعده إلى الجروبات') }}</button>
            </div>
          </article>
        </section>
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

        <!-- [X62 E8] The game's data editor. -->
        <DataEditor v-if="tab === 'data'" />
        <!-- [X65] The chat groups' retention and media. -->
        <section v-if="tab === 'chat' && chat" :aria-label="$t('الجروبات')" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
          <p class="text-sm text-text-muted">{{ $t('{v0} جروب، و{v1} رسالة، و{v2} صورة ورسالة صوتية ({v3} ك.ب).', { v0: chat.groups, v1: chat.messages, v2: chat.media_count, v3: chat.media_kb }) }}</p>
          <label class="flex flex-wrap items-center gap-2"><b>{{ $t('احذف الرسائل الأقدم من') }}</b>
            <input v-model.number="chat.retention_days" type="number" min="0" max="365" dir="ltr" class="h-touch w-24 rounded-lg bg-surface-sunk px-3 font-numbers" />
            <span>{{ $t('يوماً (0: تبقى كلها)') }}</span></label>
          <label class="flex min-h-touch items-center gap-2"><input v-model="chat.media" type="checkbox" class="size-5" /><b>{{ $t('السماح بالصور والرسائل الصوتية') }}</b></label>
          <div class="flex flex-wrap gap-2">
            <button type="button" class="h-touch rounded-lg bg-gold px-4 font-bold text-on-gold" :disabled="busy"
              @click="run(async () => { chat = (await api.PUT('/admin/chat', { body: { retention_days: chat!.retention_days, media: chat!.media } })).data!; notice = t('حُفظت إعدادات الجروبات.') })">{{ $t('حفظ') }}</button>
            <button type="button" class="h-touch rounded-lg bg-surface-sunk px-4 font-bold" :disabled="busy || !chat.retention_days"
              @click="run(async () => { const d = (await api.POST('/admin/chat/prune')).data!; chat = d; notice = t('حُذفت {v0} رسالة قديمة.', { v0: d.deleted ?? 0 }) })">{{ $t('احذف القديمة الآن') }}</button>
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
    <ConfirmDangerDialog :open="purging" title="مسح النصوص التجريبية" expected="امسح" action="امسحها نهائياً" :busy="busy"
      text="تُحذف الإعلانات التجريبية ونسخها من صناديق المدربين، وإعلانات المكافأة التجريبية. ولا يُمس غيرها." @close="purging = false" @confirm="purgeJunk" />
  </div>
</template>
