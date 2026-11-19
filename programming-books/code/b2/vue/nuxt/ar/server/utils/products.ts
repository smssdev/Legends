// قاعدة بيانات وهمية: في تطبيق حقيقي، استعلام إلى PostgreSQL أو استدعاء خدمة أخرى
export type Product = { id: number; name: string; description: string; price: number };

const products: Product[] = [
  { id: 1, name: "البرمجة من الصفر", description: "الكتاب الأول الودود في السلسلة.", price: 250 },
  { id: 2, name: "كوب بِت", description: "كوب كبير لليالي البرمجة الطويلة.", price: 85 },
  { id: 3, name: "قبعة بِت", description: "تحمي عينيك من الشمس.", price: 120 },
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
