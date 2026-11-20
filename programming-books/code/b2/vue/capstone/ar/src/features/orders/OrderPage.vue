<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useOrder, useSetStatus } from "../../api/queries";
import { STATUSES } from "../../lib/orders";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";
import StatusBadge from "../../ui/StatusBadge.vue";

const props = defineProps<{ id: number }>();
const { t } = storeToRefs(useSettings());
const { data: order, isPending, isError, refetch } = useOrder(() => props.id);
const setStatus = useSetStatus(() => props.id);
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else-if="order">
    <h1>{{ t("orderTitle", { id: String(order.id) }) }}</h1>
    <BaseCard>
      <dl>
        <dt>{{ t("customer") }}</dt>
        <dd>{{ order.customer }}</dd>
        <dt>{{ t("city") }}</dt>
        <dd>{{ order.city }}</dd>
        <dt>{{ t("date") }}</dt>
        <dd>{{ t.date(order.createdAt) }}</dd>
        <dt>{{ t("total") }}</dt>
        <dd>{{ t.money(order.total) }}</dd>
        <dt>{{ t("status") }}</dt>
        <dd aria-live="polite"><StatusBadge :status="order.status" /></dd>
      </dl>
      <p>{{ t("markAs") }}</p>
      <div class="actions">
        <button
          v-for="s in STATUSES.filter((s) => s !== order!.status)"
          :key="s"
          type="button"
          class="secondary"
          :disabled="setStatus.isPending.value"
          @click="setStatus.mutate(s)"
        >
          {{ t(s) }}
        </button>
      </div>
      <p v-if="setStatus.isError.value" role="alert" class="error">{{ t("failed") }}</p>
    </BaseCard>
    <RouterLink to="/orders">{{ t("allOrders") }}</RouterLink>
  </template>
</template>
