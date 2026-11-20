import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "./client";
import type { Order, OrderStatus, Product } from "./schemas";

// مكان واحد لمفاتيح الاستعلامات، فالقراءة والإبطال يستخدمان الأسماء نفسها دائماً
export const keys = {
  orders: ["orders"] as const,
  order: (id: number) => ["orders", id] as const,
  products: ["products"] as const,
  product: (id: number) => ["products", id] as const,
};

export const useOrders = () => useQuery({ queryKey: keys.orders, queryFn: api.orders });
export const useOrder = (id: number) => useQuery({ queryKey: keys.order(id), queryFn: () => api.order(id) });
export const useProducts = () => useQuery({ queryKey: keys.products, queryFn: api.products });
export const useProduct = (id: number) => useQuery({ queryKey: keys.product(id), queryFn: () => api.product(id) });

export function useSetStatus(id: number) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (status: OrderStatus) => api.setStatus(id, status),
    // اعرض الحالة الجديدة فوراً، وأعد القديمة إن رفض الخادم
    onMutate: async (status) => {
      await client.cancelQueries({ queryKey: keys.order(id) });
      const before = client.getQueryData<Order>(keys.order(id));
      if (before) client.setQueryData<Order>(keys.order(id), { ...before, status });
      return { before };
    },
    onError: (_error, _status, context) => {
      if (context?.before) client.setQueryData(keys.order(id), context.before);
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
