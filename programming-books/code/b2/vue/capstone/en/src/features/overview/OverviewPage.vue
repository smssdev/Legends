<script setup lang="ts">
import { computed } from "vue";
import { storeToRefs } from "pinia";
import { useOrders } from "../../api/queries";
import { overview } from "../../lib/orders";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";

const { t } = storeToRefs(useSettings());
const { data, isPending, isError, refetch } = useOrders();

const o = computed(() => (data.value ? overview(data.value, new Date()) : null));
const highest = computed(() => Math.max(1, ...(o.value?.days.map((d) => d.total) ?? [])));
const kpis = computed(() =>
  o.value
    ? [
        [t.value("revenue"), t.value.money(o.value.revenue)],
        [t.value("ordersCount"), String(o.value.orders)],
        [t.value("average"), t.value.money(o.value.average)],
        [t.value("toShip"), String(o.value.toShip)],
      ]
    : [],
);
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else-if="o">
    <h1>{{ t("overview") }}</h1>
    <div class="kpis">
      <figure v-for="[label, value] in kpis" :key="label" class="card kpi">
        <p>{{ label }}</p>
        <strong>{{ value }}</strong>
      </figure>
    </div>
    <BaseCard :title="t('lastWeek')">
      <ol class="bars">
        <li v-for="d in o.days" :key="d.day">
          <span class="bar" :style="{ blockSize: `${(d.total / highest) * 100}%` }" />
          <span aria-hidden="true">{{ t.weekday(d.day) }}</span>
          <span class="sr-only">{{ `${t.weekday(d.day)}: ${t.money(d.total)}` }}</span>
        </li>
      </ol>
    </BaseCard>
  </template>
</template>
