type Item = { id: number; price: number };
let items: Item[] = [];
export function addToCart(item: Item) {
  items = [...items, item];
}
export function useCart<T>(select: (s: { count: number }) => T): T {
  return select({ count: items.length });
}
