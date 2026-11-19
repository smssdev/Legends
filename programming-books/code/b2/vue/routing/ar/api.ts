// A pretend server for this chapter. A real app would call fetch("/api/…") here.
export type Product = {
  id: number;
  name: string;
  description: string;
  price: number;
  category: "books" | "gifts";
  favourite: boolean;
};

const products: Product[] = [
  { id: 1, name: "البرمجة من الصفر", description: "الكتاب الأول الودود في السلسلة.", price: 25, category: "books", favourite: false },
  { id: 2, name: "كوب بِت", description: "كوب كبير لليالي البرمجة الطويلة.", price: 8, category: "gifts", favourite: false },
  { id: 3, name: "قبعة بِت", description: "تحمي عينيك من الشمس.", price: 12, category: "gifts", favourite: true },
  { id: 4, name: "ملصق بِت", description: "لحاسوبك المحمول.", price: 3, category: "gifts", favourite: false },
];

export class NotFoundError extends Error {}

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export async function getProducts(category: string | null): Promise<Product[]> {
  await wait(300);
  const list = category ? products.filter((p) => p.category === category) : products;
  return structuredClone(list);
}

export async function getProduct(id: number): Promise<Product> {
  await wait(300);
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  return structuredClone(product);
}

export const server = { failNextSave: false };

export async function setFavourite(id: number, favourite: boolean): Promise<Product> {
  await wait(400);
  if (server.failNextSave) {
    server.failNextSave = false;
    throw new Error("الخادم مشغول");
  }
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  product.favourite = favourite;
  return structuredClone(product);
}
