import { createRoot } from "react-dom/client";
import { ThemeProvider, useTheme } from "./theme";

function ThemeSwitch() {
  const { theme, toggle } = useTheme();
  return (
    <button className="secondary" aria-pressed={theme === "dark"} onClick={toggle}>
      المظهر: {theme === "dark" ? "داكن" : "فاتح"}
    </button>
  );
}

localStorage.removeItem("theme");
createRoot(document.getElementById("root")!).render(
  <ThemeProvider>
    <header>
      <span className="brand">متجر بِت</span>
      <ThemeSwitch />
    </header>
    <p className="card">كوب بِت · 8 جنيهاً</p>
  </ThemeProvider>,
);
