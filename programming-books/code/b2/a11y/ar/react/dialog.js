// ar/react/dialog.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";

// ar/react/ConfirmDialog.tsx
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

// ar/react/dialog.tsx
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function Settings() {
  const [open, setOpen] = useState(false);
  return /* @__PURE__ */ jsxs2("div", { className: "card", children: [
    /* @__PURE__ */ jsx2("button", { className: "danger", onClick: () => setOpen(true), children: "\u0627\u062D\u0630\u0641 \u0627\u0644\u062D\u0633\u0627\u0628\u2026" }),
    /* @__PURE__ */ jsx2(
      ConfirmDialog,
      {
        open,
        title: "\u0623\u062A\u062D\u0630\u0641 \u062D\u0633\u0627\u0628\u0643\u061F",
        confirmLabel: "\u0627\u062D\u0630\u0641",
        cancelLabel: "\u0623\u0644\u063A\u0650",
        onConfirm: () => setOpen(false),
        onClose: () => setOpen(false),
        children: "\u0633\u062A\u064F\u062D\u0630\u0641 \u0643\u0644 \u0637\u0644\u0628\u0627\u062A\u0643 \u0648\u0642\u0648\u0627\u0626\u0645\u0643 \u0627\u0644\u0645\u062D\u0641\u0648\u0638\u0629\u060C \u0648\u0644\u0627 \u064A\u0645\u0643\u0646 \u0627\u0644\u062A\u0631\u0627\u062C\u0639 \u0639\u0646 \u0630\u0644\u0643."
      }
    )
  ] });
}
createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(Settings, {}));
