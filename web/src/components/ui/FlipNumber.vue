<script setup lang="ts">
// [X61] A score digit that slides: the old number leaves upwards as the new one comes up from below (transform and
// opacity only), instead of a jump. Reduced motion: the global rule stops it.
defineProps<{ value: number | string }>()
</script>

<template>
  <span class="flip-num">
    <Transition name="flip-num">
      <span :key="value" class="flip-num-in">{{ value }}</span>
    </Transition>
  </span>
</template>

<style scoped>
.flip-num {
  position: relative;
  display: inline-grid;
  overflow: hidden;
  vertical-align: bottom;
}
.flip-num-in {
  grid-area: 1 / 1;
}
.flip-num-enter-active,
.flip-num-leave-active {
  transition:
    transform var(--duration-slow) var(--ease-spring),
    opacity var(--duration-base) var(--ease-soft);
}
.flip-num-enter-from {
  transform: translateY(70%);
  opacity: 0;
}
.flip-num-leave-to {
  transform: translateY(-70%);
  opacity: 0;
}
</style>
