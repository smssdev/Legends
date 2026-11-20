import { createRoot } from "react-dom/client";
import { MenuButton } from "./MenuButton";

const noop = () => {};

createRoot(document.getElementById("root")!).render(
  <div className="card">
    <MenuButton
      label="إجراءات الطلب #1042"
      items={[
        { label: "تتبّع", onSelect: noop },
        { label: "نزّل الفاتورة", onSelect: noop },
        { label: "أرجع منتجات", onSelect: noop },
        { label: "ألغِ الطلب", danger: true, onSelect: noop },
      ]}
    />
  </div>,
);
