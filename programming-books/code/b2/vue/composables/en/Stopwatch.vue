<script setup lang="ts">
import { useStopwatch } from "./composables/useStopwatch";

const { seconds, running, start, stop, reset } = useStopwatch();
</script>

<template>
  <p>
    <strong>{{ seconds }}</strong> seconds
    <button v-if="!running" type="button" @click="start">Start</button>
    <button v-else type="button" @click="stop">Stop</button>
    <button type="button" class="secondary" @click="reset">Reset</button>
  </p>
</template>
