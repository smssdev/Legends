<script setup lang="ts">
import { storeToRefs } from "pinia";
import { ApiError } from "../../api/client";
import { useProduct, useSaveProduct } from "../../api/queries";
import type { Product } from "../../api/schemas";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";
import ProductForm from "./ProductForm.vue";

const props = defineProps<{ id: number }>();
const { t } = storeToRefs(useSettings());
const { data: product, isPending, isError, refetch } = useProduct(() => props.id);
const save = useSaveProduct();

async function onSave(changed: Product) {
  try {
    await save.mutateAsync(changed);
  } catch (error) {
    if (error instanceof ApiError && error.status === 422) return error.errors;
    throw error;
  }
}
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else-if="product">
    <h1>{{ product.name }}</h1>
    <BaseCard>
      <ProductForm :key="product.id" :product="product" :on-save="onSave" />
    </BaseCard>
    <RouterLink to="/products">{{ t("products") }}</RouterLink>
  </template>
</template>
