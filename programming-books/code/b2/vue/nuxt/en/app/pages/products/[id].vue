<script setup lang="ts">
const route = useRoute();
const { data: product, error } = await useFetch(`/api/products/${route.params.id}`);

// A missing product becomes a real 404, shown by error.vue
if (error.value) throw createError({ statusCode: 404, statusMessage: "We could not find that page.", fatal: true });

useSeoMeta({ title: () => product.value?.name, description: () => product.value?.description });
</script>

<template>
  <article v-if="product" class="card">
    <h1>{{ product.name }}</h1>
    <p>{{ product.description }}</p>
    <p class="price">{{ product.price }} EGP</p>
    <AddToCart :name="product.name" />
    <p><NuxtLink to="/products">All products</NuxtLink></p>
  </article>
</template>
