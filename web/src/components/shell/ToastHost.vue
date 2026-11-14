<script setup lang="ts">
// [X61] The toasts, from the top: they slide down under the top bar and leave upwards.
import { useToast } from '../../stores/toast'

const toast = useToast()
</script>

<template>
  <div
    class="pointer-events-none fixed inset-x-0 top-[calc(4.25rem+env(safe-area-inset-top))] z-[60] flex flex-col items-center gap-2 px-3"
    aria-live="polite"
  >
    <TransitionGroup name="toast">
      <div
        v-for="t in toast.list"
        :key="t.id"
        role="status"
        class="pointer-events-auto flex w-full max-w-sm items-center gap-2 rounded-xl border px-4 py-2 text-start text-sm font-bold shadow-2xl backdrop-blur"
        :class="t.tone === 'success' ? 'border-success/40 bg-surface/95 text-success' : 'border-live/40 bg-surface/95 text-danger'"
      >
        <button
          type="button"
          class="flex min-h-11 min-w-0 flex-1 items-center gap-2 text-start"
          :aria-label="$t('إغلاق')"
          @click="toast.close(t.id)"
        >
          <svg
            v-if="t.tone === 'success'"
            class="size-5 shrink-0"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="M5 12.5l4.5 4.5L19 7.5" class="animate-draw" style="stroke-dasharray: 24; stroke-dashoffset: 24" />
          </svg>
          <span class="min-w-0 flex-1 text-text">{{ t.text }}</span>
        </button>
        <!-- [X87] The one action a toast may carry: «تراجع». -->
        <button
          v-if="t.action"
          type="button"
          class="min-h-11 shrink-0 rounded-lg bg-gold/15 px-3 text-gold hover:bg-gold/25"
          @click="(toast.close(t.id), t.action.run())"
        >
          {{ $t(t.action.label) }}
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition:
    opacity var(--duration-base) var(--ease-soft),
    transform var(--duration-base) var(--ease-soft);
}
.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(-0.75rem);
}
.toast-move {
  transition: transform var(--duration-base) var(--ease-soft);
}
</style>
