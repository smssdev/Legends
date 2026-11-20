// Every message has a key, and placeholders in braces
export const messages = {
  en: {
    "cart.title": "Your cart",
    "cart.items": { one: "{count} item", other: "{count} items" },
    "cart.total": "Total: {total}",
    "cart.empty": "Your cart is empty.",
  },
  ar: {
    "cart.title": "سلتك",
    "cart.items": {
      zero: "لا عناصر",
      one: "عنصر واحد",
      two: "عنصران",
      few: "{count} عناصر",
      many: "{count} عنصراً",
      other: "{count} عنصر",
    },
    "cart.total": "المجموع: {total}",
    "cart.empty": "سلتك فارغة.",
  },
} as const;

export type Locale = keyof typeof messages;
type Plural = Partial<Record<Intl.LDMLPluralRule, string>>;

export function translate(locale: Locale, key: keyof (typeof messages)["en"], values: Record<string, string | number> = {}) {
  const entry = messages[locale][key] as string | Plural;
  const text =
    typeof entry === "string"
      ? entry
      : (entry[new Intl.PluralRules(locale).select(Number(values.count ?? 0))] ?? entry.other ?? "");
  const format = new Intl.NumberFormat(locale);
  return text.replace(/\{(\w+)\}/g, (_, name: string) => {
    const value = values[name];
    return typeof value === "number" ? format.format(value) : String(value ?? "");
  });
}
