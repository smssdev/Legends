<script setup lang="ts">
const route = useRoute();
const { data: product, error } = await useFetch(`/api/products/${route.params.id}`);

// المنتج المفقود يصير 404 حقيقياً، يعرضه error.vue
if (error.value) throw createError({ statusCode: 404, statusMessage: "لم نجد هذه الصفحة.", fatal: true });

useSeoMeta({ title: () => product.value?.name, description: () => product.value?.description });
</script>

<template>
  <article v-if="product" class="card">
    <h1>{{ product.name }}</h1>
    <p>{{ product.description }}</p>
    <p class="price">{{ product.price }} جنيهاً</p>
    <AddToCart :name="product.name" />
    <p><NuxtLink to="/products">كل المنتجات</NuxtLink></p>
  </article>
</template>
