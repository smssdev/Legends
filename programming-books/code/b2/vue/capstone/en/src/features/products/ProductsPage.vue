<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useProducts } from "../../api/queries";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";

const { t } = storeToRefs(useSettings());
const { data: products, isPending, isError, refetch } = useProducts();
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else>
    <h1>{{ t("products") }}</h1>
    <BaseCard>
      <table>
        <thead>
          <tr>
            <th scope="col">{{ t("name") }}</th>
            <th scope="col">{{ t("price") }}</th>
            <th scope="col">{{ t("stock") }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in products" :key="p.id">
            <td>
              <RouterLink :to="`/products/${p.id}`" :aria-label="`${t('edit')}: ${p.name}`">{{ p.name }}</RouterLink>
            </td>
            <td>{{ t.money(p.price) }}</td>
            <td>{{ p.stock }}</td>
          </tr>
        </tbody>
      </table>
    </BaseCard>
  </template>
</template>
