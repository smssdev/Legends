import { createRoot } from "react-dom/client";
import type { ReactNode } from "react";
import { products, type Product } from "./products";

type ProductCardProps = {
  product: Product;
  onAdd?: (id: number) => void;
};

function ProductCard({ product, onAdd }: ProductCardProps) {
  return (
    <article className="card">
      {product.isNew && <span className="badge">New</span>}
      <h3>{product.name}</h3>
      <p className="price">
        {product.price.toFixed(2)} EGP
      </p>
      <button disabled={!product.inStock} onClick={() => onAdd?.(product.id)}>
        {product.inStock ? "Add to cart" : "Sold out"}
      </button>
    </article>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section>
      <h2>{title}</h2>
      {children}
    </section>
  );
}

function App() {
  return (
    <Section title="Bit's shop">
      <div className="grid">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </Section>
  );
}

createRoot(document.getElementById("root")!).render(<App />);
