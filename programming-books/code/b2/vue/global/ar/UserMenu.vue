<script setup lang="ts">
import { useAuth } from "./auth";

// أي مكوّن تحت المزوِّد يقرأ المستخدم، مهما كان عمقه
const { user, signIn, signOut } = useAuth();
</script>

<template>
  <button v-if="!user" type="button" @click="signIn('سارة')">سجّل الدخول</button>
  <span v-else class="row">
    أهلاً، {{ user.name }}
    <button type="button" class="secondary" @click="signOut">سجّل الخروج</button>
  </span>
</template>
