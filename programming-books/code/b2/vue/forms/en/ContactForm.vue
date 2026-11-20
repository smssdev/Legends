<script setup lang="ts">
import { ref } from "vue";
import { contactSchema } from "./contact-schema";
import FormField from "./FormField.vue";
import { useForm } from "./useForm";

const { values, errors, submitting, blur, handleSubmit } = useForm(contactSchema, {
  name: "",
  email: "",
  age: "",
  message: "",
});
const sent = ref(false);

const submit = handleSubmit(async (contact) => {
  // contact.age is a number here, not text: the schema converted it
  await new Promise((resolve) => setTimeout(resolve, 600)); // send it to the server
  sent.value = true;
});
</script>

<template>
  <p v-if="sent" class="card done" role="status">Thank you! We will reply within two days.</p>
  <form v-else novalidate @submit.prevent="submit">
    <FormField id="name" v-slot="attrs" label="Full name" :error="errors.name">
      <input v-bind="attrs" v-model="values.name" autocomplete="name" @blur="blur('name')" />
    </FormField>
    <FormField id="email" v-slot="attrs" label="Email" :error="errors.email">
      <input v-bind="attrs" v-model="values.email" type="email" autocomplete="email" dir="ltr" @blur="blur('email')" />
    </FormField>
    <FormField id="age" v-slot="attrs" label="Age" :error="errors.age">
      <input v-bind="attrs" v-model="values.age" inputmode="numeric" @blur="blur('age')" />
    </FormField>
    <FormField id="message" v-slot="attrs" label="Message" :error="errors.message">
      <textarea v-bind="attrs" v-model="values.message" rows="3" @blur="blur('message')" />
    </FormField>
    <button type="submit" :disabled="submitting">{{ submitting ? "Sending…" : "Send" }}</button>
  </form>
</template>
