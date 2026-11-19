<script setup lang="ts">
import { useStopwatch } from "./composables/useStopwatch";

const { seconds, running, start, stop, reset } = useStopwatch();
</script>

<template>
  <p>
    <strong>{{ seconds }}</strong> ثانية
    <button v-if="!running" type="button" @click="start">ابدأ</button>
    <button v-else type="button" @click="stop">أوقف</button>
    <button type="button" class="secondary" @click="reset">صفّر</button>
  </p>
</template>
