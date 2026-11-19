import Link from "next/link";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getProduct, getProducts } from "@/lib/products";
import { AddToCart } from "./AddToCart";

type Props = { params: Promise<{ id: string }> };

// Build one page per product at build time
export async function generateStaticParams() {
  const products = await getProducts();
  return products.map((p) => ({ id: String(p.id) }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const product = await getProduct(Number((await params).id));
  return { title: product?.name, description: product?.description };
}

export default async function ProductPage({ params }: Props) {
  const product = await getProduct(Number((await params).id));
  if (!product) notFound();
  return (
    <article className="card">
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <p className="price">
        {product.price} EGP
      </p>
      <AddToCart name={product.name} />
      <p>
        <Link href="/products">All products</Link>
      </p>
    </article>
  );
}
