<template>
  <!-- [Sprint 11 W3] The Unity scene over the cartoon, which keeps playing under it (the page's clock, cues and sound):
       a failure or a weak device only uncovers the cartoon at the same second (W4). -->
  <div v-show="state !== 'failed'" class="absolute inset-0 z-10 bg-bg-deep" :aria-hidden="state !== 'ready'">
    <!-- Unity finds its canvas by its id (its keyboard listener): without one it stops on start. -->
    <canvas id="glm-unity-scene" ref="canvas" class="size-full" tabindex="-1" :aria-label="$t('مشهد المباراة ثلاثي الأبعاد')" />
    <div v-if="state === 'loading'" class="absolute inset-0 grid place-items-center bg-bg-deep/90" role="status">
      <div class="flex w-56 flex-col items-center gap-2 text-center">
        <span class="text-sm font-bold">{{ $t('نجهّز الملعب ثلاثي الأبعاد...') }}</span>
        <span class="h-1.5 w-full overflow-hidden rounded-full bg-surface">
          <span class="block h-full bg-brand transition-[width]" :style="{ width: `${Math.round(progress * 100)}%` }" />
        </span>
        <span class="text-xs text-text-muted">{{ $t('المباراة مستمرة بالمحاكي الكرتوني حتى يجهز') }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import type { Tick } from '../../api/sim'
import { canRunUnity, unityFiles, unityMinute, unityQuality } from '../../match/unity/bridge'
import type { Tier } from '../../match/perf'
import { report } from '../../lib/errors'

type Instance = { SendMessage: (object: string, method: string, arg?: string | number) => void; Quit: () => Promise<void> }
type Create = (canvas: HTMLCanvasElement, config: object, progress?: (p: number) => void) => Promise<Instance>

// build: the deployed web build (GET /health unity_build); setup: unitySetup(view, teams); tier: the cartoon's tier.
const props = defineProps<{ build: string; setup: object; tier: Tier }>()
const emit = defineEmits<{ ready: []; failed: [reason: string] }>()

const canvas = ref<HTMLCanvasElement>()
const state = ref<'loading' | 'ready' | 'failed'>('loading')
const progress = ref(0)
let unity: Instance | null = null
// The minute the page is on, kept until the scene is ready so it starts on the same second.
let pending: { t: Tick; startAt: number | null } | null = null
let timer = 0
// A load that takes longer than this plays the cartoon (the scene may come in later on a better connection).
const LOAD_LIMIT_MS = 60_000

function fail(reason: string) {
  if (state.value === 'failed') return
  state.value = 'failed'
  clearTimeout(timer)
  emit('failed', reason)
}

function send(method: string, arg = '') {
  try {
    unity?.SendMessage('Bridge', method, arg)
  } catch (e) {
    fail('send')
    report(e)
  }
}

/** The page's minute: to the scene now (from the same second), or kept until it is ready. */
function play(t: Tick, startAt: number | null = null) {
  if (state.value === 'failed') return
  if (!unity || state.value !== 'ready') {
    pending = { t, startAt }
    return
  }
  send('OnPlay', unityMinute(t, startAt, performance.now()))
}

function skip() {
  pending = null
  if (state.value === 'ready') send('OnSkip')
}

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const s = document.createElement('script')
    s.src = src
    s.async = true
    s.onload = () => resolve()
    s.onerror = () => reject(new Error('loader'))
    document.head.appendChild(s)
  })
}

onMounted(async () => {
  const gl2 = !!document.createElement('canvas').getContext('webgl2')
  if (!canRunUnity(navigator as never, gl2)) return fail('device')
  const files = unityFiles(props.build)
  timer = window.setTimeout(() => fail('timeout'), LOAD_LIMIT_MS)
  canvas.value?.addEventListener('webglcontextlost', () => fail('context'), { once: true })
  try {
    await loadScript(files.loaderUrl)
    const create = (window as unknown as { createUnityInstance?: Create }).createUnityInstance
    if (!create || !canvas.value) return fail('loader')
    unity = await create(
      canvas.value,
      { ...files, devicePixelRatio: Math.min(window.devicePixelRatio || 1, 1.5) },
      (p) => (progress.value = p),
    )
    if (state.value === 'failed') return void unity.Quit().catch(() => {})
    clearTimeout(timer)
    send('OnQuality', unityQuality(props.tier))
    send('OnSetup', JSON.stringify(props.setup))
    state.value = 'ready'
    emit('ready')
    if (pending) play(pending.t, pending.startAt)
    pending = null
  } catch (e) {
    report(e)
    // Out of memory, a missing build, a browser that will not run it: the cartoon plays on.
    fail('load')
  }
})

watch(
  () => props.tier,
  (t) => state.value === 'ready' && send('OnQuality', unityQuality(t)),
)

onBeforeUnmount(() => {
  clearTimeout(timer)
  unity?.Quit().catch(() => {})
  unity = null
})

defineExpose({ play, skip })
</script>
