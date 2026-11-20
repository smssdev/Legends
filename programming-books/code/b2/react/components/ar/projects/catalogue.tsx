import { useState } from "react";
import { createRoot } from "react-dom/client";
import { products, type Product } from "../products";

type Filter = "all" | Product["category"];

const FILTERS: { value: Filter; label: string }[] = [
  { value: "all", label: "الكل" },
  { value: "books", label: "كتب" },
  { value: "gifts", label: "هدايا" },
];

function ProductCard({ product }: { product: Product }) {
  return (
    <article className="card">
      {product.isNew && <span className="badge">جديد</span>}
      <h3>{product.name}</h3>
      <p className="price">
        {product.price.toFixed(2)} جنيهاً
      </p>
    </article>
  );
}

function Catalogue() {
  const [filter, setFilter] = useState<Filter>("all");
  const visible = filter === "all" ? products : products.filter((p) => p.category === filter);

  return (
    <section>
      <h2>الكتالوج</h2>
      <div className="filters" role="group" aria-label="الكتالوج">
        {FILTERS.map(({ value, label }) => (
          <button
            key={value}
            className={value === filter ? "" : "secondary"}
            aria-pressed={value === filter}
            onClick={() => setFilter(value)}
          >
            {label}
          </button>
        ))}
      </div>
      <p className="count">
        يظهر {visible.length} من {products.length} منتجات
      </p>
      <div className="grid">
        {visible.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </section>
  );
}

createRoot(document.getElementById("root")!).render(<Catalogue />);
