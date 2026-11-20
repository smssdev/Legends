import { useId, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import type { KeyboardEvent, ReactNode } from "react";

type Tab = { label: string; content: ReactNode };

function Tabs({ tabs, label }: { tabs: Tab[]; label: string }) {
  const [active, setActive] = useState(0);
  const id = useId();
  const buttons = useRef<(HTMLButtonElement | null)[]>([]);

  function select(index: number) {
    const next = (index + tabs.length) % tabs.length;
    setActive(next);
    buttons.current[next]?.focus();
  }

  function onKeyDown(event: KeyboardEvent) {
    const rtl = document.dir === "rtl";
    if (event.key === "ArrowRight") select(active + (rtl ? -1 : 1));
    if (event.key === "ArrowLeft") select(active + (rtl ? 1 : -1));
    if (event.key === "Home") select(0);
    if (event.key === "End") select(tabs.length - 1);
  }

  return (
    <div className="tabs">
      <div role="tablist" aria-label={label} onKeyDown={onKeyDown}>
        {tabs.map((tab, i) => (
          <button
            key={tab.label}
            ref={(el) => {
              buttons.current[i] = el;
            }}
            role="tab"
            id={`${id}-tab-${i}`}
            aria-selected={i === active}
            aria-controls={`${id}-panel-${i}`}
            tabIndex={i === active ? 0 : -1}
            onClick={() => select(i)}
          >
            {tab.label}
          </button>
        ))}
      </div>
      {tabs.map((tab, i) => (
        <div
          key={tab.label}
          role="tabpanel"
          id={`${id}-panel-${i}`}
          aria-labelledby={`${id}-tab-${i}`}
          hidden={i !== active}
        >
          {tab.content}
        </div>
      ))}
    </div>
  );
}

createRoot(document.getElementById("root")!).render(
  <Tabs
    label="Product details"
    tabs={[
      { label: "Description", content: <p>A friendly guide that takes you from your first line of code to your first app.</p> },
      { label: "Reviews", content: <p>“Clear, kind and practical. My son finished it in a month.” ★★★★★</p> },
      { label: "Shipping", content: <p>Free delivery in Egypt for orders over 50 EGP. Arrives in 2–4 days.</p> },
    ]}
  />,
);
