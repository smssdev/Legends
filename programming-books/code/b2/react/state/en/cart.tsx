import { useState } from "react";
import { createRoot } from "react-dom/client";
import { catalogue, FREE_DELIVERY, type Line, type Product } from "./cart-model";

function Cart() {
  const [lines, setLines] = useState<Line[]>([]);

  // Derived: calculated on every render, never stored
  const count = lines.reduce((sum, line) => sum + line.quantity, 0);
  const total = lines.reduce((sum, line) => sum + line.quantity * line.product.price, 0);
  const missing = FREE_DELIVERY - total;

  function add(product: Product) {
    setLines((current) => {
      const found = current.find((line) => line.product.id === product.id);
      if (!found) return [...current, { product, quantity: 1 }];
      return current.map((line) => (line === found ? { ...line, quantity: line.quantity + 1 } : line));
    });
  }

  function remove(id: number) {
    setLines((current) => current.filter((line) => line.product.id !== id));
  }

  return (
    <div className="card">
      <div className="row">
        {catalogue.map((product) => (
          <button key={product.id} className="secondary" onClick={() => add(product)}>
            + {product.name}
          </button>
        ))}
      </div>
      {lines.length === 0 ? (
        <p className="muted">Your cart is empty.</p>
      ) : (
        <ul>
          {lines.map((line) => (
            <li key={line.product.id}>
              <span>
                {line.quantity} × {line.product.name}
              </span>
              <button className="secondary" onClick={() => remove(line.product.id)}>
                Remove
              </button>
            </li>
          ))}
        </ul>
      )}
      <p>
        Items: {count} · Total: <b>{total} EGP</b>
      </p>
      <p className={missing <= 0 ? "ok" : "muted"}>
        {missing <= 0 ? "Free delivery!" : `${missing} EGP more for free delivery`}
      </p>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Cart />);
