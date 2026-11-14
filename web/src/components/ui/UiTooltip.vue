<script setup lang="ts">
// [Sprint 30 Q1] A short word on what a number means, on reka-ui's Tooltip: on hover and on the keyboard's focus,
// in a layer above the page (never clipped by a card), on the side that fits. Long explanations stay in the
// Assistant Coach's guide (Sprint 22), never here.
import { TooltipArrow, TooltipContent, TooltipPortal, TooltipRoot, TooltipTrigger } from 'reka-ui'

defineProps<{ text: string }>()
</script>

<template>
  <TooltipRoot :delay-duration="250">
    <TooltipTrigger as-child><slot /></TooltipTrigger>
    <TooltipPortal>
      <TooltipContent
        :side-offset="6"
        class="z-[70] max-w-60 rounded-lg bg-surface-raised px-3 py-1.5 text-xs text-text shadow-xl data-[state=delayed-open]:animate-fade-up"
      >
        {{ $t(text) }}
        <TooltipArrow class="fill-surface-raised" />
      </TooltipContent>
    </TooltipPortal>
  </TooltipRoot>
</template>
