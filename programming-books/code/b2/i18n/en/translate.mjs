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

// en/translate.ts
for (const n of [0, 1, 2, 5, 11, 100]) {
  console.log(String(n).padStart(3), "|", translate("ar", "cart.items", { count: n }).padEnd(12), "|", translate("en", "cart.items", { count: n }));
}
