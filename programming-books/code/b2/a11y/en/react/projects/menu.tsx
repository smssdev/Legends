import { createRoot } from "react-dom/client";
import { MenuButton } from "./MenuButton";

const noop = () => {};

createRoot(document.getElementById("root")!).render(
  <div className="card">
    <MenuButton
      label="Actions for order #1042"
      items={[
        { label: "Track", onSelect: noop },
        { label: "Download invoice", onSelect: noop },
        { label: "Return items", onSelect: noop },
        { label: "Cancel order", danger: true, onSelect: noop },
      ]}
    />
  </div>,
);
