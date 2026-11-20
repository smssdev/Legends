import Link from "next/link";
import type { Metadata } from "next";
import { cacheLife } from "next/cache";
import { getProducts } from "@/lib/products";

export const metadata: Metadata = { title: "Products" };

// This component runs only on the server: it can read the database directly
export default async function ProductsPage() {
  "use cache";
  cacheLife("minutes"); // Cache the page and rebuild it at most about once a minute
  const products = await getProducts();
  return (
    <section className="card">
      <h1>Products</h1>
      <ul className="list">
        {products.map((p) => (
          <li key={p.id}>
            <Link href={`/products/${p.id}`}>{p.name}</Link>
            <span className="price">
              {p.price} EGP
            </span>
          </li>
        ))}
      </ul>
      <p className="muted">
        Rendered on the server at {new Date().toISOString().slice(11, 19)} UTC
      </p>
    </section>
  );
}
