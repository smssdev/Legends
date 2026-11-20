<script setup lang="ts">
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";
import { getProduct, setFavourite, type Product } from "../api";

const props = defineProps<{ id: number }>();
const client = useQueryClient();
const key = ["product", props.id];
const product = useQuery({ queryKey: key, queryFn: () => getProduct(props.id) });

const mutation = useMutation({
  mutationFn: (favourite: boolean) => setFavourite(props.id, favourite),
  // 1. قبل رد الخادم: غيّر الذاكرة، وتذكّر القيمة القديمة
  onMutate: async (favourite) => {
    await client.cancelQueries({ queryKey: key });
    const previous = client.getQueryData<Product>(key);
    client.setQueryData<Product>(key, (old) => (old ? { ...old, favourite } : old));
    return { previous };
  },
  // 2. إن فشل: أعد القيمة القديمة
  onError: (_error, _favourite, context) => client.setQueryData(key, context?.previous),
  // 3. في الحالتين: اسأل الخادم عن الحقيقة
  onSettled: () => client.invalidateQueries({ queryKey: key }),
});
</script>

<template>
  <p v-if="!product.data.value" class="muted">جارٍ التحميل…</p>
  <div v-else class="card">
    <h2>{{ product.data.value.name }}</h2>
    <button
      type="button"
      :aria-pressed="product.data.value.favourite"
      :class="{ secondary: !product.data.value.favourite }"
      @click="mutation.mutate(!product.data.value.favourite)"
    >
      {{ product.data.value.favourite ? "♥" : "♡" }} مفضّل
    </button>
    <span v-if="mutation.isPending.value" class="muted"> جارٍ الحفظ…</span>
    <p v-if="mutation.isError.value" class="error" role="alert">تعذّر الحفظ، وأُلغي التغيير.</p>
  </div>
</template>
