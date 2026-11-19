<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useCart } from "./stores/cart";

// storeToRefs تُبقي الحالة والقيم المشتقة تفاعلية بعد التفكيك، والأفعال دوال عادية
const { count } = storeToRefs(useCart());
</script>

<template>
  <span class="row">السلة <span class="badge">{{ count }}</span></span>
</template>
