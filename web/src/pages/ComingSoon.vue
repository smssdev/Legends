<script setup lang="ts">
// A section whose sprint has not come yet (docs/SPRINTS.md).
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import Icon from '../components/Icon.vue'
import { SECTIONS } from '../layouts/nav'

const route = useRoute()
const section = computed(() => SECTIONS.find((s) => s.name === route.name))
</script>

<template>
  <div v-if="section" class="flex flex-col items-center gap-3 rounded-xl bg-surface px-4 py-14 text-center">
    <span class="flex size-16 items-center justify-center rounded-full bg-gold/15 text-gold"><Icon :name="section.icon" :size="30" /></span>
    <h1 class="font-display text-2xl font-extrabold">{{ $t(section.label) }}</h1>
    <p class="text-text-muted">{{ $t('قريباً. يصل هذا القسم في السبرنت') }} <span class="font-numbers text-lg text-gold">{{ section.sprint }}</span>.</p>
  </div>
</template>
