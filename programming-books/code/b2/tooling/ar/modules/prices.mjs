// هذا السطر يعمل مرة واحدة، مهما كان عدد الوحدات التي تستورد هذا الملف
globalThis.priceLoads = (globalThis.priceLoads ?? 0) + 1;

// تصديرات مسماة: أي عدد في الوحدة
export const VAT = 0.14;
export function withVat(price) {
  return Math.round(price * (1 + VAT) * 100) / 100;
}

// تصدير افتراضي واحد في الوحدة على الأكثر
export default function formatPrice(value) {
  return `${value.toFixed(2)} جنيهاً`;
}
