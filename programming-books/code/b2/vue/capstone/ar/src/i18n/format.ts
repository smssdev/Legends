import { messages, type Key, type Lang } from "./messages";

const locales: Record<Lang, string> = { en: "en-EG", ar: "ar-EG" };

export function makeT(lang: Lang) {
  const money = new Intl.NumberFormat(locales[lang], { style: "currency", currency: "EGP", maximumFractionDigits: 0 });
  const date = new Intl.DateTimeFormat(locales[lang], { day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
  const weekday = new Intl.DateTimeFormat(locales[lang], { weekday: "short", timeZone: "UTC" });
  const number = new Intl.NumberFormat(locales[lang]);
  const t = (key: Key, values: Record<string, string | number> = {}) =>
    messages[lang][key].replace(/\{(\w+)\}/g, (_, name: string) => {
      const value = values[name];
      return typeof value === "number" ? number.format(value) : String(value);
    });
  return Object.assign(t, {
    lang,
    money: (piastres: number) => money.format(piastres / 100),
    date: (iso: string) => date.format(new Date(iso)),
    weekday: (day: string) => weekday.format(new Date(day)),
  });
}
export type T = ReturnType<typeof makeT>;
