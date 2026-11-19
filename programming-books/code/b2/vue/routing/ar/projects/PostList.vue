<script setup lang="ts">
import { posts } from "./posts";
</script>

<template>
  <ul class="list card">
    <li v-for="post in posts" :key="post.slug">
      <RouterLink :to="{ name: 'post', params: { slug: post.slug } }">{{ post.title }}</RouterLink>
      <span class="muted">{{ post.minutes }} دقائق قراءة</span>
    </li>
  </ul>
</template>
