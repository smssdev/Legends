<script setup lang="ts">
// [Sprint 54 W3, W-D15] Every screen's three other states in one place: loading (a skeleton in the content's shape),
// an error (its message and «حاول مجدداً»), and empty (EmptyState). The content shows only when it is ready, so no
// screen is ever blank, half-filled or silent about a failure.
import EmptyState from './EmptyState.vue'
import Skeleton from './Skeleton.vue'
import type { PATHS } from '../Icon.vue'

defineProps<{
  loading?: boolean
  error?: string | null
  empty?: boolean
  /** The skeleton's shape while it loads. */
  skeleton?: 'line' | 'card' | 'row' | 'hero'
  rows?: number
  emptyIcon?: keyof typeof PATHS
  emptyTitle?: string
  emptyText?: string
  emptyCta?: { label: string; to: string }
}>()
defineEmits<{ retry: [] }>()
</script>

<template>
  <div v-if="loading" role="status" :aria-label="$t('جارٍ التحميل')"><Skeleton :kind="skeleton ?? 'row'" :count="rows ?? 4" /></div>
  <div v-else-if="error" role="alert" class="flex flex-col items-center gap-3 rounded-xl border border-live/30 bg-live/10 px-4 py-6 text-center">
    <p class="text-body font-bold">{{ $t(error) }}</p>
    <button type="button" class="min-h-touch rounded-lg bg-surface-raised px-5 font-bold" @click="$emit('retry')">{{ $t('حاول مجدداً') }}</button>
  </div>
  <EmptyState v-else-if="empty" :icon="emptyIcon ?? 'more'" :title="emptyTitle ?? 'لا شيء هنا بعد'" :text="emptyText" :cta="emptyCta" />
  <slot v-else />
</template>
