<template>
  <div class="grid grid-cols-2 gap-x-6 gap-y-3 md:grid-cols-3">
    <div v-for="row in rows" :key="row.label" class="flex flex-col gap-1.5">
      <div class="flex justify-between text-sm">
        <span class="font-numbers text-lg">{{ row.h }}</span>
        <span class="text-text-muted">{{ $t(row.label) }}</span>
        <span class="font-numbers text-lg">{{ row.a }}</span>
      </div>
      <div class="flex h-1.5 gap-1">
        <div class="rounded-full" :style="{ flex: Math.max(row.h, 0.2), background: homeColor }" />
        <div class="rounded-full bg-text" :style="{ flex: Math.max(row.a, 0.2) }" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ home: Record<string, number>; away: Record<string, number>; homeColor: string }>()
const rows = computed(() => {
  const att = (props.home.attacks || 0) + (props.away.attacks || 0)
  return [
    {
      label: 'الاستحواذ %',
      h: att ? Math.round((100 * props.home.attacks) / att) : 50,
      a: att ? Math.round((100 * props.away.attacks) / att) : 50,
    },
    { label: 'تسديدات', h: props.home.shots, a: props.away.shots },
    { label: 'على المرمى', h: props.home.on_target, a: props.away.on_target },
    { label: 'فرص محققة', h: props.home.big_chances, a: props.away.big_chances },
    { label: 'بناء مقطوع', h: props.home.presses_won, a: props.away.presses_won },
    { label: 'ركنيات', h: props.home.corners, a: props.away.corners },
    { label: 'أخطاء', h: props.home.fouls, a: props.away.fouls },
    { label: 'تسلل', h: props.home.offsides, a: props.away.offsides },
    { label: 'بطاقات', h: props.home.yellow + props.home.red, a: props.away.yellow + props.away.red },
  ]
})
</script>
