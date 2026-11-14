<script setup lang="ts">
// [Sprint 26 W1] One of the game's nine characters in a mood (README section 0, 2026-10-30): A1 to A3 the mascots,
// B1 to B3 the assistant's faces, C1 to C3 the coach on the touchline. The mood comes from the server
// (App\Characters\Mood) or from the screen's own state (the assistant thinking); the drawing only shows it. A coach
// may be the 3D one (three), a moving picture rendered from Blender (tools/unity/art/characters.py). With reduced
// motion the drawing stands still.
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { drawCharacter, drawFace, ensureDefs, MOODS, type Model, type Mood } from './art'
import './characters.css'

const props = withDefaults(defineProps<{ model: Model; mood?: string | null; three?: boolean; label?: string }>(), {
  mood: 'idle',
  three: false,
  label: undefined,
})

const mood = computed<Mood>(() => ((MOODS as readonly string[]).includes(props.mood ?? '') ? (props.mood as Mood) : 'idle'))
const reduced = typeof matchMedia !== 'undefined' && matchMedia('(prefers-reduced-motion: reduce)').matches
const use3d = computed(() => props.three && props.model.startsWith('C') && !reduced)
const host = ref<HTMLElement | null>(null)

function draw() {
  if (host.value) host.value.innerHTML = drawCharacter(props.model, mood.value)
}
onMounted(() => {
  ensureDefs()
  draw()
})
watch(() => props.model, draw)
watch(use3d, () => nextTick(draw))
// A new mood keeps the body and changes the face, so the arms and the head move to it smoothly.
watch(mood, (m) => {
  const svg = host.value?.querySelector('svg')
  const face = svg?.querySelector('.face')
  if (!svg || !face) return draw()
  svg.setAttribute('class', `char m-${m}`)
  face.innerHTML = drawFace(props.model, m)
})
</script>

<template>
  <img
    v-if="use3d"
    :src="`/characters/${model.toLowerCase()}-${mood}.webp`"
    :alt="label ?? ''"
    class="lgc-3d"
    draggable="false"
    loading="lazy"
    decoding="async"
  />
  <span v-else ref="host" class="lgc" :role="label ? 'img' : undefined" :aria-label="label" :aria-hidden="label ? undefined : 'true'" />
</template>

<style>
.lgc {
  display: inline-block;
  line-height: 0;
}
.lgc > svg {
  display: block;
  width: 100%;
  height: auto;
}
.lgc-3d {
  display: inline-block;
  height: auto;
  object-fit: contain;
}
</style>
