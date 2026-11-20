<script setup lang="ts">
import { computed, ref } from "vue";

export type Person = { name: string; role: string; city: string; projects: number; followers: number };

const props = defineProps<{ person: Person }>();
const following = ref(false);
const followers = computed(() => props.person.followers + (following.value ? 1 : 0));
</script>

<template>
  <article class="profile">
    <div class="cover" />
    <div class="body">
      <div class="avatar" aria-hidden="true">{{ person.name[0] }}</div>
      <h2>{{ person.name }}</h2>
      <p class="meta">{{ person.role }} · {{ person.city }}</p>
      <slot />
      <div class="stats">
        <span><b>{{ person.projects }}</b>projects</span>
        <span><b>{{ followers }}</b>followers</span>
      </div>
      <button type="button" :class="{ secondary: following }" :aria-pressed="following" @click="following = !following">
        {{ following ? "Following" : "Follow" }}
      </button>
    </div>
  </article>
</template>
