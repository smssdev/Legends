export default function Loading() {
  return (
    <section className="card" aria-busy="true" aria-label="جارٍ تحميل المنتجات…">
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton" />
    </section>
  );
}
