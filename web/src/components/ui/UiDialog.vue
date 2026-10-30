<script setup lang="ts">
// [X61] Every window over a screen on Headless UI's Dialog: the focus stays inside, Esc and the veil close it, the
// page behind does not scroll. It drops from the top (under the top bar on a phone, never a sheet from the bottom),
// and scrolls inside itself when long.
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'

// `bare`: the content brings its own card (a screen's existing window moved here as it was).
withDefaults(defineProps<{ open: boolean; title?: string; wide?: boolean; bare?: boolean }>(), { wide: false, bare: false })
const emit = defineEmits<{ close: [] }>()
</script>

<template>
  <TransitionRoot :show="open" as="template">
    <Dialog class="relative z-[65]" @close="emit('close')">
      <TransitionChild as="template" enter="transition-opacity duration-200" enter-from="opacity-0" leave="transition-opacity duration-150" leave-to="opacity-0">
        <div class="fixed inset-0 bg-black/60" aria-hidden="true" />
      </TransitionChild>
      <div class="fixed inset-0 overflow-y-auto overscroll-contain">
        <div class="flex min-h-full items-start justify-center p-3 pt-[max(1rem,env(safe-area-inset-top))] md:items-center md:p-6">
          <TransitionChild as="template" enter="transition duration-300 ease-soft" enter-from="opacity-0 -translate-y-4 scale-[0.98]" leave="transition duration-150 ease-soft" leave-to="opacity-0 -translate-y-2">
            <DialogPanel v-if="bare" class="flex w-full origin-top justify-center"><slot /></DialogPanel>
            <DialogPanel v-else class="w-full origin-top rounded-2xl border border-text/10 bg-bg p-4 shadow-2xl" :class="wide ? 'max-w-2xl' : 'max-w-md'">
              <DialogTitle v-if="title" class="mb-3 font-display text-2xl font-extrabold">{{ $t(title) }}</DialogTitle>
              <slot />
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>
