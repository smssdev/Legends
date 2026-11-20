<script setup lang="ts">
import { useQuery } from "@tanstack/vue-query";
import { getProduct, NotFoundError } from "../api";
import Skeleton from "./Skeleton.vue";

const props = defineProps<{ id: number }>();

const { data, error, isPending } = useQuery({
  queryKey: ["product", () => props.id],
  queryFn: () => getProduct(props.id),
  // أعد المحاولة مرتين لأخطاء الشبكة، لكن لا تعدها أبداً لمنتج غير موجود
  retry: (count, e) => !(e instanceof NotFoundError) && count < 2,
});
</script>

<template>
  <Skeleton v-if="isPending" />
  <p v-else-if="error" class="card error">
    {{ error instanceof NotFoundError ? "لا يوجد منتج بهذا الرقم." : error.message }}
  </p>
  <article v-else-if="data" class="card">
    <h2>{{ data.name }}</h2>
    <p>{{ data.description }}</p>
    <p class="price">{{ data.price }} جنيهاً</p>
    <RouterLink to="/products">→ عودة إلى المنتجات</RouterLink>
  </article>
</template>
