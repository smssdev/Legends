<script setup lang="ts">
// [Sprint 54 W3, W-D15] Every screen's three other states in one place: loading (a skeleton in the content's shape),
// an error (its message and «حاول مجدداً»), and empty (EmptyState). The content shows only when it is ready, so no
// screen is ever blank, half-filled or silent about a failure.
import { onBeforeUnmount, ref, watch } from 'vue'
import EmptyState from './EmptyState.vue'
import Skeleton from './Skeleton.vue'
import Character from '../characters/Character.vue'
import type { PATHS } from '../Icon.vue'

// [Sprint 63 G9] The mascot in the states, as in the app (mobile/assets/states): worried at an error, thinking when a
// wait runs past 4 seconds (it says so), and idle when empty (EmptyState).
const props = defineProps<{
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

const SLOW_MS = 4000
const slow = ref(false)
let timer = 0
watch(
  () => props.loading,
  (on) => {
    clearTimeout(timer)
    slow.value = false
    if (on) timer = window.setTimeout(() => (slow.value = true), SLOW_MS)
  },
  { immediate: true },
)
onBeforeUnmount(() => clearTimeout(timer))
</script>

<template>
  <div v-if="loading" role="status" :aria-label="$t('جارٍ التحميل')">
    <div v-if="slow" class="mb-3 flex items-center justify-center gap-3 text-caption text-text-muted">
      <Character model="A2" mood="think" class="w-14" />{{ $t('يأخذ وقتاً أطول من المعتاد…') }}
    </div>
    <Skeleton :kind="skeleton ?? 'row'" :count="rows ?? 4" />
  </div>
  <div
    v-else-if="error"
    role="alert"
    class="flex flex-col items-center gap-3 rounded-xl border border-live/30 bg-live/10 px-4 py-6 text-center"
  >
    <Character model="A2" mood="worried" class="w-20" />
    <p class="text-body font-bold">{{ $t(error) }}</p>
    <button type="button" class="min-h-touch rounded-lg bg-surface-raised px-5 font-bold" @click="$emit('retry')">
      {{ $t('حاول مجدداً') }}
    </button>
  </div>
  <EmptyState v-else-if="empty" :icon="emptyIcon ?? 'more'" :title="emptyTitle ?? 'لا شيء هنا بعد'" :text="emptyText" :cta="emptyCta" />
  <slot v-else />
</template>
