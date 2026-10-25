<script setup lang="ts">
// Training (Sprint 27 W1, PLAN 2.8), per the WebTraining and MobileTraining drafts: the four slots with their
// bars and the countdown to the next session, and the candidates of the chosen line. Every number comes from
// the server; the countdown reloads when a session is due. "Finish now" waits for the premium coins.
import { useGlossary } from '../../lib/glossary'
import HelpTip from '../../components/ui/HelpTip.vue'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'
import LineBadge from '../../components/ui/LineBadge.vue'
import PriceTag from '../../components/ui/PriceTag.vue'
import { useWallet } from '../../stores/wallet'
import { currentLeague } from '../../lib/currentLeague'
import { count, money, type Line } from '../../lib/format'

type View = components['schemas']['TrainingView']
// The "?" texts [X19].
const g = useGlossary()
const leagueId = ref<number | null>(null)
const v = ref<View | null>(null)
const loaded = ref(false)
const error = ref('')
const notice = ref('')
const busy = ref(false)
const line = ref<Line>('mid')
const now = ref(Date.now())
let skew = 0   // the game clock minus this device's clock (clock:travel in development)
let tick = 0
const LINE_NAMES: Record<string, string> = { gk: 'حارس', def: 'دفاع', mid: 'وسط', att: 'هجوم' }
const candidates = computed(() => {
  const busyIds = new Set(v.value?.slots.map((s) => s.player?.id))
  return (v.value?.players ?? []).filter((p) => p.line === line.value && !busyIds.has(p.id))
    .sort((a, b) => Number(a.maxed) - Number(b.maxed) || (b.potential - b.overall) - (a.potential - a.overall) || a.age - b.age)
})
function left(at: string | null | undefined) {
  if (!at) return ''
  const s = Math.max(0, Math.floor((new Date(at).getTime() - now.value) / 1000))
  return [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
}

async function load() {
  try {
    leagueId.value ??= await currentLeague()
    if (leagueId.value) {
      const { data } = await api.GET('/leagues/{league}/training', { params: { path: { league: leagueId.value } } })
      v.value = data!
      skew = new Date(data!.now).getTime() - Date.now()
      now.value = Date.now() + skew
    }
  } catch (e) {
    error.value = asApiError(e).message
  }
  loaded.value = true
}

async function act(run: () => Promise<{ data?: View }>, done: string) {
  busy.value = true
  error.value = notice.value = ''
  try {
    await ensureCsrf()
    const { data } = await run()
    v.value = data!
    notice.value = done
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}

// The camp (docs/features/camp.md) and secret training (docs/features/secret-training.md).
const LEVEL_NAMES: Record<string, string> = { basic: 'عادي', good: 'جيد', elite: 'ممتاز' }
const pick = ref<number[]>([])
const level = ref<'basic' | 'good' | 'elite'>('good')
const days = ref(1)
const campActive = computed(() => v.value?.camp.current?.status === 'active')
const campPrice = computed(() => (v.value?.camp.levels.find((l) => l.level === level.value)?.day_price ?? 0) * pick.value.length * days.value)
const nameOf = (id: number) => v.value?.players.find((p) => p.id === id)?.name ?? ''
function toggle(id: number) {
  const i = pick.value.indexOf(id)
  if (i >= 0) pick.value.splice(i, 1)
  else if (pick.value.length < (v.value?.camp.max_players ?? 5)) pick.value.push(id)
}
const sendCamp = () => act(() => api.POST('/leagues/{league}/training/camp', { params: { path: { league: leagueId.value! } },
  body: { player_ids: pick.value, level: level.value, days: days.value, idempotency_key: crypto.randomUUID() } }) as any, 'سافر اللاعبون إلى المعسكر.').then(() => { if (!error.value) pick.value = [] })
const secret = (l: Line) => act(() => api.POST('/leagues/{league}/training/secret', { params: { path: { league: leagueId.value! } }, body: { line: l } }) as any,
  `تم: ${LINE_NAMES[l]} +${v.value?.secret.boost} في المباراة القادمة، والخصم لا يعرف.`).then(() => wallet.load())

// Finish a session now for coins [Sprint 34].
const wallet = useWallet()
const finish = (l: string) => act(() => api.POST('/leagues/{league}/training/{line}/finish', { params: { path: { league: leagueId.value!, line: l as Line } } }) as any,
  'انتهت الجلسة الآن.').then(() => wallet.load())

const train = (id: number, name: string) => act(() => api.POST('/leagues/{league}/training', { params: { path: { league: leagueId.value! } }, body: { player_id: id } }) as any,
  `بدأ ${name} التدريب. أول جلسة بعد ${Math.round((v.value?.interval_minutes ?? 0) / 60)} ساعات.`)
const stop = (l: string) => act(() => api.DELETE('/leagues/{league}/training/{line}', { params: { path: { league: leagueId.value!, line: l as Line } } }) as any,
  'فرغت الخانة، واللاعب يحتفظ بتقدمه.')

onMounted(() => {
  load()
  tick = window.setInterval(() => {
    now.value = Date.now() + skew
    if (v.value?.slots.some((s) => s.next_at && new Date(s.next_at).getTime() <= now.value - 2000)
      || (campActive.value && new Date(v.value!.camp.current!.ends_at).getTime() <= now.value - 2000)) load()
  }, 1000)
})
onBeforeUnmount(() => clearInterval(tick))
</script>

<template>
  <div class="flex flex-col gap-4">
    <header class="flex flex-wrap items-end gap-3">
      <div class="flex-1">
        <span class="flex flex-wrap items-center gap-1"><h1 class="font-display text-3xl font-extrabold">التدريب</h1><HelpTip :text="g.training" label="التدريب" /></span>
        <p class="mt-1 text-sm text-text-muted">لاعب من كل خط · جلسة كل {{ v ? Math.round(v.interval_minutes / 60) : 8 }} ساعات حتى لو كنت غائباً · عند 100% القوة +1 · التدريب مفتوح طوال الموسم: بعد الإمكانية أبطأ، حتى 99</p>
      </div>
      <div v-if="v" class="rounded-lg bg-surface px-4 py-2 text-end">
        <span class="block text-xs text-text-muted">أموال النادي</span>
        <b class="font-numbers text-xl" dir="ltr">{{ money(v.balance) }}</b>
        <span class="block text-xs text-text-muted">الجلسة <span class="font-numbers" dir="ltr">{{ count(v.cost) }}</span></span>
      </div>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ error }}</p>
    <p v-if="notice" class="rounded-lg bg-success/15 px-4 py-3 text-sm text-success" role="status">{{ notice }}</p>
    <p v-if="!loaded" class="text-text-muted">جارٍ التحميل...</p>
    <p v-else-if="!leagueId" class="rounded-xl bg-surface p-6 text-text-muted">ليس لديك فريق بعد. <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">دورياتي</RouterLink></p>

    <template v-else-if="v">
      <p v-if="v.balance < v.cost" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">رصيد النادي لا يكفي جلسة، فالجلسات تفوت حتى يرجع الرصيد.</p>

      <section aria-label="خانات التدريب" class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <article v-for="s in v.slots" :key="s.line" class="flex flex-col gap-3 rounded-xl p-4" :class="s.player ? 'border border-gold/40 bg-surface' : 'border border-dashed border-white/15 bg-surface/50'">
          <div class="flex items-center gap-2">
            <LineBadge :line="s.line as Line" />
            <span class="text-sm text-text-muted">خانة {{ LINE_NAMES[s.line] }}</span>
            <span v-if="s.player" class="ms-auto font-numbers text-sm text-gold" dir="ltr" aria-label="الجلسة التالية بعد">{{ left(s.next_at) }}</span>
          </div>
          <template v-if="s.player">
            <div class="flex items-center gap-3">
              <span class="min-w-0 flex-1"><b class="block truncate"><bdi>{{ s.player.name }}</bdi></b>
                <span class="text-xs text-text-muted">{{ s.player.position }} · {{ s.player.age }} سنة · الإمكانية {{ s.player.potential }}</span></span>
              <span class="text-center"><b class="block font-numbers text-2xl">{{ s.player.overall }}</b><span class="font-numbers text-xs text-success" dir="ltr">→ {{ s.player.overall + 1 }}</span></span>
            </div>
            <div>
              <div class="flex justify-between text-xs text-text-muted"><span>التقدم</span><span class="font-numbers" dir="ltr">{{ s.player.progress }}%</span></div>
              <div class="mt-1 h-2 overflow-hidden rounded-full bg-surface-sunk" role="progressbar" :aria-valuenow="s.player.progress" aria-valuemin="0" aria-valuemax="100">
                <div class="h-full rounded-full bg-gold transition-all" :style="{ width: s.player.progress + '%' }" />
              </div>
              <p class="mt-1 text-xs text-text-muted">حوالي {{ s.player.sessions }} جلسة للـ +1 · {{ s.sessions_done }} جلسة حتى الآن</p>
            </div>
            <div class="flex gap-2">
              <button type="button" class="h-touch flex-1 rounded-md bg-surface-sunk px-3 text-sm font-bold" @click="line = s.line as Line">اختر لاعباً آخر</button>
              <button v-if="wallet.open(leagueId)" type="button" class="flex h-touch items-center gap-1 rounded-md bg-gold/15 px-3 text-sm font-bold text-gold" :disabled="busy" @click="finish(s.line)"
                title="أنهِ الجلسة الآن">الآن · <PriceTag :amount="wallet.price('finish_training')" currency="coins" /></button>
              <button type="button" class="h-touch rounded-md px-3 text-sm text-text-muted hover:text-text" :disabled="busy" @click="stop(s.line)">إفراغ</button>
            </div>
          </template>
          <template v-else>
            <p class="text-sm text-text-muted">الخانة فارغة.</p>
            <button type="button" class="h-touch rounded-md bg-gold px-3 font-bold text-on-gold" @click="line = s.line as Line">اختر لاعباً</button>
          </template>
        </article>
      </section>

      <section aria-label="مرشحون للتدريب" class="flex flex-col gap-2 rounded-xl bg-surface p-3">
        <div class="flex flex-wrap items-center gap-2 px-1">
          <span class="flex flex-wrap items-center gap-1"><h2 class="font-display text-lg font-bold">مرشحون للتدريب</h2><HelpTip :text="g.potential" label="الإمكانية" /></span>
          <span class="text-sm text-text-muted">الأصغر سناً يتطور أسرع وسقفه أعلى</span>
          <div class="ms-auto flex gap-1" role="tablist" aria-label="الخط">
            <button v-for="(n, k) in LINE_NAMES" :key="k" type="button" role="tab" :aria-selected="line === k" class="h-touch rounded-md px-3 text-sm font-bold"
              :class="line === k ? 'bg-gold text-on-gold' : 'bg-surface-sunk text-text-muted'" @click="line = k as Line">{{ n }}</button>
          </div>
        </div>
        <div class="hidden grid-cols-[1fr_3rem_3rem_3rem_5rem_6rem] gap-2 px-2 text-xs text-text-muted sm:grid">
          <span>اللاعب</span><span class="text-center">السن</span><span class="text-center">القوة</span><span class="text-center">السقف</span><span class="text-center">جلسات للـ +1</span><span />
        </div>
        <div v-for="p in candidates" :key="p.id" class="grid grid-cols-[1fr_3rem_6rem] items-center gap-2 rounded-lg bg-surface-sunk px-2 py-2 sm:grid-cols-[1fr_3rem_3rem_3rem_5rem_6rem]">
          <span class="min-w-0"><b class="block truncate"><bdi>{{ p.name }}</bdi></b><span class="text-xs text-text-muted">{{ p.position }}<template v-if="p.progress"> · التقدم {{ p.progress }}%</template><template v-if="p.injured"> · مصاب</template><span class="sm:hidden"> · {{ p.age }} سنة · الإمكانية {{ p.potential }}</span></span></span>
          <span class="hidden text-center font-numbers sm:block">{{ p.age }}</span>
          <span class="text-center font-numbers text-lg">{{ p.overall }}</span>
          <span class="hidden text-center font-numbers sm:block" :class="p.over_potential ? 'text-warning' : 'text-success'" :title="p.over_potential ? 'تجاوز إمكانيته: يتطور أبطأ، حتى 99' : undefined">{{ p.potential }}</span>
          <span class="hidden text-center font-numbers text-text-muted sm:block">~{{ p.sessions }}</span>
          <span v-if="p.in_camp" class="text-center text-xs text-gold">في المعسكر</span>
          <button v-else-if="!p.maxed" type="button" class="h-touch rounded-md bg-gold px-3 text-sm font-bold text-on-gold disabled:opacity-40" :disabled="busy" @click="train(p.id, p.name)">درّب</button>
          <span v-else class="text-center text-xs text-text-muted">بلغ سقفه</span>
        </div>
        <p v-if="!candidates.length" class="px-1 text-sm text-text-muted">لا لاعبين آخرين في هذا الخط.</p>
      </section>

      <div class="grid gap-3 lg:grid-cols-2">
        <section aria-label="معسكر التدريب" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
          <div><span class="flex flex-wrap items-center gap-1"><h2 class="font-display text-lg font-bold">معسكر التدريب</h2><HelpTip :text="g.camp" label="معسكر التدريب" /></span>
            <p class="text-sm text-text-muted">حتى {{ v.camp.max_players }} لاعبين يتدربون معاً، ويغيبون عن المباريات حتى يعودوا. يبقى {{ v.camp.min_left }} لاعباً على الأقل في الفريق.</p></div>
          <template v-if="campActive">
            <div class="flex items-center gap-3 rounded-lg border border-gold/40 bg-surface-sunk p-3">
              <span class="flex-1"><b class="block">معسكر {{ LEVEL_NAMES[v.camp.current!.level] }}</b><span class="text-xs text-text-muted">{{ v.camp.current!.sessions_done }} من {{ v.camp.current!.sessions }} جلسات</span></span>
              <span class="text-end"><span class="block text-xs text-text-muted">العودة بعد</span><b class="font-numbers text-gold" dir="ltr">{{ left(v.camp.current!.ends_at) }}</b></span>
            </div>
            <div v-for="c in v.camp.current!.players" :key="c.id" class="flex items-center gap-2 px-1 text-sm">
              <span class="flex-1 truncate"><bdi>{{ nameOf(c.id) }}</bdi></span>
              <span class="font-numbers text-text-muted" dir="ltr">{{ v.players.find((p) => p.id === c.id)?.progress ?? 0 }}%</span>
              <span v-if="c.gain" class="font-numbers text-success" dir="ltr">+{{ c.gain }}</span>
            </div>
          </template>
          <template v-else>
            <p v-if="v.camp.current" class="rounded-lg bg-surface-sunk px-3 py-2 text-sm text-text-muted">آخر معسكر: {{ v.camp.current.players.map((c) => `${nameOf(c.id)} ${c.gain ? '+' + c.gain : ''}`).join('، ') }}</p>
            <div class="flex flex-wrap gap-2" role="group" aria-label="الدرجة">
              <button v-for="l in v.camp.levels" :key="l.level" type="button" class="h-touch flex-1 rounded-md px-3 text-sm font-bold"
                :class="level === l.level ? 'bg-gold text-on-gold' : 'bg-surface-sunk text-text-muted'" @click="level = l.level">
                {{ LEVEL_NAMES[l.level] }} · ×{{ l.gain_bp / 10000 }}</button>
            </div>
            <label class="flex items-center gap-3 text-sm text-text-muted">الأيام
              <input v-model.number="days" type="range" :min="v.camp.days[0]" :max="v.camp.days[1]" class="flex-1 accent-gold" />
              <b class="font-numbers text-text">{{ days }}</b></label>
            <div class="flex flex-wrap gap-1.5" aria-label="اختر اللاعبين">
              <button v-for="p in v.players.filter((p) => !p.maxed)" :key="p.id" type="button" class="min-h-touch rounded-full px-3 text-xs"
                :class="pick.includes(p.id) ? 'bg-gold font-bold text-on-gold' : 'bg-surface-sunk text-text-muted'" :aria-pressed="pick.includes(p.id)" @click="toggle(p.id)">
                <bdi>{{ p.name }}</bdi> {{ p.overall }}</button>
            </div>
            <button type="button" class="h-12 rounded-md bg-gold px-6 font-display font-bold text-on-gold disabled:opacity-40"
              :disabled="busy || !pick.length || campPrice > v.balance" @click="sendCamp">
              أرسل {{ pick.length }} إلى المعسكر · <span class="font-numbers" dir="ltr">{{ money(campPrice) }}</span></button>
          </template>
        </section>

        <section aria-label="التدريب السري" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
          <div><span class="flex flex-wrap items-center gap-1"><h2 class="font-display text-lg font-bold">التدريب السري</h2><HelpTip :text="g.secret_training" label="التدريب السري" /></span>
            <p class="text-sm text-text-muted">خط واحد +{{ v.secret.boost }} في المباراة القادمة وحدها، والخصم لا يعرف. {{ v.secret.used }} من {{ v.secret.per_season }} هذا الموسم.</p></div>
          <p v-if="!v.secret.fixture" class="text-sm text-text-muted">لا مباراة قادمة.</p>
          <template v-else>
            <p class="text-sm">ضد <b><bdi>{{ v.secret.fixture.opponent }}</bdi></b> · القفل بعد <span class="font-numbers text-gold" dir="ltr">{{ left(v.secret.fixture.lock_at) }}</span></p>
            <p v-if="v.secret.fixture.line" class="rounded-lg bg-success/15 px-3 py-2 text-sm text-success">تم: {{ LINE_NAMES[v.secret.fixture.line] }} +{{ v.secret.boost }} في هذه المباراة.</p>
            <p v-else-if="v.secret.fixture.status !== 'scheduled'" class="text-sm text-text-muted">قُفلت التشكيلة.</p>
            <div v-else class="grid grid-cols-2 gap-2">
              <button v-for="(n, k) in LINE_NAMES" :key="k" type="button" class="h-12 rounded-md bg-surface-sunk font-bold disabled:opacity-40"
                :disabled="busy || v.secret.used >= v.secret.per_season || (v.secret.currency === 'money' && v.secret.cost > v.balance)" @click="secret(k as Line)">{{ n }}</button>
            </div>
            <p class="text-xs text-text-muted">الجلسة <PriceTag :amount="v.secret.cost" :currency="v.secret.currency" /></p>
          </template>
        </section>
      </div>

      <section aria-label="منشأة التدريب" class="flex flex-wrap items-center gap-3 rounded-xl bg-surface p-4">
        <div class="flex-1"><b class="block">منشأة التدريب</b><span class="text-sm text-text-muted">كل مرحلة منها تسرّع التقدم في كل الخانات والمعسكر، وتُطوَّر من صفحة الملعب.</span></div>
        <RouterLink :to="{ name: 'stadium' }" class="grid h-touch place-items-center rounded-md bg-surface-sunk px-4 font-bold text-gold">إلى الملعب</RouterLink>
      </section>
    </template>
  </div>
</template>
