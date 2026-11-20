import { useEffect, useId, useRef, useState } from "react";
import type { KeyboardEvent } from "react";

type Item = { label: string; danger?: boolean; onSelect: () => void };

export function MenuButton({ label, items }: { label: string; items: Item[] }) {
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const id = useId();
  const button = useRef<HTMLButtonElement>(null);
  const itemRefs = useRef<(HTMLButtonElement | null)[]>([]);

  // Move the real focus to the active item whenever it changes
  useEffect(() => {
    if (open) itemRefs.current[active]?.focus();
  }, [open, active]);

  function openAt(index: number) {
    setActive(index);
    setOpen(true);
  }

  function close() {
    setOpen(false);
    button.current?.focus(); // focus goes back where it came from
  }

  function onButtonKey(event: KeyboardEvent) {
    if (event.key === "ArrowDown") (event.preventDefault(), openAt(0));
    if (event.key === "ArrowUp") (event.preventDefault(), openAt(items.length - 1));
  }

  function onMenuKey(event: KeyboardEvent) {
    const last = items.length - 1;
    if (event.key === "ArrowDown") setActive((i) => (i === last ? 0 : i + 1));
    else if (event.key === "ArrowUp") setActive((i) => (i === 0 ? last : i - 1));
    else if (event.key === "Home") setActive(0);
    else if (event.key === "End") setActive(last);
    else if (event.key === "Escape" || event.key === "Tab") close();
    else return;
    event.preventDefault();
  }

  return (
    <div className="menu-wrap">
      <button
        ref={button}
        id={`${id}-button`}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={`${id}-menu`}
        onClick={() => (open ? close() : openAt(0))}
        onKeyDown={onButtonKey}
      >
        {label} ▾
      </button>
      {open && (
        <ul role="menu" id={`${id}-menu`} aria-labelledby={`${id}-button`} onKeyDown={onMenuKey}>
          {items.map((item, i) => (
            <li role="none" key={item.label}>
              <button
                ref={(el) => {
                  itemRefs.current[i] = el;
                }}
                role="menuitem"
                tabIndex={-1}
                className={item.danger ? "danger-text" : undefined}
                onClick={() => {
                  item.onSelect();
                  close();
                }}
              >
                {item.label}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
