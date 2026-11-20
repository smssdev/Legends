import type { Product } from "./products.ts";
import { formatPrice } from "./format.ts";

// تخيّل هنا مكتبة رسوم بيانية كبيرة: لا ينزّلها إلا من يضغط الزر
export function buildReport(items: Product[]): HTMLElement {
  const table = document.createElement("table");
  for (const item of items) {
    const row = table.insertRow();
    row.insertCell().textContent = item.name;
    row.insertCell().textContent = formatPrice(item.price);
  }
  const total = items.reduce((sum, item) => sum + item.price, 0);
  const foot = table.createTFoot().insertRow();
  foot.insertCell().textContent = "المجموع";
  foot.insertCell().textContent = formatPrice(total);
  return table;
}
