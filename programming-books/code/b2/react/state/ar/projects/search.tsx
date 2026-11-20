import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { searchProducts } from "../fake-api";
import type { Product } from "../cart-model";

type Result =
  | { status: "idle" }
  | { status: "loading"; query: string }
  | { status: "done"; query: string; products: Product[] }
  | { status: "error"; message: string };

function useDebounced<T>(value: T, ms: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), ms);
    return () => clearTimeout(id);
  }, [value, ms]);
  return debounced;
}

function Search() {
  const [query, setQuery] = useState("");
  const [result, setResult] = useState<Result>({ status: "idle" });
  const debounced = useDebounced(query, 300);

  useEffect(() => {
    if (!debounced.trim()) {
      setResult({ status: "idle" });
      return;
    }
    const controller = new AbortController();
    setResult({ status: "loading", query: debounced });
    searchProducts(debounced, controller.signal)
      .then((products) => setResult({ status: "done", query: debounced, products }))
      .catch((error: unknown) => {
        if (controller.signal.aborted) return;
        setResult({ status: "error", message: String(error) });
      });
    return () => controller.abort(); // إن كتب المستخدم من جديد، فتجاهل الرد القديم
  }, [debounced]);

  return (
    <div className="card">
      <label htmlFor="q">ابحث في المنتجات</label>
      <input id="q" type="search" value={query} onChange={(e) => setQuery(e.target.value)} />
      {result.status === "loading" && <p className="muted">جارٍ البحث عن “{result.query}”…</p>}
      {result.status === "error" && <p role="alert">{result.message}</p>}
      {result.status === "done" &&
        (result.products.length === 0 ? (
          <p className="muted">لا منتجات تطابق “{result.query}”.</p>
        ) : (
          <ul aria-label="نتائج">
            {result.products.map((p) => (
              <li key={p.id}>
                <span>{p.name}</span>
                <b>
                  {p.price} جنيهاً
                </b>
              </li>
            ))}
          </ul>
        ))}
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Search />);
