export default function Loading() {
  return (
    <section className="card" aria-busy="true" aria-label="Loading products…">
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton" />
    </section>
  );
}
