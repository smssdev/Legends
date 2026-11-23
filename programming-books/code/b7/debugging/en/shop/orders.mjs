import {MENU} from "./menu.mjs";

export function priceOf(name) {
  const drink = MENU.find((d) => d.name === name);
  return drink.price;
}

export function total(order) {
  return order.items.reduce((sum, item) => sum + priceOf(item.name) * item.count, 0);
}
