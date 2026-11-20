<script setup lang="ts">
import ProfileCard, { type Person } from "./ProfileCard.vue";

const sara: Person = { name: "Sara", role: "Frontend developer", city: "Alexandria", projects: 12, followers: 340 };
</script>

<template>
  <ProfileCard :person="sara">
    <p>I build fast, accessible web apps with Vue and TypeScript.</p>
  </ProfileCard>
</template>
