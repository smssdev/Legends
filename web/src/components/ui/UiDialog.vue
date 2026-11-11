<script setup lang="ts">
// [X61] Every window over a screen: the focus stays inside, Esc and the veil close it, the page behind does not
// scroll. It drops from the top (under the top bar on a phone, never a sheet from the bottom), and scrolls inside
// itself when long. [Sprint 54 W4] On reka-ui's Dialog (Headless UI is gone); the animation is the `ui-veil` and
// `ui-window` classes in style.css, read from the open/closed state reka puts on them.
import { DialogClose, DialogContent, DialogOverlay, DialogPortal, DialogRoot, DialogTitle, VisuallyHidden } from 'reka-ui'

// `bare`: the content brings its own card (a screen's existing window moved here as it was). `closable`: a ✕ by the
// title (44px), for a long window whose foot is out of sight.
const props = withDefaults(defineProps<{ open: boolean; title?: string; wide?: boolean; bare?: boolean; closable?: boolean }>(), { wide: false, bare: false, closable: false })
const emit = defineEmits<{ close: [] }>()
const onOpen = (o: boolean) => { if (!o && props.open) emit('close') }
</script>

<template>
  <DialogRoot :open="open" @update:open="onOpen">
    <DialogPortal>
      <DialogOverlay class="ui-veil fixed inset-0 z-[65] overflow-y-auto overscroll-contain bg-black/60">
        <div class="flex min-h-full items-start justify-center p-3 pt-[max(1rem,env(safe-area-inset-top))] md:items-center md:p-6">
          <DialogContent v-if="bare" class="ui-window flex w-full origin-top justify-center" :aria-describedby="undefined">
            <VisuallyHidden v-if="title"><DialogTitle>{{ $t(title) }}</DialogTitle></VisuallyHidden>
            <slot />
          </DialogContent>
          <DialogContent v-else class="ui-window flex max-h-[88dvh] w-full origin-top flex-col overflow-y-auto overscroll-contain rounded-2xl border border-text/10 bg-bg p-4 shadow-overlay" :class="wide ? 'max-w-2xl' : 'max-w-md'" :aria-describedby="undefined">
            <div v-if="title || closable" class="mb-3 flex items-center gap-2">
              <DialogTitle v-if="title" class="flex-1 font-display text-headline">{{ $t(title) }}</DialogTitle>
              <DialogClose v-if="closable" class="ms-auto grid size-touch shrink-0 place-items-center rounded-md bg-surface-raised" :aria-label="$t('إغلاق')">✕</DialogClose>
            </div>
            <slot />
          </DialogContent>
        </div>
      </DialogOverlay>
    </DialogPortal>
  </DialogRoot>
</template>
