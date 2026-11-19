import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { translate, type Locale } from "../messages";

type I18n = {
  locale: Locale;
  setLocale: (l: Locale) => void;
  t: (key: Parameters<typeof translate>[1], values?: Record<string, string | number>) => string;
  money: (value: number) => string;
};

const Ctx = createContext<I18n | null>(null);

export function I18nProvider({ initial, children }: { initial: Locale; children: ReactNode }) {
  const [locale, setLocale] = useState<Locale>(initial);

  useEffect(() => {
    document.documentElement.lang = locale;
    document.documentElement.dir = locale === "ar" ? "rtl" : "ltr";
  }, [locale]);

  const value = useMemo<I18n>(() => {
    const currency = new Intl.NumberFormat(locale === "ar" ? "ar-EG" : "en-EG", { style: "currency", currency: "EGP" });
    return {
      locale,
      setLocale,
      t: (key, values) => translate(locale, key, values),
      money: (v) => currency.format(v),
    };
  }, [locale]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useI18n(): I18n {
  const value = useContext(Ctx);
  if (!value) throw new Error("useI18n must be used inside <I18nProvider>");
  return value;
}
