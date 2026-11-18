import { useState } from "react";
import { createRoot } from "react-dom/client";
import { ConfirmDialog } from "./ConfirmDialog";

function Settings() {
  const [open, setOpen] = useState(false);
  return (
    <div className="card">
      <button className="danger" onClick={() => setOpen(true)}>
        Delete account…
      </button>
      <ConfirmDialog
        open={open}
        title="Delete your account?"
        confirmLabel="Delete"
        cancelLabel="Cancel"
        onConfirm={() => setOpen(false)}
        onClose={() => setOpen(false)}
      >
        All your orders and saved lists will be removed. This cannot be undone.
      </ConfirmDialog>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Settings />);
