import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";
import { toValue, type MaybeRefOrGetter } from "vue";
import { api } from "./client";
import type { Order, OrderStatus, Product } from "./schemas";

// One place for query keys, so reading and invalidating always use the same names
export const keys = {
  orders: ["orders"] as const,
  order: (id: number) => ["orders", id] as const,
  products: ["products"] as const,
  product: (id: number) => ["products", id] as const,
};

export const useOrders = () => useQuery({ queryKey: keys.orders, queryFn: api.orders });
export const useProducts = () => useQuery({ queryKey: keys.products, queryFn: api.products });

export function useOrder(id: MaybeRefOrGetter<number>) {
  return useQuery({ queryKey: ["orders", id], queryFn: () => api.order(toValue(id)) });
}

export function useProduct(id: MaybeRefOrGetter<number>) {
  return useQuery({ queryKey: ["products", id], queryFn: () => api.product(toValue(id)) });
}

export function useSetStatus(id: MaybeRefOrGetter<number>) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (status: OrderStatus) => api.setStatus(toValue(id), status),
    // Show the new status at once; put the old one back if the server refuses
    onMutate: async (status) => {
      const key = keys.order(toValue(id));
      await client.cancelQueries({ queryKey: key });
      const before = client.getQueryData<Order>(key);
      if (before) client.setQueryData<Order>(key, { ...before, status });
      return { before };
    },
    onError: (_error, _status, context) => {
      if (context?.before) client.setQueryData(keys.order(toValue(id)), context.before);
    },
    onSettled: () => client.invalidateQueries({ queryKey: keys.orders }),
  });
}

export function useSaveProduct() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (product: Product) => api.saveProduct(product),
    onSuccess: (saved) => {
      client.setQueryData(keys.product(saved.id), saved);
      void client.invalidateQueries({ queryKey: keys.products, exact: true });
    },
  });
}
