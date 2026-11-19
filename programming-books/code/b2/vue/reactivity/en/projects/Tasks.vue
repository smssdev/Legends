<script setup lang="ts">
import { computed, ref, watch } from "vue";

type Task = { id: number; text: string; done: boolean };

function load(): Task[] {
  try {
    return JSON.parse(localStorage.getItem("tasks") ?? "null") ?? defaults;
  } catch {
    return defaults;
  }
}
const defaults: Task[] = [{ id: 1, text: "Read chapter 5", done: true }];

const tasks = ref<Task[]>(load());
const text = ref("");
const left = computed(() => tasks.value.filter((t) => !t.done).length);

watch(tasks, (now) => localStorage.setItem("tasks", JSON.stringify(now)), { deep: true });

function add() {
  if (!text.value.trim()) return;
  tasks.value.push({ id: Date.now(), text: text.value.trim(), done: false });
  text.value = "";
}
</script>

<template>
  <section class="card">
    <h2>Tasks <small>({{ left }} left)</small></h2>
    <form @submit.prevent="add">
      <label for="task" class="sr-only">New task</label>
      <input id="task" v-model="text" placeholder="New task" />
    </form>
    <ul>
      <li v-for="task in tasks" :key="task.id">
        <label :class="{ done: task.done }"><input v-model="task.done" type="checkbox" /> {{ task.text }}</label>
      </li>
    </ul>
    <button type="button" class="secondary" @click="tasks = tasks.filter((t) => !t.done)">Clear done</button>
  </section>
</template>
