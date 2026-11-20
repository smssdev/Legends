import { useDeferredValue, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import { SlowList } from "./SlowList";

const ALL = Array.from({ length: 5000 }, (_, i) => `Bit item ${i + 1}`);

function Filter() {
  const [text, setText] = useState("");
  // Keep the typing urgent; the big list update can wait
  const deferred = useDeferredValue(text);
  const items = useMemo(() => ALL.filter((name) => name.includes(deferred)), [deferred]);
  const stale = text !== deferred;

  return (
    <div className="card">
      <label htmlFor="q">Filter products</label>
      <input id="q" value={text} onChange={(e) => setText(e.target.value)} />
      <p className="muted" aria-live="polite">
        {stale ? "Updating…" : `Showing ${items.length} of ${ALL.length}`}
      </p>
      <div className={stale ? "stale" : undefined}>
        <SlowList items={items} />
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Filter />);
