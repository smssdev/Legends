import { createRoot } from "react-dom/client";

type Orders =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "success"; orders: string[] };

function OrderList({ state }: { state: Orders }) {
  if (state.status === "loading") {
    return (
      <p className="muted">
        <span className="spinner" />
        جارٍ تحميل طلباتك…
      </p>
    );
  }
  if (state.status === "error") {
    return (
      <p className="error">
        تعذّر تحميل طلباتك: {state.message}
        <button className="secondary">حاول مرة أخرى</button>
      </p>
    );
  }
  if (state.orders.length === 0) {
    return <p className="muted">ليست لديك طلبات بعد.</p>;
  }
  return (
    <ul>
      {state.orders.map((order) => (
        <li key={order}>{order}</li>
      ))}
    </ul>
  );
}

const examples: Orders[] = [
  { status: "loading" },
  { status: "error", message: "أنت غير متصل" },
  { status: "success", orders: [] },
  { status: "success", orders: ["#1042 · البرمجة من الصفر", "#1043 · كوب بِت"] },
];

createRoot(document.getElementById("root")!).render(
  <>
    {examples.map((state, i) => (
      <div className="panel" key={i}>
        <OrderList state={state} />
      </div>
    ))}
  </>,
);
