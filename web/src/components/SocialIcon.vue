<script setup lang="ts">
// [X82, X98] The social networks' marks as the owner's pictures: a rounded tile in the network's own colours (its
// brand, not the game's tokens) with its white sign, a soft shade over the lower corner, all four the same shape and
// size. YouTube drawn the same way to match.
import { useId } from 'vue'
import type { Social } from '../content/site'

defineProps<{ name: Social['key'] }>()
const id = useId()
const TIKTOK = 'M12.53.02C13.84 0 15.14.01 16.44 0c.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07Z'
</script>

<template>
  <svg viewBox="0 0 48 48" class="size-10" aria-hidden="true" focusable="false">
    <defs>
      <clipPath :id="`${id}-tile`"><rect width="48" height="48" rx="12" /></clipPath>
      <linearGradient v-if="name === 'facebook'" :id="`${id}-bg`" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#5a86dc" /><stop offset="1" stop-color="#1c45a0" />
      </linearGradient>
      <radialGradient v-else-if="name === 'instagram'" :id="`${id}-bg`" cx="0.2" cy="1.05" r="1.25">
        <stop offset="0" stop-color="#ffdd55" /><stop offset="0.12" stop-color="#ffcb3d" /><stop offset="0.35" stop-color="#ff5a4a" />
        <stop offset="0.6" stop-color="#e9268f" /><stop offset="1" stop-color="#7a2be0" />
      </radialGradient>
      <linearGradient v-else-if="name === 'youtube'" :id="`${id}-bg`" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#ff3b30" /><stop offset="1" stop-color="#c4000a" />
      </linearGradient>
      <linearGradient v-else :id="`${id}-bg`" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#111" /><stop offset="1" stop-color="#000" />
      </linearGradient>
    </defs>
    <g :clip-path="`url(#${id}-tile)`">
      <rect width="48" height="48" :fill="`url(#${id}-bg)`" />
      <!-- The soft shade over the lower corner, as on the pictures. -->
      <circle cx="40" cy="48" r="34" fill="#000" opacity="0.1" />

      <g v-if="name === 'facebook'" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round">
        <path d="M27 52V20.5a6.5 6.5 0 0 1 6.5-6.5h3" />
        <path d="M19.5 26.5h15" />
      </g>
      <g v-else-if="name === 'instagram'" fill="none" stroke="#fff" stroke-width="3.6">
        <rect x="11" y="11" width="26" height="26" rx="8" />
        <circle cx="24" cy="24" r="6.3" />
        <circle cx="31.4" cy="16.6" r="1.9" fill="#fff" stroke="none" />
      </g>
      <path v-else-if="name === 'youtube'" d="M19 15.6c0-1.6 1.7-2.6 3.1-1.8l13.4 8.4c1.3.8 1.3 2.8 0 3.6l-13.4 8.4c-1.4.9-3.1-.1-3.1-1.8z" fill="#fff" />
      <path v-else :d="TIKTOK" fill="#fff" transform="translate(11 10.2) scale(1.15)" />
    </g>
  </svg>
</template>
