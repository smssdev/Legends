<script setup lang="ts">
import ProfileCard, { type Person } from "./ProfileCard.vue";

const sara: Person = { name: "سارة", role: "مطورة واجهات", city: "الإسكندرية", projects: 12, followers: 340 };
</script>

<template>
  <ProfileCard :person="sara">
    <p>أبني تطبيقات ويب سريعة وسهلة الوصول بـ Vue وTypeScript.</p>
  </ProfileCard>
</template>
