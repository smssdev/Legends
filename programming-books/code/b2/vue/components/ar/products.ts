export type Product = {
  id: number;
  name: string;
  price: number;
  category: "books" | "gifts";
  isNew?: boolean;
  inStock: boolean;
};

export const products: Product[] = [
  { id: 1, name: "البرمجة من الصفر", price: 25, category: "books", isNew: true, inStock: true },
  { id: 2, name: "كوب بِت", price: 8, category: "gifts", inStock: true },
  { id: 3, name: "ملصق بِت", price: 3, category: "gifts", inStock: false },
  { id: 4, name: "قبعة بِت", price: 12, category: "gifts", isNew: true, inStock: true },
];
