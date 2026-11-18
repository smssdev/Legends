export type Product = { id: number; name: string; price: number };
export type Line = { product: Product; quantity: number };

export const catalogue: Product[] = [
  { id: 1, name: "Code from Zero", price: 25 },
  { id: 2, name: "Bit mug", price: 8 },
  { id: 3, name: "Bit cap", price: 12 },
];

export const FREE_DELIVERY = 50;
