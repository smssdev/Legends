<script setup lang="ts">
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";
import { getProduct, setFavourite, type Product } from "../api";

const props = defineProps<{ id: number }>();
const client = useQueryClient();
const key = ["product", props.id];
const product = useQuery({ queryKey: key, queryFn: () => getProduct(props.id) });

const mutation = useMutation({
  mutationFn: (favourite: boolean) => setFavourite(props.id, favourite),
  // 1. Before the server answers: change the cache, and remember the old value
  onMutate: async (favourite) => {
    await client.cancelQueries({ queryKey: key });
    const previous = client.getQueryData<Product>(key);
    client.setQueryData<Product>(key, (old) => (old ? { ...old, favourite } : old));
    return { previous };
  },
  // 2. If it fails: put the old value back
  onError: (_error, _favourite, context) => client.setQueryData(key, context?.previous),
  // 3. Either way: ask the server for the truth
  onSettled: () => client.invalidateQueries({ queryKey: key }),
});
</script>

<template>
  <p v-if="!product.data.value" class="muted">Loading…</p>
  <div v-else class="card">
    <h2>{{ product.data.value.name }}</h2>
    <button
      type="button"
      :aria-pressed="product.data.value.favourite"
      :class="{ secondary: !product.data.value.favourite }"
      @click="mutation.mutate(!product.data.value.favourite)"
    >
      {{ product.data.value.favourite ? "♥" : "♡" }} Favourite
    </button>
    <span v-if="mutation.isPending.value" class="muted"> Saving…</span>
    <p v-if="mutation.isError.value" class="error" role="alert">Could not save. The change was undone.</p>
  </div>
</template>
