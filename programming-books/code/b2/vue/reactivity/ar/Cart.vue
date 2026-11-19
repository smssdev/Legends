<script setup lang="ts">
import { computed, ref } from "vue";
import { catalogue, FREE_DELIVERY, type Line, type Product } from "./cart-model";

// السطور وحدها حالة، وكل ما عداها محسوب منها
const lines = ref<Line[]>([]);

const count = computed(() => lines.value.reduce((n, l) => n + l.quantity, 0));
const total = computed(() => lines.value.reduce((sum, l) => sum + l.product.price * l.quantity, 0));
const missing = computed(() => Math.max(0, FREE_DELIVERY - total.value));

function add(product: Product) {
  const line = lines.value.find((l) => l.product.id === product.id);
  if (line) line.quantity++;
  else lines.value.push({ product, quantity: 1 });
}

function remove(id: number) {
  lines.value = lines.value.filter((l) => l.product.id !== id);
}
</script>

<template>
  <section class="cart">
    <div class="row">
      <button v-for="p in catalogue" :key="p.id" type="button" class="secondary" @click="add(p)">
        أضف {{ p.name }}
      </button>
    </div>
    <p v-if="lines.length === 0" class="muted">سلتك فارغة.</p>
    <ul v-else>
      <li v-for="line in lines" :key="line.product.id">
        <span>{{ line.product.name }} × {{ line.quantity }}</span>
        <button type="button" class="secondary" @click="remove(line.product.id)">احذف</button>
      </li>
    </ul>
    <p>العناصر: {{ count }} · <span class="total">المجموع: {{ total }} جنيهاً</span></p>
    <div class="bar" aria-hidden="true"><span :style="{ width: `${Math.min(100, (total / 50) * 100)}%` }" /></div>
    <p v-if="missing === 0" class="free">توصيل مجاني!</p>
    <p v-else class="muted">{{ missing }} جنيهاً أخرى للتوصيل المجاني</p>
  </section>
</template>
