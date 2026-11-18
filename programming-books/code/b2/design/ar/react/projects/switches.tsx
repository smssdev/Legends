import { useState } from "react";
import { createRoot } from "react-dom/client";
import { Switch } from "./Switch";

function Settings() {
  const [dark, setDark] = useState(false);
  return (
    <div className="gallery" data-theme={dark ? "dark" : undefined}>
      <Switch label="راسلني عن الكتب الجديدة" defaultChecked />
      <Switch label="الواي فاي" />
      <Switch label="المظهر الداكن" checked={dark} onChange={setDark} />
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Settings />);
