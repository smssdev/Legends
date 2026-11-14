<template>
  <!-- [Sprint 56 W7] Match.html: the picture fills the screen and the score shows once (on the picture); a thin bar over
       it; the coach's commands in a drawer from one edge, the chat, the momentum and the stats from the other.
       [Sprint 57 W1, W2] The page only wires its parts: the state and the pace in match/use*.ts, the panels in
       components/match/. -->
  <main class="match-root">
    <!-- [Sprint 63 G2] Into the pitch's world: a curtain in the two shirts, parting. -->
    <MatchCurtain v-if="view" ref="curtain" :home="feedKits.home.kit" :away="feedKits.away.kit" />
    <!-- [Sprint 43 W3] Sideways on a phone: upright, it asks to turn (and locks it on Android). -->
    <TurnPhone v-if="view" />
    <p class="sr-only" role="status" aria-live="polite" aria-atomic="true">{{ said }}</p>
    <MatchTopBar :player="P" :live="L" :league="!!league" :seed="view?.seed" :mine-name="mine && view ? view.clubs[mine].name : ''" :settings-open="settingsOpen" @settings="settingsOpen = true" />
    <div class="match-notices">
      <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-danger">{{ $t(error) }}</p>
      <p v-if="oldEngine" class="flex flex-wrap items-center gap-2 rounded-lg bg-surface px-4 py-2 text-sm text-text-soft" role="status">
        <span class="flex-1">{{ replayExpired ? $t('بدأت جولة جديدة، فلم تعد إعادة هذه المباراة متاحة. تبقى نتيجتها وملخصها السريع.') : $t('لُعبت هذه المباراة بنسخة أقدم من المحرك، فلا تُعاد محاكاتها. شاهد ملخصها السريع.') }}</span>
        <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold" @click="recapOpen = true"><Icon name="bolt" :size="16" class="inline-block align-[-3px]" /> {{ $t('الملخص السريع') }}</button>
      </p>
      <p v-if="viewing.chosenView.value === 'unity' && viewing.playing.value === 'cartoon'" class="rounded-lg bg-surface px-4 py-2 text-sm text-text-soft" role="status">{{ $t('المحاكي المطوّر (Unity) قريباً. تُعرض المباراة الآن بالمحاكي الكرتوني بنفس التوقيت.') }}</p>
    </div>

    <div v-if="view" class="match-stage">
      <section class="relative size-full overflow-hidden bg-bg-deep" :aria-label="$t('المباراة')">
        <MatchFeed ref="pitch" :kits="feedKits" :clubs="clubs" :codes="{ home: view.clubs.home.code, away: view.clubs.away.code }" :logos="{ home: view.clubs.home.logo, away: view.clubs.away.logo }" :strength="{ home: view.clubs.home.strength ?? 0, away: view.clubs.away.strength ?? 0 }" :coaches="view.coaches" :countdown="L.countdown.value" :teams="teams" :seed="view.seed" :kickoff="view.kickoff_at" :looks="view.coach_looks" :speed="live ? 1 : speed" :minute="minuteText" :score="score" :mine="mine" :lang="audio.commentary.value" :intro="intro" :live="live" @cue="P.onCue" @sound="audio.onSound" @say="(line: any) => audio.voice.say(line)" @near="(c: any) => audio.sound.near(c)" @intro-done="P.endIntro" />
        <EmergencySub v-if="L.injuredId.value && live && league && !finished" :injured-name="L.injuredName.value" :left="P.halftimeLeft.value" :bench="L.benchForInjury.value" @pick="L.emergencySub" />
        <HalftimeCard :player="P" :live="L" :league="!!league" :id="id" :mine="mine" :key-count="replay.keyTicks.length" @coach="drawer = 'coach'" @recap="recapOpen = true" />
        <GoalReplay v-if="replayTick" :key="replayTick.tick" :tick="replayTick" :players="playersById" :clubs="clubs" :tag="replay.replayMissed.value ? $t('فاتك · {v0}', { v0: replayTick.minute[0] + `'` }) : undefined" @done="replay.nextReplay" />
        <!-- [E8.5] Back after a gap (a hidden tab, a lost connection, joining late): now, with what was missed. -->
        <button v-if="caught" type="button" class="absolute inset-x-3 top-24 z-30 flex min-h-touch flex-col items-center justify-center gap-0.5 rounded-lg bg-surface-raised/95 px-3 py-2 text-center text-sm font-bold" role="status" @click="caught = null">
          <span>{{ $t('عدت إلى الوقت الحالي: فاتتك {v0} دقيقة', { v0: caught.minutes }) }}</span>
          <span v-if="caught.goals.length || caught.reds.length" class="text-xs text-text-muted">
            <span v-for="(g, i) in caught.goals" :key="'g' + i" class="me-2"><Icon name="ball" :size="16" class="inline-block align-[-3px]" /> {{ g.minute }}' {{ $nm(P.clubName(g.team)) }}</span>
            <span v-for="(r, i) in caught.reds" :key="'r' + i" class="me-2"><Icon name="card" :size="16" class="inline-block align-[-3px] text-danger" /> {{ r.minute }}' {{ $nm(P.clubName(r.team)) }}</span>
          </span>
        </button>
        <p v-if="L.offline.value" class="absolute inset-x-3 top-24 z-30 rounded-lg bg-warning/90 px-3 py-2 text-center text-sm font-bold text-bg-deep" role="status">{{ $t('انقطع الاتصال، نعيد المحاولة... ولن يفوتك شيء') }}</p>
      </section>
      <!-- [Sprint 26 W6] The coaches on the touchline, each in his own look, feeling the minute as the server says. -->
      <div v-if="view.coach_looks && Object.keys(view.coach_looks).length" class="match-looks pointer-events-none flex items-end justify-between gap-2 px-1" :aria-label="$t('المدربان على الخط')">
        <template v-for="s in (['home', 'away'] as const)" :key="s">
          <span v-if="view.coach_looks[s]" class="flex items-end gap-1" :class="s === 'away' ? 'flex-row-reverse text-end' : ''">
            <Character :model="view.coach_looks[s]!" :mood="moods[s]" three class="w-16 md:w-20" :label="$t('مدرب {v0}', { v0: $nm(view.clubs[s].name) })" />
            <small class="max-w-[8rem] truncate pb-2 text-xs text-text-muted"><bdi>{{ view.coaches?.[s] ?? $nm(view.clubs[s].name) }}</bdi></small>
          </span>
          <span v-else />
        </template>
      </div>
      <!-- [Sprint 64 W1] The new coach's first match: the assistant at its three moments, a skip, then a club. -->
      <IntroCoach v-if="introMatch.on.value" :current="introMatch.current.value" :over="introMatch.over.value" @answer="introMatch.answer" @coach="drawer = 'coach'" @skip="introMatch.skip" />
      <!-- [Sprint 64 W6] A league match before its whistle: the waiting room, gone by itself at kick-off. -->
      <WaitingRoom v-if="live && league && !started && !finished" :view="view" @chat="drawer = 'more'" />
      <LiveStart v-if="live && !started && mine" :live="L" :other-name="view.clubs[mine === 'away' ? 'home' : 'away'].name" />
    </div>

    <!-- The two drawers, each from its edge, over the picture (never moving it). -->
    <template v-if="view">
      <button v-if="!rerun" type="button" class="match-edge is-end" :aria-expanded="drawer === 'coach'" @click="drawer = drawer === 'coach' ? null : 'coach'"><Icon name="todo" :size="16" class="inline-block align-[-3px]" /><span>{{ $t('الأوامر') }}</span></button>
      <button type="button" class="match-edge is-start" :aria-expanded="drawer === 'more'" @click="drawer = drawer === 'more' ? null : 'more'"><Icon name="chat" :size="16" class="inline-block align-[-3px]" /><span>{{ $t('الدردشة') }}</span><i v-if="social.chat.value.length" class="match-dot" /></button>
      <MatchDrawer side="end" label="لوحة المدرب" :open="drawer === 'coach'" @close="drawer = null">
        <CoachDrawer v-if="!rerun" :player="P" :orders="orders" :view="view" :mine="mine" :league="!!league" :can-change="canChange" :next-window="nextWindow" :readings="L.readings.value" @choose="(s) => (chosen = s)" />
      </MatchDrawer>
      <MatchDrawer side="start" label="الدردشة والمجريات" :open="drawer === 'more'" @close="drawer = null">
        <nav v-if="orders.others.value.length > 1" class="flex flex-wrap items-center gap-2" :aria-label="$t('مبارياتك المباشرة')">
          <span class="text-sm text-text-muted">{{ $t('مبارياتك الآن:') }}</span>
          <RouterLink v-for="o in orders.others.value" :key="o.id" :to="{ name: 'league-match', params: { id: o.id } }" class="flex h-touch items-center rounded-md px-3 font-numbers text-sm" :class="String(o.id) === id ? 'bg-gold text-on-gold' : 'bg-surface'" :aria-current="String(o.id) === id ? 'page' : undefined" dir="ltr">{{ o.home }} - {{ o.away }}</RouterLink>
        </nav>
        <MatchChat :social="social" :player="P" :view="view" :mine="mine" :league="!!league" />
        <FeedList :player="P" :view="view" :home-color="feedKits.home.kit" :dev="dev" />
      </MatchDrawer>
    </template>

    <MatchSettings :open="settingsOpen" :audio="audio" :admin="!league && auth.user?.role === 'admin'" v-model:dev="dev" @close="settingsOpen = false" />
    <MatchRecap v-if="recapOpen" :match-id="Number(id)" :watch="false" @close="recapOpen = false" />
    <!-- [Sprint 30 G3] The first live matches, taught as they happen by the Assistant Coach. -->
    <FirstMatchTips :active="!!(live && league && mine)" :started="started && minute[0] > 0" :window-on="windowOn" :halftime="halftime" :conceded="mine ? score[mine === 'home' ? 'away' : 'home'] : 0" :finished="finished" />
  </main>
</template>

<script setup lang="ts">
import MatchCurtain from '../components/match/MatchCurtain.vue'
import Icon from '../components/Icon.vue'
import { computed, onActivated, onBeforeUnmount, onDeactivated, onMounted, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import { scoreText } from '../lib/format'
import { nm } from '../lib/names'
import { t } from '../lib/i18n'
import { useAuth } from '../stores/auth'
import { useBroadcast } from '../stores/broadcast'
import { leagueMatch, seats, sim, type Side } from '../api/sim'
import TurnPhone from '../components/match/TurnPhone.vue'
import FirstMatchTips from '../components/match/FirstMatchTips.vue'
import IntroCoach from '../components/match/IntroCoach.vue'
import { useIntroMatch } from '../match/useIntroMatch'
import MatchTopBar from '../components/match/MatchTopBar.vue'
import MatchDrawer from '../components/match/MatchDrawer.vue'
import CoachDrawer from '../components/match/CoachDrawer.vue'
import MatchChat from '../components/match/MatchChat.vue'
import FeedList from '../components/match/FeedList.vue'
import HalftimeCard from '../components/match/HalftimeCard.vue'
import EmergencySub from '../components/match/EmergencySub.vue'
import LiveStart from '../components/match/LiveStart.vue'
import WaitingRoom from '../components/match/WaitingRoom.vue'
import MatchSettings from '../components/match/MatchSettings.vue'
import Character from '../components/characters/Character.vue'
import MatchRecap from '../components/shell/MatchRecap.vue'
import MatchFeed from '../match/feed/MatchFeed.vue'
import GoalReplay from '../match/feed/GoalReplay.vue'
import { useViewing } from '../match/viewing'
import { useMatchAudio } from '../match/useMatchAudio'
import { useMatchClock } from '../match/useMatchClock'
import { useWakeLock } from '../match/useWakeLock'
import { useMatchAnnouncer } from '../match/useMatchAnnouncer'
import { useReplay } from '../match/useReplay'
import { useCoachOrders } from '../match/useCoachOrders'
import { useMatchSocial } from '../match/useMatchSocial'
import { useMatchPlayer, type Pitch } from '../match/useMatchPlayer'
import { useLiveMatch } from '../match/useLiveMatch'

// league: a league match from /api/v1/matches (Sprints 18 to 20), played by the server's clock: the coach's orders,
// the server's commentary, his assistant's readings, and catching up after a lost connection.
const props = defineProps<{ id: string; league?: boolean }>()
const auth = useAuth()
const route = useRoute()
const router = useRouter()
const viewing = useViewing()
const broadcast = useBroadcast()
const league = !!props.league

const pitch = ref<Pitch>()
const audio = useMatchAudio()
const replay = useReplay()
const clock = useMatchClock()
const P = useMatchPlayer({ id: props.id, league, pitch, audio, replay, orders: () => orders, speed: Number(route.query.speed) || 1 })
const { view, teams, score, minute, error, speed, halftime, windowOn, started, finished, rerun, oldEngine, replayExpired, intro, moods, live, minuteText } = P

// Who this screen coaches: live, only the seat this device holds (the server checks every order); else the side set
// to «me» (or the one chosen when both are).
const chosen = ref<Side | null>(null)
const mine = computed<Side | null>(() => {
  const c = view.value?.control
  if (!c) return null
  if (view.value?.mode === 'live') return view.value.you
  if (c.home === 'me' && c.away === 'me') return chosen.value ?? 'home'
  return c.home === 'me' ? 'home' : c.away === 'me' ? 'away' : null
})
const orders = useCoachOrders({ league, id: props.id, mine, teams, finished, error })
const social = useMatchSocial({
  league, id: props.id, mine,
  show: (side, emoji, text, who) => pitch.value?.react(side, emoji, text, who),
  sideName: (side) => view.value?.coaches?.[side] ?? view.value?.clubs[side].name ?? '',
  pop: () => audio.sound.pop(),
})
// [Sprint 65 W7] What matters in the picture, said to a screen reader as it lands (the region under the stage).
const { said } = useMatchAnnouncer({
  feed: P.feed, score, windowOn, skipping: P.skipping,
  scoreWord: (h, a) => (view.value ? `${nm(view.value.clubs.home.name)} ${h} - ${a} ${nm(view.value.clubs.away.name)}` : `${h}-${a}`),
  windowWord: () => t('فترة التوقف: يمكنك تغيير التشكيلة والتكتيك الآن'),
})
const wake = useWakeLock(() => live.value && !finished.value && !broadcast.away)
const L = useLiveMatch({ id: props.id, league, player: P, pitch, clock, social: () => social, orders: () => orders, replay, mine, awake: { keep: wake.keep }, hush: () => { if (!audio.soundOn.value) audio.voice.stop() } })
const { caught } = L
// [Sprint 64 W1] Only for the match /intro made (its moments kept on this device).
const introMatch = useIntroMatch({ id: props.id, minute: computed(() => minute.value[0]), finished, done: () => sim.introFinished() })

const drawer = ref<'coach' | 'more' | null>(null)
const settingsOpen = ref(false)
const recapOpen = ref(false)
const dev = ref(false)
const replayTick = replay.replayTick
const clubs = computed(() => ({ home: view.value?.clubs.home.name ?? '', away: view.value?.clubs.away.name ?? '' }))
const playersById = computed(() => {
  const m: Record<number, { name: string; no: number; side: Side }> = {}
  for (const side of ['home', 'away'] as const) for (const p of teams.value[side]?.players ?? []) m[p.id] = { name: p.name, no: p.no, side }
  return m
})
// [Sprint 57 B1, W7] The kits come worked out from the server (App\Data\MatchKits), the same as the app's and Unity's.
const NO_KIT = { shirt: '#163360', trim: '#F7F4EA', shorts: '#163360', socks: '#163360', text: '#FFFFFF', gk: '#2E8B57', pattern: null }
const feedKits = computed(() => {
  const k = (side: Side) => view.value?.kits?.[side] ?? NO_KIT
  // [X76] And each club's kit pattern, drawn in its trim colour.
  const kit = (side: Side) => ({ kit: k(side).shirt, ink: k(side).text, trim: k(side).trim, name: view.value?.clubs[side].name ?? '', pattern: k(side).pattern })
  return { home: kit('home'), away: kit('away') }
})
// [X42] Live, the coach changes only in a window (and before kick-off, at half-time); its countdown's last 2 s are shut.
const windows = computed(() => (live.value ? view.value?.timing.windows ?? [] : []))
const canChange = computed(() => !windows.value.length || !started.value || minute.value[0] === 0 || halftime.value || (windowOn.value && P.halftimeLeft.value > 2))
const nextWindow = computed(() => [...windows.value, 45].sort((a, b) => a - b).find((w) => w > minute.value[0]) ?? null)

// [Sprint 64 W7] A coach's window opens his drawer by itself (its countdown inside), and its end closes it; a drawer
// he opened himself between windows is left as it is.
let openedByWindow = false
watch(windowOn, (on) => {
  if (!live.value || !league || !mine.value || rerun.value) return
  if (on && drawer.value !== 'coach') { drawer.value = 'coach'; openedByWindow = true }
  else if (!on && openedByWindow) { if (drawer.value === 'coach') drawer.value = null; openedByWindow = false }
})

// [Sprint 63 G2] Back to the management's world: the curtain closes first (420ms), then the page goes.
const curtain = ref<InstanceType<typeof MatchCurtain> | null>(null)
onBeforeRouteLeave(async () => {
  await curtain.value?.close()
})

onMounted(async () => {
  // A friend's link carries his seat once: keep it on this device and take it out of the address.
  const linkSeat = route.query.seat
  if (typeof linkSeat === 'string' && linkSeat) {
    seats.set(props.id, linkSeat)
    router.replace({ query: { ...route.query, seat: undefined } })
  }
  orders.loadQuick()
  orders.loadOthers()
  document.addEventListener('visibilitychange', L.onVisible)
  window.addEventListener('online', L.onVisible)
  try {
    const v = (view.value = await (league ? leagueMatch : sim).show(props.id))
    teams.value = v.teams
    audio.voice.prepare([v.clubs.home.name, v.clubs.away.name])
    score.value = v.score
    orders.adopt(true)
    finished.value = v.finished
    await P.begin()
    if (live.value) await L.begin()
  } catch (e) {
    error.value = (e as Error).message
  }
})

// [X41] The broadcast behind the other screens: this page stays alive (KeepAlive in App.vue) and tells the shell's bar
// the score and the minute; the bar brings the coach back or mutes it. A finished match leaves the bar soon after.
const ownPath = route.path
let endTimer = 0
watch(() => [view.value, score.value.home, score.value.away, minuteText.value, finished.value] as const, () => {
  if (!view.value) return
  broadcast.update({
    path: ownPath,
    title: `${nm(view.value.clubs.home.name)} - ${nm(view.value.clubs.away.name)}`,
    score: scoreText(score.value.home, score.value.away),
    minute: finished.value ? t('نهاية المباراة') : minuteText.value,
    live: !finished.value,
  })
  // [Sprint 57 W6, W-B07] One timer for the end of the broadcast.
  window.clearTimeout(endTimer)
  if (finished.value) endTimer = window.setTimeout(() => { if (broadcast.away && finished.value) broadcast.end() }, 20000)
}, { immediate: true })
// [X74] Kept behind the other screens only while live; a recorded match closes on leaving. Behind them the screen may
// sleep: the wake lock is let go, and asked again on the way back.
watch(live, (on) => { broadcast.keep = on }, { immediate: true })
watch(finished, (done) => { if (done) wake.release() })
onActivated(() => { broadcast.away = false; broadcast.keep = live.value; wake.keep() })
onDeactivated(() => { broadcast.away = !finished.value; wake.release() })
watch(() => broadcast.muteAsk, () => { if (audio.soundOn.value) audio.toggleSound() })

onBeforeUnmount(() => {
  window.clearTimeout(endTimer)
  broadcast.end()
  document.removeEventListener('visibilitychange', L.onVisible)
  window.removeEventListener('online', L.onVisible)
  orders.dispose()
  social.dispose()
  L.dispose()
  P.dispose()
  wake.release()
  audio.dispose()
})
</script>

<style scoped>
/* [Sprint 56 W7] The match fills the screen: the picture under a thin bar, the drawers over it. */
.match-root { position: relative; display: grid; height: 100dvh; grid-template-rows: auto minmax(0, 1fr); overflow: hidden; background: var(--color-broadcast-tv-deep); }
.match-notices { position: absolute; inset-inline: var(--space-sm); top: 3rem; z-index: 44; display: flex; flex-direction: column; gap: var(--space-xs); }
.match-stage { position: relative; min-height: 0; }
.match-looks { position: absolute; inset-inline: 3.5rem; bottom: var(--space-xs); z-index: 5; }
.match-edge { position: absolute; z-index: 46; top: 50%; display: flex; width: var(--spacing-touch); flex-direction: column; align-items: center; gap: 2px; padding: var(--space-sm) 0; transform: translateY(-50%); font-size: var(--text-title); color: var(--color-broadcast-white); background: color-mix(in srgb, var(--color-broadcast-tv) 88%, transparent); }
.match-edge span { font-size: var(--text-caption); writing-mode: vertical-rl; }
.match-edge.is-end { inset-inline-end: 0; border-start-start-radius: var(--radius-lg); border-end-start-radius: var(--radius-lg); }
.match-edge.is-start { inset-inline-start: 0; border-start-end-radius: var(--radius-lg); border-end-end-radius: var(--radius-lg); }
.match-dot { position: absolute; top: 4px; width: 8px; height: 8px; border-radius: 50%; background: var(--color-live); }
</style>
