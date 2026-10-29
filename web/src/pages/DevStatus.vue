<script setup lang="ts">
// The server's status for developers (moved from the home screen by X18): the server's health and the live test
// (Sprint 9 W1). The home screen is the coach's dashboard (Home.vue).
import { intlLocale } from '../lib/i18n'
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { api, asApiError } from '../api/client'
import { live, liveState } from '../lib/echo'

type Health = { status: string; version: string; min_app_version: string; engine_version: number; time: string; clock_offset: number; broadcast: { channel?: string; event?: string } }

const health = ref<Health | null>(null)
const error = ref('')
const now = ref(Date.now())
let fetchedAt = 0
let serverMs = 0
const ping = ref<'idle' | 'sending' | 'waiting' | 'ok' | 'failed'>('idle')
const pingNote = ref('')
const pingSentAt = ref(0)
const pingMs = ref(0)

const gameTime = computed(() => (health.value ? new Date(serverMs + (now.value - fetchedAt)) : null))
const fmt = (d: Date) => new Intl.DateTimeFormat(intlLocale(), { dateStyle: 'full', timeStyle: 'medium' }).format(d)
const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
const liveLabel = computed(() => ({ connecting: 'يتصل…', connected: 'متصل', unavailable: 'غير متاح', failed: 'غير مدعوم', disconnected: 'منقطع' })[liveState.value])

let timer = 0
onMounted(async () => {
  timer = window.setInterval(() => (now.value = Date.now()), 1000)
  try {
    const { data } = await api.GET('/health')
    health.value = data as Health
    fetchedAt = Date.now()
    serverMs = Date.parse(health.value.time)
  } catch (e) {
    error.value = asApiError(e).message
  }
  const channel = health.value?.broadcast.channel ?? 'system'
  const event = health.value?.broadcast.event ?? 'ping'
  live().channel(channel).listen(`.${event}`, (e: { message: string }) => {
    // The event can arrive before the answer to the POST does.
    if (ping.value !== 'sending' && ping.value !== 'waiting') return
    ping.value = 'ok'
    pingMs.value = Date.now() - pingSentAt.value
    pingNote.value = e.message
  })
})
onBeforeUnmount(() => window.clearInterval(timer))

async function sendPing() {
  ping.value = 'sending'
  pingNote.value = ''
  pingSentAt.value = Date.now()
  try {
    await api.POST('/health/ping')
    if (ping.value === 'sending') ping.value = 'waiting'
    window.setTimeout(() => {
      if (ping.value === 'waiting') {
        ping.value = 'failed'
        pingNote.value = 'أُرسل الحدث ولم يصل. هل خادم البث شغال؟'
      }
    }, 5000)
  } catch (e) {
    ping.value = 'failed'
    pingNote.value = asApiError(e).message
  }
}
</script>

<template>
  <div class="flex flex-col gap-5">
    <div>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('أهلاً في لعبة المدرب الأسطورة') }}</h1>
      <p class="mt-1 text-text-muted">{{ $t('دورياتك، وحالة الخادم، والبث المباشر، والمحاكي.') }}</p>
    </div>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>

    <div class="grid gap-4 md:grid-cols-2">
      <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-server">
        <h2 id="h-server" class="font-display text-xl font-extrabold">{{ $t('الخادم') }}</h2>
        <dl v-if="health" class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm">
          <dt class="text-text-muted">{{ $t('الحالة') }}</dt>
          <dd class="font-bold text-success">{{ $t('يعمل') }}</dd>
          <dt class="text-text-muted">{{ $t('الإصدار') }}</dt>
          <dd class="font-numbers text-base" dir="ltr">{{ health.version }}</dd>
          <dt class="text-text-muted">{{ $t('أقدم تطبيق مدعوم') }}</dt>
          <dd class="font-numbers text-base" dir="ltr">{{ health.min_app_version }}</dd>
          <dt class="text-text-muted">{{ $t('نسخة المحرك') }}</dt>
          <dd class="font-numbers text-base">{{ health.engine_version }}</dd>
          <dt class="text-text-muted">{{ $t('وقت اللعبة') }}</dt>
          <dd>
            <span v-if="gameTime">{{ fmt(gameTime) }}</span>
            <span class="block text-xs text-text-muted">{{ $t('بتوقيت جهازك ({v0})', { v0: zone }) }}</span>
          </dd>
        </dl>
        <p v-else-if="!error" class="text-text-muted">{{ $t('جارٍ التحميل…') }}</p>
        <p v-if="health && health.clock_offset !== 0" class="rounded-lg bg-warning/15 px-3 py-2 text-sm">
          {{ $t('ساعة اللعبة مقدَّمة بـ') }} <span class="font-numbers">{{ Math.round(health.clock_offset / 3600) }}</span> {{ $t('ساعة (') }}<code dir="ltr">clock:travel</code>{{ $t('، للتطوير فقط).') }}
        </p>
      </section>

      <section class="flex flex-col gap-3 rounded-xl bg-surface p-4" aria-labelledby="h-live">
        <div class="flex items-center justify-between">
          <h2 id="h-live" class="font-display text-xl font-extrabold">{{ $t('البث المباشر') }}</h2>
          <span class="flex items-center gap-2 text-sm" role="status">
            <span class="size-2.5 rounded-full" :class="liveState === 'connected' ? 'bg-success' : liveState === 'connecting' ? 'bg-warning' : 'bg-live'" />{{ $t(liveLabel) }}
          </span>
        </div>
        <p class="text-sm text-text-muted">{{ $t('يرسل الخادم حدثاً تجريبياً، ويصل هنا لحظياً كما ستصل أحداث المباريات.') }}</p>
        <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold disabled:opacity-60" :disabled="ping === 'sending' || ping === 'waiting'" @click="sendPing">
          {{ ping === 'sending' || ping === 'waiting' ? $t('ينتظر الحدث…') : $t('جرّب البث') }}
        </button>
        <p v-if="ping === 'ok'" class="rounded-lg bg-success/15 px-3 py-2 text-sm" role="status">
          {{ $t('وصل: {v0} · خلال', { v0: pingNote }) }} <span class="font-numbers">{{ pingMs }}</span> {{ $t('ملّي ثانية') }}
        </p>
        <p v-else-if="ping === 'failed'" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger" role="alert">{{ pingNote }}</p>
      </section>
    </div>

    <RouterLink to="/leagues" class="flex min-h-touch items-center justify-between rounded-xl border border-gold/30 bg-surface p-4 hover:bg-surface-raised">
      <span>
        <span class="block font-display text-lg font-extrabold">{{ $t('دورياتي') }}</span>
        <span class="text-sm text-text-muted">{{ $t('أنشئ دورياً لأصحابك، أو انضم بكود دوري.') }}</span>
      </span>
      <span class="text-gold" aria-hidden="true">‹</span>
    </RouterLink>

    <RouterLink to="/sim" class="flex min-h-touch items-center justify-between rounded-xl bg-surface p-4 hover:bg-surface-raised">
      <span>
        <span class="block font-display text-lg font-extrabold">{{ $t('المحاكي') }}</span>
        <span class="text-sm text-text-muted">{{ $t('مباراة بين أي ناديين حقيقيين، تديرها حية.') }}</span>
      </span>
      <span class="text-gold" aria-hidden="true">‹</span>
    </RouterLink>
  </div>
</template>
