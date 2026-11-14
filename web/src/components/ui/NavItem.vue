<script setup lang="ts">
// [Sprint 54 W3] One section of the menu: its icon over its name, gold when it is where the coach is (with the gold
// mark under it). The shell's menu row draws them; Sprint 55's dock stands them on their side. Its look is the global
// .ui-nav-item in style.css, which the row's dropdown names (reka-ui's triggers) wear too.
import Icon, { type PATHS } from '../Icon.vue'

defineProps<{ to: string; icon: keyof typeof PATHS; label: string; active?: boolean }>()
</script>

<template>
  <RouterLink :to="to" class="ui-nav-item" :class="active ? 'is-active' : ''" :aria-current="active ? 'page' : undefined">
    <Icon :name="icon" :size="20" class="ui-nav-icon" />{{ $t(label) }}
  </RouterLink>
</template>
