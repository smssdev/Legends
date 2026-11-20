<script setup lang="ts">
import { ref } from "vue";
import ToastList from "./ToastList.vue";
import { useToasts } from "./toasts";

const { notify } = useToasts();
const items = ref(["البرمجة من الصفر", "كوب بِت", "قبعة بِت"]);

function remove(name: string) {
  items.value = items.value.filter((n) => n !== name);
  notify(`حُذف: ${name}`, { label: "تراجع", run: () => items.value.push(name) });
}
</script>

<template>
  <section class="card">
    <div v-for="name in items" :key="name" class="row spread">
      <span>{{ name }}</span>
      <span class="row">
        <button type="button" @click="notify(`${name} أُضيف إلى السلة`)">أضف</button>
        <button type="button" class="secondary" :aria-label="`حُذف: ${name}`" @click="remove(name)">×</button>
      </span>
    </div>
  </section>
  <ToastList />
</template>
