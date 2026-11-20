import Link from "next/link";

export default function Home() {
  return (
    <section className="card">
      <h1>Welcome to Bit's shop</h1>
      <p>Books, mugs and stickers for people who love to code.</p>
      <Link href="/products">Browse the products</Link>
    </section>
  );
}
