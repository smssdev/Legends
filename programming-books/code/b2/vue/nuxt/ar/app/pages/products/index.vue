<script setup lang="ts">
// يعمل على الخادم في الزيارة الأولى، ويستلم المتصفح البيانات مع الصفحة فلا يسأل مرة أخرى
const { data: products } = await useFetch("/api/products");
// useState تحمل قيمة الخادم إلى المتصفح، فيرسم الاثنان الوقت نفسه
const rendered = useState("rendered", () => new Date().toISOString().slice(11, 19));

useSeoMeta({ title: "المنتجات", description: "كتب وأكواب وملصقات لمن يحبون البرمجة." });
</script>

<template>
  <section class="card">
    <h1>المنتجات</h1>
    <ul class="list">
      <li v-for="p in products" :key="p.id">
        <NuxtLink :to="`/products/${p.id}`">{{ p.name }}</NuxtLink>
        <span class="price">{{ p.price }} جنيهاً</span>
      </li>
    </ul>
    <p class="muted">رُسمت على الخادم الساعة {{ rendered }} UTC</p>
  </section>
</template>
