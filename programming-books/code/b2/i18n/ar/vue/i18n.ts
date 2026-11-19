import { computed, inject, provide, ref, watchEffect, type ComputedRef, type InjectionKey, type Ref } from "vue";
import { translate, type Locale } from "../messages";

type I18n = {
  locale: Ref<Locale>;
  t: ComputedRef<(key: Parameters<typeof translate>[1], values?: Record<string, string | number>) => string>;
  money: ComputedRef<(value: number) => string>;
};

const I18nKey: InjectionKey<I18n> = Symbol("i18n");

export function provideI18n(initial: Locale) {
  const locale = ref<Locale>(initial);

  watchEffect(() => {
    document.documentElement.lang = locale.value;
    document.documentElement.dir = locale.value === "ar" ? "rtl" : "ltr";
  });

  const t = computed(() => (key: Parameters<typeof translate>[1], values?: Record<string, string | number>) =>
    translate(locale.value, key, values),
  );
  const money = computed(() => {
    const currency = new Intl.NumberFormat(locale.value === "ar" ? "ar-EG" : "en-EG", { style: "currency", currency: "EGP" });
    return (v: number) => currency.format(v);
  });

  provide(I18nKey, { locale, t, money });
}

export function useI18n(): I18n {
  const value = inject(I18nKey);
  if (!value) throw new Error("useI18n() must be used inside a component that called provideI18n()");
  return value;
}
