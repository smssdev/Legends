<template>
  <img v-if="!failed" :src="src ?? ''" :alt="alt ?? ''" :width="w" :height="h" :loading="eager ? 'eager' : 'lazy'" decoding="async" @error="failed = true" />
  <!-- A picture that does not come (a broken link, offline): a crest becomes a shield in the club's colours, any other
       picture a quiet square of its size, so nothing jumps and no broken-image icon shows. -->
  <Crest v-else-if="crest" :code="crest.code ?? ''" :primary="crest.colors?.[0] ?? '#1C2B48'" :secondary="crest.colors?.[1] ?? '#93A3BF'" :size="w" />
  <span v-else class="inline-block shrink-0 rounded-md bg-surface-sunk" :style="{ width: w + 'px', height: h + 'px' }" aria-hidden="true" />
</template>

<script setup lang="ts">
// [Sprint 58 W3, W-P10] Every picture of the game: its size given (width and height, so the page never moves when it
// arrives), loaded when it comes into view (eager for the first screen's), decoded off the main thread, and a fallback
// when it fails. size: a square's side in px (a crest is 1.12 times taller); or width and height.
import { computed, ref, watch } from 'vue'
import Crest from '../Crest.vue'

const props = defineProps<{ src?: string | null; alt?: string; size?: number; width?: number; height?: number; eager?: boolean; crest?: { code?: string; colors?: string[] } | true }>()
const failed = ref(false)
watch(() => props.src, () => (failed.value = !props.src), { immediate: true })
const w = computed(() => props.width ?? props.size ?? 24)
const h = computed(() => props.height ?? (props.crest && !props.width ? Math.round(w.value * 1.12) : props.size ?? w.value))
const crest = computed(() => (props.crest === true ? {} : props.crest ?? null))
</script>
