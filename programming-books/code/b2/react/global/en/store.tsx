import { createRoot } from "react-dom/client";
import { selectCount, selectTotal, useCart, type Product } from "./cart-store";

const products: Product[] = [
  { id: 1, name: "Code from Zero", price: 25 },
  { id: 2, name: "Bit mug", price: 8 },
  { id: 3, name: "Bit cap", price: 12 },
];

function CartBadge() {
  const count = useCart(selectCount); // A selector: this component re-renders only when the count changes
  return (
    <span className="row">
      Cart <span className="badge">{count}</span>
    </span>
  );
}

function ProductList() {
  const add = useCart((s) => s.add);
  return (
    <section className="card">
      {products.map((p) => (
        <div key={p.id} className="row" style={{ justifyContent: "space-between", padding: "4px 0" }}>
          <span>{p.name}</span>
          <button onClick={() => add(p)}>Add</button>
        </div>
      ))}
    </section>
  );
}

function CartSummary() {
  const lines = useCart((s) => s.lines);
  const total = useCart(selectTotal);
  const clear = useCart((s) => s.clear);
  const list = Object.values(lines);
  if (list.length === 0) return <p className="card muted">The cart is empty.</p>;
  return (
    <section className="card">
      <ul>
        {list.map((l) => (
          <li key={l.product.id}>
            <span>
              {l.quantity} × {l.product.name}
            </span>
            <span>
              {l.quantity * l.product.price} EGP
            </span>
          </li>
        ))}
      </ul>
      <p>
        <b>
          Total: {total} EGP
        </b>
      </p>
      <button className="secondary" onClick={clear}>
        Empty the cart
      </button>
    </section>
  );
}

localStorage.clear();
createRoot(document.getElementById("root")!).render(
  <>
    <header>
      <span className="brand">Bit's shop</span>
      <CartBadge />
    </header>
    <ProductList />
    <CartSummary />
  </>,
);
