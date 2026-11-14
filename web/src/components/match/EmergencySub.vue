<template>
  <!-- [UP17, Sprint 57 W2] The emergency substitution: my injured player, a few seconds to pick who comes on. -->
  <div
    dir="rtl"
    class="absolute inset-0 z-30 flex flex-col items-center justify-center gap-3 bg-bg-deep/90 p-4 text-center"
    role="alertdialog"
    :aria-label="$t('تبديل طارئ')"
  >
    <span class="font-display text-xl font-extrabold text-warning">{{ $t('إصابة: {v0}', { v0: injuredName }) }}</span>
    <span class="text-sm text-text-soft"
      >{{ $t('اختر البديل خلال') }} <b class="font-numbers text-lg text-gold">{{ left }}</b>
      {{ $t('ثانية، وإلا اختاره المدرب المساعد') }}</span
    >
    <div class="flex max-w-xl flex-wrap justify-center gap-2">
      <button
        v-for="p in bench"
        :key="p.id"
        type="button"
        class="min-h-touch rounded-md bg-surface-raised px-3 text-sm font-bold"
        @click="emit('pick', p.id)"
      >
        {{ p.pos }} · {{ $nm(p.name) }} <span class="font-numbers text-gold">{{ p.ovr }}</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { TeamPlayer } from '../../api/sim'

defineProps<{ injuredName: string; left: number; bench: TeamPlayer[] }>()
const emit = defineEmits<{ pick: [id: number] }>()
</script>
