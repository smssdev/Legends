<template>
  <!-- [Sprint 11 W3, X113] The Unity scene: the picture under the match feed, which draws its captions, score and
       commentary over it (MatchFeed's scene3d). Hidden until it is ready: the cartoon plays as ever while it loads, and
       a failure or a weak device only leaves the cartoon (W4). -->
  <div class="absolute inset-0 bg-bg-deep" :class="state === 'ready' ? 'visible' : 'invisible'" aria-hidden="true">
    <!-- Unity finds its canvas by its id (its keyboard listener): without one it stops on start. -->
    <canvas id="glm-unity-scene" ref="canvas" class="size-full" tabindex="-1" />
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import type { Tick } from '../../api/sim'
import { canRunUnity, unityClock, unityFiles, unityMinute, unityQuality } from '../../match/unity/bridge'
import type { Tier } from '../../match/perf'
import { report } from '../../lib/errors'

type Instance = { SendMessage: (object: string, method: string, arg?: string | number) => void; Quit: () => Promise<void> }
type Create = (canvas: HTMLCanvasElement, config: object, progress?: (p: number) => void) => Promise<Instance>

// build: the deployed web build (GET /health unity_build); setup: unitySetup(view, teams); tier: the cartoon's tier;
// clock: where the page's feed is (MatchFeed.now); rate: how fast the page's time runs (its speed).
const props = defineProps<{ build: string; setup: object; tier: Tier; clock: () => { tick: number; t: number } | null; rate: number }>()
const emit = defineEmits<{ ready: []; failed: [reason: string]; progress: [p: number] }>()

const canvas = ref<HTMLCanvasElement>()
const state = ref<'loading' | 'ready' | 'failed'>('loading')
let unity: Instance | null = null
// The minute the page is on, kept until the scene is ready so it starts on the same second.
let pending: { t: Tick; startAt: number | null } | null = null
let timer = 0
let beat = 0
// A load that takes longer than this plays the cartoon (the scene may come in later on a better connection).
const LOAD_LIMIT_MS = 120_000
// How often the scene is told the page's clock.
const CLOCK_MS = 200

function fail(reason: string) {
  if (state.value === 'failed') return
  state.value = 'failed'
  clearTimeout(timer)
  clearInterval(beat)
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

/** [X113] The page's clock to the scene, so it shows the same second at every speed and stops when the page stops. */
function tickClock() {
  if (state.value !== 'ready') return
  const c = props.clock()
  if (c) send('OnClock', unityClock(c.tick, c.t, props.rate))
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
    unity = await create(canvas.value, { ...files, devicePixelRatio: Math.min(window.devicePixelRatio || 1, 1.5) }, (p) =>
      emit('progress', p),
    )
    if (state.value === 'failed') return void unity.Quit().catch(() => {})
    clearTimeout(timer)
    send('OnQuality', unityQuality(props.tier))
    send('OnSetup', JSON.stringify(props.setup))
    state.value = 'ready'
    emit('ready')
    if (pending) play(pending.t, pending.startAt)
    pending = null
    beat = window.setInterval(tickClock, CLOCK_MS)
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
  clearInterval(beat)
  unity?.Quit().catch(() => {})
  unity = null
})

defineExpose({ play, skip })
</script>
