<template>
  <div class="replay" role="img" :aria-label="$t('إعادة الهدف: {v0}', { v0: who })">
    <span class="tag">إعادة · {{ who }}</span>
    <div ref="stage" class="stage" />
  </div>
</template>

<script setup lang="ts">
// @ts-nocheck
// The goal again, in a small frame while play goes on (docs/MATCH_VIEW.md 4.2): the last seconds of its scene,
// up to the ball in the net, at half speed. Drawn from the same minute and seed, so it is the goal as it was.
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { SCENES } from './art'
import { SCENE_TIME, story } from './story'

const props = defineProps<{ tick: any; players: any; clubs: { home: string; away: string }; seed: number }>()
const emit = defineEmits<{ done: [] }>()
const stage = ref<HTMLElement>()
const s = story(props.tick, { players: props.players, clubs: props.clubs, seed: props.seed, mine: null })
const who = s.who || ''
// Four seconds: two seconds of play before the ball goes in, and the moment after, at half speed.
const LENGTH = 2.2, RATE = 0.5
let raf = 0

onMounted(() => {
  if (!s.scene || !SCENES[s.scene]) return emit('done')
  let scene
  // A scene that breaks ends the replay instead of stopping the match.
  try { scene = SCENES[s.scene]({ ...s.data, side: s.side }) } catch (e) { console.error(e); return emit('done') }
  stage.value.replaceChildren(scene.svg)
  const key = s.keyAt * SCENE_TIME[s.scene][0]
  const from = Math.max(0, key - 1.8)
  const start = performance.now()
  const frame = (now) => {
    const t = from + ((now - start) / 1000) * RATE
    try { scene.update(t) } catch (e) { console.error(e); return emit('done') }
    if (t < from + LENGTH) raf = requestAnimationFrame(frame)
    else emit('done')
  }
  raf = requestAnimationFrame(frame)
})
onBeforeUnmount(() => cancelAnimationFrame(raf))
</script>

<style scoped>
.replay { position: absolute; inset-inline-start: 10px; bottom: 10px; z-index: 15; width: min(42%, 340px); border-radius: 12px; overflow: hidden; border: 2px solid #F5B82E; background: #050D1F; box-shadow: 0 12px 30px rgba(0,0,0,.5) }
.tag { position: absolute; top: 6px; inset-inline-start: 6px; z-index: 1; padding: 2px 8px; border-radius: 999px; background: #F5B82E; color: #071733; font-size: 12px; font-weight: 800 }
.stage :deep(svg) { display: block; width: 100%; height: auto }
</style>
