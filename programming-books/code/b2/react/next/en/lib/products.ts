// A pretend database: in a real app, a query to PostgreSQL or a call to another service
export type Product = { id: number; name: string; description: string; price: number };

const products: Product[] = [
  { id: 1, name: "Code from Zero", description: "The friendly first book of the series.", price: 250 },
  { id: 2, name: "Bit mug", description: "A big mug for long coding nights.", price: 85 },
  { id: 3, name: "Bit cap", description: "Keeps the sun out of your eyes.", price: 120 },
];

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export async function getProducts(): Promise<Product[]> {
  await wait(300);
  return products;
}

export async function getProduct(id: number): Promise<Product | undefined> {
  await wait(300);
  return products.find((p) => p.id === id);
}
