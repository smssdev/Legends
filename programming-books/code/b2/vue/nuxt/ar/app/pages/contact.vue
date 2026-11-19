<script setup lang="ts">
useSeoMeta({ title: "تواصل معنا" });

const form = reactive({ name: "", message: "" });
const errors = ref<Record<string, string>>({});
const done = ref("");
const sending = ref(false);

async function send() {
  sending.value = true;
  try {
    const answer = await $fetch("/api/contact", { method: "POST", body: form });
    done.value = answer.message;
  } catch (e) {
    errors.value = (e as { data?: { data?: { errors?: Record<string, string> } } }).data?.data?.errors ?? {};
  } finally {
    sending.value = false;
  }
}
</script>

<template>
  <section class="card">
    <h1>تواصل معنا</h1>
    <p v-if="done" class="done" role="status">{{ done }}</p>
    <form v-else novalidate @submit.prevent="send">
      <label for="name">الاسم</label>
      <input id="name" v-model="form.name" autocomplete="name" :aria-invalid="!!errors.name" aria-describedby="name-error" />
      <p v-if="errors.name" id="name-error" class="error">{{ errors.name }}</p>
      <label for="message">الرسالة</label>
      <textarea id="message" v-model="form.message" rows="3" :aria-invalid="!!errors.message" aria-describedby="message-error" />
      <p v-if="errors.message" id="message-error" class="error">{{ errors.message }}</p>
      <p>
        <button type="submit" :disabled="sending">{{ sending ? "جارٍ الإرسال…" : "أرسل" }}</button>
      </p>
    </form>
  </section>
</template>
