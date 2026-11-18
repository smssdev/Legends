var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/projects/theme.tsx
import { createContext, useContext, useEffect, useState } from "react";
import { jsx } from "react/jsx-runtime";
function initialTheme() {
  const saved = localStorage.getItem("theme");
  if (saved === "light" || saved === "dark") return saved;
  return matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}
function ThemeProvider({ children }) {
  const [theme, setTheme] = useState(initialTheme);
  useEffect(() => {
    document.body.classList.toggle("dark", theme === "dark");
    localStorage.setItem("theme", theme);
  }, [theme]);
  const toggle = () => setTheme((t) => t === "dark" ? "light" : "dark");
  return /* @__PURE__ */ jsx(ThemeContext.Provider, { value: { theme, toggle }, children });
}
function useTheme() {
  const value = useContext(ThemeContext);
  if (!value) throw new Error("useTheme must be used inside <ThemeProvider>");
  return value;
}
var ThemeContext;
var init_theme = __esm({
  "ar/projects/theme.tsx"() {
    ThemeContext = createContext(null);
  }
});

// ar/projects/theme-page.tsx
import { createRoot } from "react-dom/client";
import { jsx as jsx2, jsxs } from "react/jsx-runtime";
var require_theme_page = __commonJS({
  "ar/projects/theme-page.tsx"() {
    init_theme();
    function ThemeSwitch() {
      const { theme, toggle } = useTheme();
      return /* @__PURE__ */ jsxs("button", { className: "secondary", "aria-pressed": theme === "dark", onClick: toggle, children: [
        "\u0627\u0644\u0645\u0638\u0647\u0631: ",
        theme === "dark" ? "\u062F\u0627\u0643\u0646" : "\u0641\u0627\u062A\u062D"
      ] });
    }
    localStorage.removeItem("theme");
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsxs(ThemeProvider, { children: [
        /* @__PURE__ */ jsxs("header", { children: [
          /* @__PURE__ */ jsx2("span", { className: "brand", children: "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A" }),
          /* @__PURE__ */ jsx2(ThemeSwitch, {})
        ] }),
        /* @__PURE__ */ jsx2("p", { className: "card", children: "\u0643\u0648\u0628 \u0628\u0650\u062A \xB7 8 \u062C\u0646\u064A\u0647\u0627\u064B" })
      ] })
    );
  }
});
export default require_theme_page();
