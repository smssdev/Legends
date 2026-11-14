<script setup lang="ts">
// [Sprint 64 W-B4] A spend before it is made, as the server quotes it (App\Wallet\SpendQuote): what is left after,
// and when what it buys ends. One line under the spend's button, on every screen that spends.
import type { components } from '../../api/schema'
import { stamp } from '../../lib/dates'
import PriceTag from './PriceTag.vue'

defineProps<{ quote: components['schemas']['SpendQuote'] }>()
</script>

<template>
  <p class="spend-note" :class="{ 'spend-short': !quote.can }">
    <template v-if="quote.can">{{ $t('يبقى بعده') }} <PriceTag :amount="quote.after" :currency="quote.currency" /></template>
    <template v-else>{{ $t('ينقصك') }} <PriceTag :amount="-quote.after" :currency="quote.currency" /></template>
    <template v-if="quote.ends_at"> · {{ $t('ينتهي {v0}', { v0: stamp(quote.ends_at) }) }}</template>
  </p>
</template>

<style scoped>
.spend-note { font-size: var(--text-caption); color: var(--color-text-muted); }
.spend-short { color: var(--color-danger); }
</style>
