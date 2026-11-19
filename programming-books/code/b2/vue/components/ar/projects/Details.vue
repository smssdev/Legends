<script setup lang="ts">
import TabList from "./TabList.vue";
</script>

<template>
  <TabList label="تفاصيل المنتج" :labels="['الوصف', 'المراجعات', 'الشحن']">
    <template #tab-0><p>دليل ودود يأخذك من أول سطر كود إلى أول تطبيق لك.</p></template>
    <template #tab-1><p>«واضح ولطيف وعملي. أنهاه ابني في شهر.» ★★★★★</p></template>
    <template #tab-2><p>توصيل مجاني داخل مصر للطلبات فوق 50 جنيهاً. يصل خلال 2 إلى 4 أيام.</p></template>
  </TabList>
</template>
