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
  { id: 1, name: "Code from Zero", description: "The friendly first book of the series.", price: 25, category: "books", favourite: false },
  { id: 2, name: "Bit mug", description: "A big mug for long coding nights.", price: 8, category: "gifts", favourite: false },
  { id: 3, name: "Bit cap", description: "Keeps the sun out of your eyes.", price: 12, category: "gifts", favourite: true },
  { id: 4, name: "Bit sticker", description: "For your laptop.", price: 3, category: "gifts", favourite: false },
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
    throw new Error("The server is busy");
  }
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  product.favourite = favourite;
  return structuredClone(product);
}
