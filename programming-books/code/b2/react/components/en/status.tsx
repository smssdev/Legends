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
        Loading your orders…
      </p>
    );
  }
  if (state.status === "error") {
    return (
      <p className="error">
        Could not load your orders: {state.message}
        <button className="secondary">Try again</button>
      </p>
    );
  }
  if (state.orders.length === 0) {
    return <p className="muted">You have no orders yet.</p>;
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
  { status: "error", message: "you are offline" },
  { status: "success", orders: [] },
  { status: "success", orders: ["#1042 · Code from Zero", "#1043 · Bit mug"] },
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
