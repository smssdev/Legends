<script setup lang="ts">
// [Sprint 54 W3] Time left until a moment (a kick-off, a slot that opens), ticking every second, in the numbers' font
// and left to right; `done` takes its place once it is reached («الآن», «مباشر»...).
import { countdown, useNow } from '../../lib/clock'

withDefaults(defineProps<{ to: string | null | undefined; done?: string; size?: 'sm' | 'lg' }>(), { done: 'الآن', size: 'sm' })
const now = useNow()
</script>

<template>
  <b class="font-numbers text-gold" :class="size === 'lg' ? 'text-display' : 'text-body'" dir="ltr">{{ countdown(to, now) || $t(done) }}</b>
</template>
