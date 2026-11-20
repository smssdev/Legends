<script setup lang="ts">
import { ref } from "vue";
import { signIn as defaultSignIn } from "./api";

const { signIn = defaultSignIn } = defineProps<{ signIn?: typeof defaultSignIn }>();
const error = ref("");
const user = ref<string | null>(null);
const busy = ref(false);

async function submit(event: SubmitEvent) {
  const data = new FormData(event.target as HTMLFormElement);
  const email = String(data.get("email") ?? "").trim();
  if (!email) return (error.value = "Please enter your email.");
  busy.value = true;
  try {
    user.value = (await signIn(email, String(data.get("password") ?? ""))).name;
  } catch (e) {
    error.value = (e as Error).message;
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <h2 v-if="user">Welcome back, {{ user }}!</h2>
  <form v-else novalidate :aria-describedby="error ? 'login-error' : undefined" @submit.prevent="submit">
    <label for="email">Email</label>
    <input id="email" name="email" type="email" autocomplete="email" dir="ltr" />
    <label for="password">Password</label>
    <input id="password" name="password" type="password" autocomplete="current-password" dir="ltr" />
    <p v-if="error" id="login-error" role="alert">{{ error }}</p>
    <button type="submit" :disabled="busy">{{ busy ? "Signing in…" : "Sign in" }}</button>
  </form>
</template>
