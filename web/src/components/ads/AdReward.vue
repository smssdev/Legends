<script setup lang="ts">
// [Sprint 20 S4] «شاهد إعلاناً»: one of the game's own ads in a window with its countdown; at its end the server
// (which timed the watch itself) cuts the task's time and the page reloads. The button shows the minutes a watch cuts
// and how many of the most are used. No outside network and nothing to install.
import { computed, onBeforeUnmount, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import type { components } from '../../api/schema'

const props = defineProps<{ leagueId: number; item: 'training' | 'stadium'; line?: 'gk' | 'def' | 'mid' | 'att'; ads: components['schemas']['AdStatus'] }>()
const emit = defineEmits<{ done: [] }>()

type Watch = { token: string; ad: { title: string; body: string; cta_label?: string | null; cta_url?: string | null; seconds: number }; ends_at: string }
const watch = ref<Watch | null>(null)
const left = ref(0)
const message = ref('')
const busy = ref(false)
let timer: ReturnType<typeof setInterval> | undefined
const full = computed(() => props.ads.used >= props.ads.max)

async function open() {
  message.value = ''
  busy.value = true
  try {
    await ensureCsrf()
    const { data } = await api.POST('/ads/start')
    watch.value = data as Watch
    tick()
    timer = setInterval(tick, 250)
  } catch (e) {
    message.value = asApiError(e).message
  } finally {
    busy.value = false
  }
}
function tick() {
  if (!watch.value) return
  left.value = Math.max(0, Math.ceil((new Date(watch.value.ends_at).getTime() - Date.now()) / 1000))
}
async function claim() {
  if (!watch.value || left.value > 0) return
  busy.value = true
  try {
    await api.POST('/leagues/{league}/ads/reward', { params: { path: { league: props.leagueId } }, body: { item: props.item, ...(props.line ? { line: props.line } : {}), token: watch.value.token } })
    close()
    emit('done')
  } catch (e) {
    message.value = asApiError(e).message
  } finally {
    busy.value = false
  }
}
function close() {
  clearInterval(timer)
  watch.value = null
}
onBeforeUnmount(() => clearInterval(timer))
</script>

<template>
  <button v-if="ads.enabled" type="button" class="flex h-touch items-center gap-1.5 rounded-md bg-brand/20 px-3 text-sm font-bold text-brand-light disabled:opacity-40" :disabled="busy || full"
    :title="full ? $t('وصلت إلى الحد لهذه المهمة') : $t('شاهد إعلاناً من اللعبة يقلّص الوقت')" @click="open">
    <svg viewBox="0 0 24 24" class="size-5" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="3" /><path d="M10 9l5 3-5 3z" fill="currentColor" /></svg>
    <span>{{ $t('−{v0} د', { v0: ads.minutes }) }}</span><span class="font-numbers text-xs opacity-80" dir="ltr">{{ ads.used }}/{{ ads.max }}</span>
  </button>
  <p v-if="message && !watch" class="basis-full text-xs text-warning" role="status">{{ $t(message) }}</p>
  <Teleport to="body">
    <div v-if="watch" class="fixed inset-0 z-50 grid place-items-center bg-bg-deep/85 p-4" role="dialog" aria-modal="true" :aria-label="$t('إعلان')">
      <div class="flex w-full max-w-md flex-col gap-4 overflow-hidden rounded-2xl border border-gold/40 bg-surface p-6 text-center shadow-2xl">
        <span class="self-center rounded-pill bg-surface-sunk px-3 py-1 text-xs text-text-muted">{{ $t('إعلان من المدرب الأسطورة') }}</span>
        <h2 class="font-display text-2xl font-extrabold text-gold">{{ watch.ad.title }}</h2>
        <p class="text-base leading-relaxed">{{ watch.ad.body }}</p>
        <a v-if="watch.ad.cta_url" :href="watch.ad.cta_url" target="_blank" rel="noopener noreferrer nofollow" class="self-center font-bold text-ring underline">{{ watch.ad.cta_label || watch.ad.cta_url }}</a>
        <div class="h-2 overflow-hidden rounded-full bg-surface-sunk" role="progressbar" :aria-valuenow="watch.ad.seconds - left" aria-valuemin="0" :aria-valuemax="watch.ad.seconds">
          <div class="h-full bg-gold transition-all" :style="{ width: `${((watch.ad.seconds - left) / watch.ad.seconds) * 100}%` }" />
        </div>
        <p v-if="message" class="text-sm text-warning" role="status">{{ $t(message) }}</p>
        <div class="flex gap-2">
          <button type="button" class="h-touch flex-1 rounded-lg bg-gold font-bold text-on-gold disabled:opacity-40" :disabled="left > 0 || busy" @click="claim">
            {{ left > 0 ? $t('انتظر {v0} ث', { v0: left }) : $t('خذ المكافأة: −{v0} دقيقة', { v0: ads.minutes }) }}</button>
          <button type="button" class="h-touch rounded-lg px-4 text-sm text-text-muted" @click="close">{{ $t('إغلاق') }}</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
