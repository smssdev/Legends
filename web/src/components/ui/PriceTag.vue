<script setup lang="ts">
// A price in coins (with the coin) or in club money (Sprint 34): the premium features cost coins, or club money in
// a fair league where coins are locked.
import { count, money } from '../../lib/format'

defineProps<{ amount: number; currency: 'coins' | 'money' }>()
</script>

<template>
  <span v-if="currency === 'coins'" class="inline-flex items-center gap-1 font-numbers" dir="ltr">
    <img src="/brand/coin.svg" alt="" class="size-4" />{{ count(amount) }}<span class="sr-only">كوينز</span>
  </span>
  <span v-else class="font-numbers" dir="ltr">{{ money(amount) }}</span>
</template>
