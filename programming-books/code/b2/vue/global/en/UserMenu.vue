<script setup lang="ts">
import { useAuth } from "./auth";

// Any component under the provider can read the user, however deep
const { user, signIn, signOut } = useAuth();
</script>

<template>
  <button v-if="!user" type="button" @click="signIn('Sara')">Sign in</button>
  <span v-else class="row">
    Hello, {{ user.name }}
    <button type="button" class="secondary" @click="signOut">Sign out</button>
  </span>
</template>
