<script setup lang="ts">
import { computed } from "vue";
import { posts } from "./posts";

const props = defineProps<{ slug: string }>();
const post = computed(() => posts.find((p) => p.slug === props.slug));
</script>

<template>
  <article v-if="post" class="card">
    <h2>{{ post.title }}</h2>
    <p class="muted">بقلم بِت · {{ post.minutes }} دقائق قراءة</p>
    <p>{{ post.body }}</p>
  </article>
  <p v-else class="card">هذه التدوينة غير موجودة. <RouterLink to="/">اذهب إلى الرئيسية</RouterLink></p>
</template>
