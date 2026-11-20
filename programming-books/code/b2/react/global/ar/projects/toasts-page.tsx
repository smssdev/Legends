import { useState } from "react";
import { createRoot } from "react-dom/client";
import { ToastProvider, useToast } from "./toasts";

const NAMES = ["البرمجة من الصفر", "كوب بِت", "قبعة بِت"];

function Shelf() {
  const notify = useToast();
  const [items, setItems] = useState(NAMES);

  function remove(name: string) {
    setItems((all) => all.filter((n) => n !== name));
    notify(`حُذف: ${name}`, { label: "تراجع", run: () => setItems((all) => [...all, name]) });
  }

  return (
    <section className="card">
      {items.map((name) => (
        <div key={name} className="row" style={{ justifyContent: "space-between", padding: "4px 0" }}>
          <span>{name}</span>
          <span className="row">
            <button onClick={() => notify(`${name} أُضيف إلى السلة`)}>أضف</button>
            <button className="secondary" onClick={() => remove(name)}>
              ×
            </button>
          </span>
        </div>
      ))}
    </section>
  );
}

createRoot(document.getElementById("root")!).render(
  <ToastProvider>
    <Shelf />
  </ToastProvider>,
);
