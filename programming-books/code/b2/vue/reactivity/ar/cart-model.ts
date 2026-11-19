export type Product = { id: number; name: string; price: number };
export type Line = { product: Product; quantity: number };

export const catalogue: Product[] = [
  { id: 1, name: "البرمجة من الصفر", price: 25 },
  { id: 2, name: "كوب بِت", price: 8 },
  { id: 3, name: "قبعة بِت", price: 12 },
];

export const FREE_DELIVERY = 50;
