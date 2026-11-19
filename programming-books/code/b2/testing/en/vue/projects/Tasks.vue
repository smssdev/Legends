<script setup lang="ts">
import { computed, ref } from "vue";

type Task = { id: number; text: string; done: boolean };

const { initial = [] } = defineProps<{ initial?: Task[] }>();
const tasks = ref<Task[]>(structuredClone(initial));
const text = ref("");
const left = computed(() => tasks.value.filter((t) => !t.done).length);

function add() {
  if (!text.value.trim()) return;
  tasks.value.push({ id: tasks.value.length + 1, text: text.value.trim(), done: false });
  text.value = "";
}
</script>

<template>
  <section aria-labelledby="tasks-title">
    <h2 id="tasks-title">Tasks</h2>
    <form @submit.prevent="add">
      <input v-model="text" aria-label="New task" />
      <button type="submit">Add</button>
    </form>
    <ul>
      <li v-for="t in tasks" :key="t.id">
        <label><input v-model="t.done" type="checkbox" /> {{ t.text }}</label>
      </li>
    </ul>
    <p role="status">{{ left }} left</p>
  </section>
</template>
