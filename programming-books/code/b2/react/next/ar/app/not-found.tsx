import Link from "next/link";

export default function NotFound() {
  return (
    <section className="card">
      <h1>404</h1>
      <p>لم نجد هذه الصفحة.</p>
      <Link href="/">الرئيسية</Link>
    </section>
  );
}
