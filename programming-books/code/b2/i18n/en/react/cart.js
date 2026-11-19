// en/react/cart.tsx
import { createRoot } from "react-dom/client";

// en/react/I18n.tsx
import { createContext, useContext, useEffect, useMemo, useState } from "react";

// en/messages.ts
var messages = {
  en: {
    "cart.title": "Your cart",
    "cart.items": { one: "{count} item", other: "{count} items" },
    "cart.total": "Total: {total}",
    "cart.empty": "Your cart is empty."
  },
  ar: {
    "cart.title": "\u0633\u0644\u062A\u0643",
    "cart.items": {
      zero: "\u0644\u0627 \u0639\u0646\u0627\u0635\u0631",
      one: "\u0639\u0646\u0635\u0631 \u0648\u0627\u062D\u062F",
      two: "\u0639\u0646\u0635\u0631\u0627\u0646",
      few: "{count} \u0639\u0646\u0627\u0635\u0631",
      many: "{count} \u0639\u0646\u0635\u0631\u0627\u064B",
      other: "{count} \u0639\u0646\u0635\u0631"
    },
    "cart.total": "\u0627\u0644\u0645\u062C\u0645\u0648\u0639: {total}",
    "cart.empty": "\u0633\u0644\u062A\u0643 \u0641\u0627\u0631\u063A\u0629."
  }
};
function translate(locale, key, values = {}) {
  const entry = messages[locale][key];
  const text = typeof entry === "string" ? entry : entry[new Intl.PluralRules(locale).select(Number(values.count ?? 0))] ?? entry.other ?? "";
  const format = new Intl.NumberFormat(locale);
  return text.replace(/\{(\w+)\}/g, (_, name) => {
    const value = values[name];
    return typeof value === "number" ? format.format(value) : String(value ?? "");
  });
}

// en/react/I18n.tsx
import { jsx } from "react/jsx-runtime";
var Ctx = createContext(null);
function I18nProvider({ initial, children }) {
  const [locale, setLocale] = useState(initial);
  useEffect(() => {
    document.documentElement.lang = locale;
    document.documentElement.dir = locale === "ar" ? "rtl" : "ltr";
  }, [locale]);
  const value = useMemo(() => {
    const currency = new Intl.NumberFormat(locale === "ar" ? "ar-EG" : "en-EG", { style: "currency", currency: "EGP" });
    return {
      locale,
      setLocale,
      t: (key, values) => translate(locale, key, values),
      money: (v) => currency.format(v)
    };
  }, [locale]);
  return /* @__PURE__ */ jsx(Ctx.Provider, { value, children });
}
function useI18n() {
  const value = useContext(Ctx);
  if (!value) throw new Error("useI18n must be used inside <I18nProvider>");
  return value;
}

// en/react/cart.tsx
import { jsx as jsx2, jsxs } from "react/jsx-runtime";
var LINES = [
  { name: "Code from Zero", price: 250 },
  { name: "Bit mug", price: 85 }
];
function Cart() {
  const { t, money, locale, setLocale } = useI18n();
  const total = LINES.reduce((sum, l) => sum + l.price, 0);
  return /* @__PURE__ */ jsxs("section", { className: "card", children: [
    /* @__PURE__ */ jsxs("h2", { children: [
      t("cart.title"),
      /* @__PURE__ */ jsx2("span", { className: "badge", children: t("cart.items", { count: LINES.length }) })
    ] }),
    LINES.map((l) => /* @__PURE__ */ jsxs("div", { className: "row", children: [
      /* @__PURE__ */ jsx2("bdi", { children: l.name }),
      /* @__PURE__ */ jsx2("span", { children: money(l.price) })
    ] }, l.name)),
    /* @__PURE__ */ jsx2("p", { children: /* @__PURE__ */ jsx2("b", { children: t("cart.total", { total: money(total) }) }) }),
    /* @__PURE__ */ jsx2("button", { className: "next", onClick: () => setLocale(locale === "ar" ? "en" : "ar"), children: locale === "ar" ? "English" : "\u0627\u0644\u0639\u0631\u0628\u064A\u0629" })
  ] });
}
createRoot(document.getElementById("root")).render(
  /* @__PURE__ */ jsx2(I18nProvider, { initial: "en", children: /* @__PURE__ */ jsx2(Cart, {}) })
);
