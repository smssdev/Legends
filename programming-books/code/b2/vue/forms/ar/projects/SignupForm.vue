<script setup lang="ts">
import { ref } from "vue";
import * as z from "zod";
import FormField from "../FormField.vue";
import { useForm } from "../useForm";
import { signupSchema } from "./signup-schema";

// refine() wraps the object, so useForm receives the inner object and the full schema checks the rest
const fields = z.object({ ...signupSchema.shape, terms: z.boolean() });
const { values, errors, submitting, blur, handleSubmit } = useForm(fields, {
  email: "",
  password: "",
  confirm: "",
  terms: false,
});
const created = ref(false);

const submit = handleSubmit(async (data) => {
  const result = signupSchema.safeParse(data);
  if (!result.success) {
    return Object.fromEntries(result.error.issues.map((i) => [String(i.path[0]), i.message]));
  }
  await new Promise((resolve) => setTimeout(resolve, 400));
  // خادم وهمي: هذا البريد مستخدم بالفعل
  if (data.email === "sara@example.com") return { email: "لهذا البريد حساب بالفعل. هل تريد تسجيل الدخول؟" };
  created.value = true;
});
</script>

<template>
  <p v-if="created" class="card done" role="status">حسابك جاهز.</p>
  <form v-else novalidate @submit.prevent="submit">
    <FormField id="email" v-slot="attrs" label="البريد الإلكتروني" :error="errors.email">
      <input v-bind="attrs" v-model="values.email" type="email" autocomplete="email" dir="ltr" @blur="blur('email')" />
    </FormField>
    <FormField id="password" v-slot="attrs" label="كلمة المرور" :error="errors.password">
      <input v-bind="attrs" v-model="values.password" type="password" autocomplete="new-password" dir="ltr" @blur="blur('password')" />
    </FormField>
    <FormField id="confirm" v-slot="attrs" label="أكّد كلمة المرور" :error="errors.confirm">
      <input v-bind="attrs" v-model="values.confirm" type="password" autocomplete="new-password" dir="ltr" @blur="blur('confirm')" />
    </FormField>
    <div class="field">
      <label class="check"><input v-model="values.terms" type="checkbox" :aria-invalid="!!errors.terms" /> أوافق على الشروط</label>
      <p v-if="errors.terms" class="error">{{ errors.terms }}</p>
    </div>
    <button type="submit" :disabled="submitting">أنشئ الحساب</button>
  </form>
</template>
