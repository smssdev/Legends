// This line runs once, however many modules import this file
globalThis.priceLoads = (globalThis.priceLoads ?? 0) + 1;

// Named exports: any number per module
export const VAT = 0.14;
export function withVat(price) {
  return Math.round(price * (1 + VAT) * 100) / 100;
}

// One default export per module, at most
export default function formatPrice(value) {
  return `${value.toFixed(2)} EGP`;
}
