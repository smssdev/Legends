import Link from "next/link";
import type { Metadata } from "next";
import { cacheLife } from "next/cache";
import { getProducts } from "@/lib/products";

export const metadata: Metadata = { title: "المنتجات" };

// هذا المكوّن يعمل على الخادم فقط: يستطيع قراءة قاعدة البيانات مباشرة
export default async function ProductsPage() {
  "use cache";
  cacheLife("minutes"); // خزّن الصفحة وأعد بناءها مرة في الدقيقة على الأكثر
  const products = await getProducts();
  return (
    <section className="card">
      <h1>المنتجات</h1>
      <ul className="list">
        {products.map((p) => (
          <li key={p.id}>
            <Link href={`/products/${p.id}`}>{p.name}</Link>
            <span className="price">
              {p.price} جنيهاً
            </span>
          </li>
        ))}
      </ul>
      <p className="muted">
        رُسمت على الخادم الساعة {new Date().toISOString().slice(11, 19)} UTC
      </p>
    </section>
  );
}
