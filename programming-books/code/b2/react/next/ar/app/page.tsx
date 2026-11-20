import Link from "next/link";

export default function Home() {
  return (
    <section className="card">
      <h1>أهلاً بك في متجر بِت</h1>
      <p>كتب وأكواب وملصقات لمن يحبون البرمجة.</p>
      <Link href="/products">تصفّح المنتجات</Link>
    </section>
  );
}
