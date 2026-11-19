<script setup lang="ts">
import { useQuery } from "@tanstack/vue-query";
import { getProduct, NotFoundError } from "../api";
import Skeleton from "./Skeleton.vue";

const props = defineProps<{ id: number }>();

const { data, error, isPending } = useQuery({
  queryKey: ["product", () => props.id],
  queryFn: () => getProduct(props.id),
  // Retry network errors twice, but never a product that does not exist
  retry: (count, e) => !(e instanceof NotFoundError) && count < 2,
});
</script>

<template>
  <Skeleton v-if="isPending" />
  <p v-else-if="error" class="card error">
    {{ error instanceof NotFoundError ? "There is no product with this number." : error.message }}
  </p>
  <article v-else-if="data" class="card">
    <h2>{{ data.name }}</h2>
    <p>{{ data.description }}</p>
    <p class="price">{{ data.price }} EGP</p>
    <RouterLink to="/products">← Back to products</RouterLink>
  </article>
</template>
