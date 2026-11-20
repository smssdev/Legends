import { createContext, useCallback, useContext, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";

type Toast = { id: number; text: string; action?: { label: string; run: () => void } };
type Notify = (text: string, action?: Toast["action"]) => void;

const ToastContext = createContext<Notify | null>(null);
let nextId = 1;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const dismiss = useCallback((id: number) => setToasts((all) => all.filter((t) => t.id !== id)), []);

  const notify = useCallback<Notify>(
    (text, action) => {
      const id = nextId++;
      setToasts((all) => [...all.slice(-2), { id, text, action }]); // at most three on screen
      setTimeout(() => dismiss(id), 5000);
    },
    [dismiss],
  );

  return (
    <ToastContext.Provider value={notify}>
      {children}
      {createPortal(
        <div className="toasts" role="status" aria-live="polite" aria-label="الإشعارات">
          {toasts.map((t) => (
            <div className="toast" key={t.id}>
              <span>{t.text}</span>
              {t.action && (
                <button
                  onClick={() => {
                    t.action!.run();
                    dismiss(t.id);
                  }}
                >
                  {t.action.label}
                </button>
              )}
              <button className="secondary" aria-label="أغلق" onClick={() => dismiss(t.id)}>
                ×
              </button>
            </div>
          ))}
        </div>,
        document.body,
      )}
    </ToastContext.Provider>
  );
}

export function useToast(): Notify {
  const notify = useContext(ToastContext);
  if (!notify) throw new Error("useToast must be used inside <ToastProvider>");
  return notify;
}
