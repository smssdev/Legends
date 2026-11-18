import { useState } from "react";
import { createRoot } from "react-dom/client";
import { ConfirmDialog } from "./ConfirmDialog";

function Settings() {
  const [open, setOpen] = useState(false);
  return (
    <div className="card">
      <button className="danger" onClick={() => setOpen(true)}>
        احذف الحساب…
      </button>
      <ConfirmDialog
        open={open}
        title="أتحذف حسابك؟"
        confirmLabel="احذف"
        cancelLabel="ألغِ"
        onConfirm={() => setOpen(false)}
        onClose={() => setOpen(false)}
      >
        ستُحذف كل طلباتك وقوائمك المحفوظة، ولا يمكن التراجع عن ذلك.
      </ConfirmDialog>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Settings />);
