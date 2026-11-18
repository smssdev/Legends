import { createRoot } from "react-dom/client";
import { selectCount, selectTotal, useCart, type Product } from "./cart-store";

const products: Product[] = [
  { id: 1, name: "البرمجة من الصفر", price: 25 },
  { id: 2, name: "كوب بِت", price: 8 },
  { id: 3, name: "قبعة بِت", price: 12 },
];

function CartBadge() {
  const count = useCart(selectCount); // محدِّد: يعاد رسم هذا المكوّن فقط حين يتغير العدد
  return (
    <span className="row">
      السلة <span className="badge">{count}</span>
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
          <button onClick={() => add(p)}>أضف</button>
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
  if (list.length === 0) return <p className="card muted">السلة فارغة.</p>;
  return (
    <section className="card">
      <ul>
        {list.map((l) => (
          <li key={l.product.id}>
            <span>
              {l.quantity} × {l.product.name}
            </span>
            <span>
              {l.quantity * l.product.price} جنيهاً
            </span>
          </li>
        ))}
      </ul>
      <p>
        <b>
          المجموع: {total} جنيهاً
        </b>
      </p>
      <button className="secondary" onClick={clear}>
        أفرغ السلة
      </button>
    </section>
  );
}

localStorage.clear();
createRoot(document.getElementById("root")!).render(
  <>
    <header>
      <span className="brand">متجر بِت</span>
      <CartBadge />
    </header>
    <ProductList />
    <CartSummary />
  </>,
);
