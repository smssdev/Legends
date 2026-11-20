// en/react/dialog.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";

// en/react/ConfirmDialog.tsx
import { useEffect, useRef } from "react";
import { jsx, jsxs } from "react/jsx-runtime";
function ConfirmDialog({ open, title, children, confirmLabel, cancelLabel, onConfirm, onClose }) {
  const dialog = useRef(null);
  useEffect(() => {
    const el = dialog.current;
    if (!el) return;
    if (open && !el.open) el.showModal();
    if (!open && el.open) el.close();
  }, [open]);
  return /* @__PURE__ */ jsxs("dialog", { ref: dialog, "aria-labelledby": "dlg-title", "aria-describedby": "dlg-text", onClose, children: [
    /* @__PURE__ */ jsx("h2", { id: "dlg-title", children: title }),
    /* @__PURE__ */ jsx("p", { id: "dlg-text", children }),
    /* @__PURE__ */ jsxs("div", { className: "row", children: [
      /* @__PURE__ */ jsx("button", { className: "secondary", autoFocus: true, onClick: onClose, children: cancelLabel }),
      /* @__PURE__ */ jsx("button", { className: "danger", onClick: onConfirm, children: confirmLabel })
    ] })
  ] });
}

// en/react/dialog.tsx
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function Settings() {
  const [open, setOpen] = useState(false);
  return /* @__PURE__ */ jsxs2("div", { className: "card", children: [
    /* @__PURE__ */ jsx2("button", { className: "danger", onClick: () => setOpen(true), children: "Delete account\u2026" }),
    /* @__PURE__ */ jsx2(
      ConfirmDialog,
      {
        open,
        title: "Delete your account?",
        confirmLabel: "Delete",
        cancelLabel: "Cancel",
        onConfirm: () => setOpen(false),
        onClose: () => setOpen(false),
        children: "All your orders and saved lists will be removed. This cannot be undone."
      }
    )
  ] });
}
createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(Settings, {}));
