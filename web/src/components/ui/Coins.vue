<script setup lang="ts">
// The premium currency, الكوينز, with its coin.
import { count } from '../../lib/format'
defineProps<{ amount: number }>()
</script>

<template>
  <span class="inline-flex items-center gap-1.5 font-numbers text-lg font-bold" :aria-label="$t('{v0} كوينز', { v0: amount })">
    {{ count(amount) }}<AppImage src="/brand/coin.svg" alt="" class="size-5" :size="20" />
  </span>
</template>
