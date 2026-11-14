<script setup lang="ts">
import Icon from '../Icon.vue'
// [X61] Every window over a screen: the focus stays inside, Esc and the veil close it, the page behind does not
// scroll. It drops from the top (under the top bar on a phone, never a sheet from the bottom), and scrolls inside
// itself when long. [Sprint 54 W4] On reka-ui's Dialog (Headless UI is gone); the animation is the `ui-veil` and
// `ui-window` classes in style.css, read from the open/closed state reka puts on them.
import { DialogClose, DialogContent, DialogOverlay, DialogPortal, DialogRoot, DialogTitle, VisuallyHidden } from 'reka-ui'

// `bare`: the content brings its own card (a screen's existing window moved here as it was). `closable`: a ✕ by the
// title (44px), for a long window whose foot is out of sight.
// [Sprint 56 W2] `side`: a panel along the screen's end edge, full height, beside what it is about (the player's card
// beside the squad's table): no veil, the screen behind still answers (a tap on another row there closes this one and
// opens the next), Esc closes it.
const props = withDefaults(
  defineProps<{ open: boolean; title?: string; wide?: boolean; bare?: boolean; closable?: boolean; side?: boolean }>(),
  { wide: false, bare: false, closable: false, side: false },
)
const emit = defineEmits<{ close: [] }>()
const onOpen = (o: boolean) => {
  if (!o && props.open) emit('close')
}
</script>

<template>
  <DialogRoot :open="open" :modal="!side" @update:open="onOpen">
    <DialogPortal v-if="side">
      <DialogContent class="ui-side" :aria-describedby="undefined">
        <div v-if="title || closable" class="mb-3 flex items-center gap-2">
          <DialogTitle v-if="title" class="flex-1 font-display text-title">{{ $t(title) }}</DialogTitle>
          <DialogClose
            v-if="closable"
            class="ms-auto grid size-touch shrink-0 place-items-center rounded-md bg-surface-raised"
            :aria-label="$t('إغلاق')"
            ><Icon name="close" :size="18"
          /></DialogClose>
        </div>
        <slot />
      </DialogContent>
    </DialogPortal>
    <DialogPortal v-else>
      <DialogOverlay class="ui-veil fixed inset-0 z-[65] overflow-y-auto overscroll-contain bg-black/60">
        <div class="flex min-h-full items-start justify-center p-3 pt-[max(1rem,env(safe-area-inset-top))] md:items-center md:p-6">
          <DialogContent v-if="bare" class="ui-window flex w-full origin-top justify-center" :aria-describedby="undefined">
            <VisuallyHidden v-if="title"
              ><DialogTitle>{{ $t(title) }}</DialogTitle></VisuallyHidden
            >
            <slot />
          </DialogContent>
          <DialogContent
            v-else
            class="ui-window flex max-h-[88dvh] w-full origin-top flex-col overflow-y-auto overscroll-contain rounded-2xl border border-text/10 bg-bg p-4 shadow-overlay"
            :class="wide ? 'max-w-2xl' : 'max-w-md'"
            :aria-describedby="undefined"
          >
            <div v-if="title || closable" class="mb-3 flex items-center gap-2">
              <DialogTitle v-if="title" class="flex-1 font-display text-headline">{{ $t(title) }}</DialogTitle>
              <DialogClose
                v-if="closable"
                class="ms-auto grid size-touch shrink-0 place-items-center rounded-md bg-surface-raised"
                :aria-label="$t('إغلاق')"
                ><Icon name="close" :size="18"
              /></DialogClose>
            </div>
            <slot />
          </DialogContent>
        </div>
      </DialogOverlay>
    </DialogPortal>
  </DialogRoot>
</template>

<style>
/* [Sprint 56 W2] The side panel: from the screen's end edge, under the frame's bar, sliding in. */
.ui-side {
  position: fixed;
  z-index: 60;
  inset-block: var(--bar-h, 42px) 0;
  inset-inline-end: 0;
  display: flex;
  flex-direction: column;
  width: min(24rem, 46vw);
  padding: var(--space-md);
  overflow-y: auto;
  overscroll-behavior: contain;
  background: var(--color-bg);
  border-inline-start: 1px solid color-mix(in srgb, var(--color-gold) 30%, transparent);
  box-shadow: var(--shadow-overlay);
}
@media (max-width: 560px) {
  .ui-side {
    width: 100vw;
  }
}
.ui-side[data-state='open'] {
  animation: side-in var(--duration-base) var(--ease-soft);
}
.ui-side[data-state='closed'] {
  animation: side-out var(--duration-fast) var(--ease-soft);
}
@keyframes side-in {
  from {
    opacity: 0;
    transform: translateX(var(--side-from, -1.5rem));
  }
}
@keyframes side-out {
  to {
    opacity: 0;
    transform: translateX(var(--side-from, -1.5rem));
  }
}
[dir='ltr'] .ui-side {
  --side-from: 1.5rem;
}
</style>
