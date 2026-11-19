<script setup lang="ts">
import { ref } from "vue";

const props = defineProps<{ initial: number }>();
const likes = ref(props.initial);
const liked = ref(false);

function toggle() {
  liked.value = !liked.value;
  likes.value += liked.value ? 1 : -1;
}
</script>

<template>
  <button type="button" :class="{ secondary: !liked }" :aria-pressed="liked" @click="toggle">
    {{ liked ? "♥ Liked" : "♡ Like" }} · {{ likes }} likes
  </button>
</template>
