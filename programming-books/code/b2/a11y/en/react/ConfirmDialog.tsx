import { useEffect, useRef, type ReactNode } from "react";

type Props = {
  open: boolean;
  title: string;
  children: ReactNode;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  onClose: () => void;
};

export function ConfirmDialog({ open, title, children, confirmLabel, cancelLabel, onConfirm, onClose }: Props) {
  const dialog = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const el = dialog.current;
    if (!el) return;
    if (open && !el.open) el.showModal(); // modal: traps focus, Esc closes, the page behind is inert
    if (!open && el.open) el.close(); // the browser returns the focus to the button that opened it
  }, [open]);

  return (
    <dialog ref={dialog} aria-labelledby="dlg-title" aria-describedby="dlg-text" onClose={onClose}>
      <h2 id="dlg-title">{title}</h2>
      <p id="dlg-text">{children}</p>
      <div className="row">
        <button className="secondary" autoFocus onClick={onClose}>
          {cancelLabel}
        </button>
        <button className="danger" onClick={onConfirm}>
          {confirmLabel}
        </button>
      </div>
    </dialog>
  );
}
