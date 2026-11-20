<script setup lang="ts">
import { computed, ref } from "vue";
import { storeToRefs } from "pinia";
import * as z from "zod";
import type { Product } from "../../api/schemas";
import { useForm } from "../../lib/useForm";
import { useSettings } from "../../settings";

type Fields = "name" | "price" | "stock";
const props = defineProps<{
  product: Product;
  onSave: (product: Product) => Promise<Partial<Record<Fields, string>> | void>;
}>();
const { t } = storeToRefs(useSettings());

// The schema is built with the current language, so its messages are translated
const schema = computed(() =>
  z.object({
    name: z.string().trim().min(2, t.value("nameError")).max(40, t.value("nameError")),
    price: z.coerce.number<string>().int(t.value("priceError")).positive(t.value("priceError")),
    stock: z.coerce.number<string>().int(t.value("stockError")).min(0, t.value("stockError")),
  }),
);
const { values, errors, submitting, blur, handleSubmit } = useForm(schema.value, {
  name: props.product.name,
  price: String(props.product.price),
  stock: String(props.product.stock),
});
const saved = ref(false);

const submit = handleSubmit(async (data) => {
  saved.value = false;
  const fromServer = await props.onSave({ ...props.product, ...data });
  if (!fromServer) saved.value = true;
  return fromServer;
});
</script>

<template>
  <form novalidate @submit.prevent="submit">
    <template v-for="field in (['name', 'price', 'stock'] as const)" :key="field">
      <label :for="field">{{ t(field) }}</label>
      <input
        :id="field"
        v-model="values[field]"
        :inputmode="field === 'name' ? undefined : 'numeric'"
        :aria-invalid="!!errors[field]"
        :aria-describedby="`${field}-error`"
        @blur="blur(field)"
      />
      <p v-if="errors[field]" :id="`${field}-error`" class="error">{{ errors[field] }}</p>
    </template>
    <p>
      <button type="submit" :disabled="submitting">{{ submitting ? t("saving") : t("save") }}</button>
    </p>
    <p v-if="saved" role="status" class="done">{{ t("saved") }}</p>
  </form>
</template>
