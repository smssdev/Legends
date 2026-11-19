import { useDeferredValue, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import { SlowList } from "./SlowList";

const ALL = Array.from({ length: 5000 }, (_, i) => `منتج بِت ${i + 1}`);

function Filter() {
  const [text, setText] = useState("");
  // أبقِ الكتابة عاجلة، وتحديث القائمة الكبيرة يستطيع الانتظار
  const deferred = useDeferredValue(text);
  const items = useMemo(() => ALL.filter((name) => name.includes(deferred)), [deferred]);
  const stale = text !== deferred;

  return (
    <div className="card">
      <label htmlFor="q">صفِّ المنتجات</label>
      <input id="q" value={text} onChange={(e) => setText(e.target.value)} />
      <p className="muted" aria-live="polite">
        {stale ? "جارٍ التحديث…" : `يظهر ${items.length} من ${ALL.length}`}
      </p>
      <div className={stale ? "stale" : undefined}>
        <SlowList items={items} />
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Filter />);
