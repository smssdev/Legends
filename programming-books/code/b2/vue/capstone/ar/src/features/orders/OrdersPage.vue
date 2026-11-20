<script setup lang="ts">
import { computed } from "vue";
import { useRoute, useRouter, type LocationQueryRaw } from "vue-router";
import { storeToRefs } from "pinia";
import { useOrders } from "../../api/queries";
import { filterOrders, readFilters, STATUSES } from "../../lib/orders";
import { useSettings } from "../../settings";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";
import StatusBadge from "../../ui/StatusBadge.vue";

const { t } = storeToRefs(useSettings());
const route = useRoute();
const router = useRouter();
const { data, isPending, isError, refetch } = useOrders();

// المرشحات تعيش في العنوان، فتُحفظ القائمة المرشحة وتُشارك
const filters = computed(() => {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(route.query)) if (typeof value === "string") params.set(key, value);
  return readFilters(params);
});
const result = computed(() => (data.value ? filterOrders(data.value, filters.value) : null));

const link = (changes: LocationQueryRaw) => ({ query: { ...route.query, ...changes } });
const search = computed({
  get: () => filters.value.q,
  set: (q: string) => router.replace(link({ q: q || undefined, page: undefined })),
});
</script>

<template>
  <h1>{{ t("orders") }}</h1>
  <nav class="filters" :aria-label="t('status')">
    <RouterLink
      v-for="s in ['all', ...STATUSES] as const"
      :key="s"
      :to="link({ status: s === 'all' ? undefined : s, page: undefined })"
      :aria-current="filters.status === s ? 'page' : undefined"
    >
      {{ t(s) }}
    </RouterLink>
  </nav>
  <label for="q" class="sr-only">{{ t("search") }}</label>
  <input id="q" v-model="search" type="search" :placeholder="t('search')" />
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <p v-else-if="result && result.count === 0" role="status">{{ t("none") }}</p>
  <section v-else-if="result" class="card">
    <table>
      <caption class="sr-only">{{ t("found", { count: result.count }) }}</caption>
      <thead>
        <tr>
          <th scope="col">{{ t("order") }}</th>
          <th scope="col">{{ t("customer") }}</th>
          <th scope="col">{{ t("total") }}</th>
          <th scope="col">{{ t("status") }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="o in result.rows" :key="o.id">
          <td><RouterLink :to="`/orders/${o.id}`">#{{ o.id }}</RouterLink></td>
          <td>{{ o.customer }}</td>
          <td>{{ t.money(o.total) }}</td>
          <td><StatusBadge :status="o.status" /></td>
        </tr>
      </tbody>
    </table>
    <div class="pager">
      <RouterLink v-if="result.page > 1" :to="link({ page: String(result.page - 1) })">{{ t("previous") }}</RouterLink>
      <span v-else />
      <span>{{ t("page", { page: result.page, pages: result.pages }) }}</span>
      <RouterLink v-if="result.page < result.pages" :to="link({ page: String(result.page + 1) })">{{ t("next") }}</RouterLink>
      <span v-else />
    </div>
  </section>
</template>
