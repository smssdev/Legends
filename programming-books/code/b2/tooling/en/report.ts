import type { Product } from "./products.ts";
import { formatPrice } from "./format.ts";

// Imagine a big charting library here: only people who press the button download it
export function buildReport(items: Product[]): HTMLElement {
  const table = document.createElement("table");
  for (const item of items) {
    const row = table.insertRow();
    row.insertCell().textContent = item.name;
    row.insertCell().textContent = formatPrice(item.price);
  }
  const total = items.reduce((sum, item) => sum + item.price, 0);
  const foot = table.createTFoot().insertRow();
  foot.insertCell().textContent = "Total";
  foot.insertCell().textContent = formatPrice(total);
  return table;
}
