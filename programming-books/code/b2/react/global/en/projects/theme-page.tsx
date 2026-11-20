import { createRoot } from "react-dom/client";
import { ThemeProvider, useTheme } from "./theme";

function ThemeSwitch() {
  const { theme, toggle } = useTheme();
  return (
    <button className="secondary" aria-pressed={theme === "dark"} onClick={toggle}>
      Theme: {theme === "dark" ? "Dark" : "Light"}
    </button>
  );
}

localStorage.removeItem("theme");
createRoot(document.getElementById("root")!).render(
  <ThemeProvider>
    <header>
      <span className="brand">Bit's shop</span>
      <ThemeSwitch />
    </header>
    <p className="card">Bit mug · 8 EGP</p>
  </ThemeProvider>,
);
