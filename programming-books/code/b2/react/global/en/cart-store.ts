import { create } from "zustand";
import { persist } from "zustand/middleware";

export type Product = { id: number; name: string; price: number };

type CartState = {
  lines: Record<number, { product: Product; quantity: number }>;
  add: (product: Product) => void;
  clear: () => void;
};

export const useCart = create<CartState>()(
  // persist saves the store in localStorage and loads it on the next visit
  persist(
    (set) => ({
      lines: {},
      add: (product) =>
        set((state) => {
          const line = state.lines[product.id];
          return { lines: { ...state.lines, [product.id]: { product, quantity: (line?.quantity ?? 0) + 1 } } };
        }),
      clear: () => set({ lines: {} }),
    }),
    { name: "cart" },
  ),
);

// Derived values, calculated from the state
export const selectCount = (s: CartState) => Object.values(s.lines).reduce((n, l) => n + l.quantity, 0);
export const selectTotal = (s: CartState) =>
  Object.values(s.lines).reduce((n, l) => n + l.quantity * l.product.price, 0);
