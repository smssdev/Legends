import Link from "next/link";

export default function NotFound() {
  return (
    <section className="card">
      <h1>404</h1>
      <p>We could not find that page.</p>
      <Link href="/">Home</Link>
    </section>
  );
}
