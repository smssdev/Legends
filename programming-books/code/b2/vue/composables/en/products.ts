export type Product = { id: number; name: string; price: number };

const catalogue: Product[] = [
  { id: 1, name: "Code from Zero", price: 25 },
  { id: 2, name: "Bit mug", price: 8 },
  { id: 3, name: "Bit cap", price: 12 },
  { id: 4, name: "Bit sticker", price: 3 },
];

// A pretend server: answers after a delay, and can be cancelled like fetch
export function searchProducts(query: string, signal: AbortSignal): Promise<Product[]> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const q = query.trim().toLowerCase();
      resolve(catalogue.filter((p) => p.name.toLowerCase().includes(q)));
    }, 400);
    signal.addEventListener("abort", () => {
      clearTimeout(timer);
      reject(signal.reason);
    });
  });
}
