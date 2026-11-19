<script setup lang="ts">
// Runs on the server for the first visit; the browser receives the data with the page, and does not ask again
const { data: products } = await useFetch("/api/products");
// useState carries the server's value to the browser, so both draw the same time
const rendered = useState("rendered", () => new Date().toISOString().slice(11, 19));

useSeoMeta({ title: "Products", description: "Books, mugs and stickers for people who love to code." });
</script>

<template>
  <section class="card">
    <h1>Products</h1>
    <ul class="list">
      <li v-for="p in products" :key="p.id">
        <NuxtLink :to="`/products/${p.id}`">{{ p.name }}</NuxtLink>
        <span class="price">{{ p.price }} EGP</span>
      </li>
    </ul>
    <p class="muted">Rendered on the server at {{ rendered }} UTC</p>
  </section>
</template>
