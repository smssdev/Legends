<script setup lang="ts">
// [Sprint 48 T2] A player's national team as a small chip: its two colours side by side and its three letters, as the
// app's flag chip (Sprint 46). No flag pictures: the colours come from the API (Nations).
defineProps<{ nation: { code: string; colors: string[] } | null; name?: string | null }>()
</script>

<template>
  <span v-if="nation" class="inline-flex items-center gap-1.5" :title="name ?? nation.code">
    <span class="flex h-3.5 w-5 overflow-hidden rounded-[3px] ring-1 ring-shade/30" aria-hidden="true">
      <span class="flex-1" :style="{ background: nation.colors[0] }" /><span
        class="flex-1"
        :style="{ background: nation.colors[1] ?? nation.colors[0] }"
      />
    </span>
    <span class="font-numbers text-xs text-text-soft" dir="ltr">{{ nation.code }}</span>
  </span>
  <span v-else class="text-xs text-text-muted">—</span>
</template>
