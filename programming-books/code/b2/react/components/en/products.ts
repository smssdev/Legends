export type Product = {
  id: number;
  name: string;
  price: number;
  category: "books" | "gifts";
  isNew?: boolean;
  inStock: boolean;
};

export const products: Product[] = [
  { id: 1, name: "Code from Zero", price: 25, category: "books", isNew: true, inStock: true },
  { id: 2, name: "Bit mug", price: 8, category: "gifts", inStock: true },
  { id: 3, name: "Bit sticker", price: 3, category: "gifts", inStock: false },
  { id: 4, name: "Bit cap", price: 12, category: "gifts", isNew: true, inStock: true },
];
