import { useState } from "react";
import { createRoot } from "react-dom/client";
import { Switch } from "./Switch";

function Settings() {
  const [dark, setDark] = useState(false);
  return (
    <div className="gallery" data-theme={dark ? "dark" : undefined}>
      <Switch label="Email me about new books" defaultChecked />
      <Switch label="Wi-Fi" />
      <Switch label="Dark theme" checked={dark} onChange={setDark} />
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Settings />);
