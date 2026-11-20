import { getJson } from "../../shared/api/client";

export type Product = { id: number; name: string; price: number };
export function useProducts(): Product[] {
  void getJson("/api/products");
  return [];
}
