"""Writes the examples of Book 2, chapter "Internationalisation and RTL", in English and Arabic.
Run: python3 make.py   Every format in the book is the real output of the JavaScript Intl API.
Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Languages", w_c1="One number, many correct ways to write it",
        w_c2="Arabic has six plural categories; English has two",
        w_c3="Every message has a key, and placeholders in braces",
        w_c4="Compare the two catalogues: missing keys, extra keys, and placeholders that do not match",
        w_missing="missing in", w_extra="not in en", w_ph="placeholders differ:", w_ok="All keys match.",
        w_problems="problems",
    ),
    "ar": dict(
        w_title="اللغات", w_c1="رقم واحد، وطرق صحيحة كثيرة لكتابته",
        w_c2="في العربية ست فئات للجمع، وفي الإنجليزية فئتان",
        w_c3="لكل رسالة مفتاح، والأماكن الفارغة بين أقواس",
        w_c4="قارن الفهرسين: المفاتيح الناقصة، والزائدة، والأماكن الفارغة غير المتطابقة",
        w_missing="ناقص في", w_extra="ليس في en", w_ph="الأماكن الفارغة مختلفة:", w_ok="كل المفاتيح متطابقة.",
        w_problems="مشكلات",
    ),
}

PLAIN, NODE, BROWSER = {}, {}, {}

NODE["numbers.ts"] = '''// {w_c1}
const price = 1234567.5;
const show = (locale: string, options: Intl.NumberFormatOptions = {}) =>
  console.log(locale.padEnd(18), new Intl.NumberFormat(locale, options).format(price));

show("en-US");
show("de-DE");
show("ar-EG");
show("ar-EG-u-nu-latn");
show("ar-SA", { style: "currency", currency: "SAR" });
show("en-EG", { style: "currency", currency: "EGP" });
show("ar-EG", { notation: "compact" });
'''

NODE["dates.ts"] = '''const date = new Date(Date.UTC(2026, 2, 20, 14, 30));
const fmt = (locale: string, options: Intl.DateTimeFormatOptions) =>
  console.log(locale.padEnd(26), new Intl.DateTimeFormat(locale, { timeZone: "Africa/Cairo", ...options }).format(date));

fmt("en-GB", { dateStyle: "full", timeStyle: "short" });
fmt("en-US", { dateStyle: "full", timeStyle: "short" });
fmt("ar-EG", { dateStyle: "full", timeStyle: "short" });
fmt("ar-SA-u-ca-islamic-umalqura", { dateStyle: "long" });

const rtf = new Intl.RelativeTimeFormat("ar", { numeric: "auto" });
console.log([-1, 0, 1, 2, 3, 11].map((d) => rtf.format(d, "day")).join(" | "));
console.log(new Intl.ListFormat("ar", { type: "conjunction" }).format(["HTML", "CSS", "JavaScript"]));
'''

NODE["plurals.ts"] = '''// {w_c2}
const ar = new Intl.PluralRules("ar");
const en = new Intl.PluralRules("en");

for (const n of [0, 1, 2, 3, 10, 11, 100, 101]) {
  console.log(String(n).padStart(3), "ar:", ar.select(n).padEnd(5), " en:", en.select(n));
}
console.log("ar categories:", ar.resolvedOptions().pluralCategories.join(", "));
'''

PLAIN["messages.ts"] = '''// {w_c3}
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
  return text.replace(/\\{(\\w+)\\}/g, (_, name: string) => {
    const value = values[name];
    return typeof value === "number" ? format.format(value) : String(value ?? "");
  });
}
'''

NODE["translate.ts"] = '''import { translate } from "./messages";

for (const n of [0, 1, 2, 5, 11, 100]) {
  console.log(String(n).padStart(3), "|", translate("ar", "cart.items", { count: n }).padEnd(12), "|", translate("en", "cart.items", { count: n }));
}
'''

CSS = """.cards { display: grid; gap: 12px; }
.card { background: white; border-radius: 14px; padding: 12px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
.card h2 { margin: 0 0 6px; display: flex; align-items: center; gap: 8px; }
.row { display: flex; justify-content: space-between; gap: 12px; padding: 4px 0; border-bottom: 1px solid #eef2ff; }
.badge { margin-inline-start: auto; background: #4338ca; color: white; border-radius: 999px; padding: 0 10px; font-size: 0.85rem; }
.next::after { content: "→"; display: inline-block; margin-inline-start: 6px; }
[dir="rtl"] .next::after { transform: scaleX(-1); }
.muted { color: #5b5873; font-size: 0.9rem; }
.bad { border-inline-start: 4px solid #b91c1c; }
.good { border-inline-start: 4px solid #047857; }
"""

PLAIN["react/I18n.tsx"] = '''import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
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
'''

BROWSER["react/cart.tsx"] = ('''import { createRoot } from "react-dom/client";
import { I18nProvider, useI18n } from "./I18n";

const LINES = [
  { name: "Code from Zero", price: 250 },
  { name: "Bit mug", price: 85 },
];

function Cart() {
  const { t, money, locale, setLocale } = useI18n();
  const total = LINES.reduce((sum, l) => sum + l.price, 0);
  return (
    <section className="card">
      <h2>
        {t("cart.title")}
        <span className="badge">{t("cart.items", { count: LINES.length })}</span>
      </h2>
      {LINES.map((l) => (
        <div className="row" key={l.name}>
          <bdi>{l.name}</bdi>
          <span>{money(l.price)}</span>
        </div>
      ))}
      <p>
        <b>{t("cart.total", { total: money(total) })}</b>
      </p>
      <button className="next" onClick={() => setLocale(locale === "ar" ? "en" : "ar")}>
        {locale === "ar" ? "English" : "العربية"}
      </button>
    </section>
  );
}

createRoot(document.getElementById("root")!).render(
  <I18nProvider initial="{start}">
    <Cart />
  </I18nProvider>,
);
''', CSS)

PLAIN["bidi.html"] = '''<!doctype html>
<html lang="ar" dir="rtl">
  <head>
    <meta charset="utf-8">
    <style>
      body { font-family: system-ui, "Segoe UI", Tahoma, sans-serif; margin: 0; padding: 16px; background: #f5f5fb; color: #1e1b2e; }
CSS_HERE    </style>
  </head>
  <body>
    <div class="cards">
      <div class="card bad">
        <p>طلب <span>#1042</span> من <span>Sara Khan</span> (3 items)</p>
        <p>الهاتف: <span>+20 100 123 4567</span></p>
        <p>البريد: <span>sara@example.com</span></p>
      </div>
      <div class="card good">
        <p>طلب <bdi>#1042</bdi> من <bdi>Sara Khan</bdi> (<bdi>3 items</bdi>)</p>
        <p>الهاتف: <span dir="ltr">+20 100 123 4567</span></p>
        <p>البريد: <span dir="ltr">sara@example.com</span></p>
      </div>
    </div>
  </body>
</html>
'''.replace("CSS_HERE", "".join("      " + l + "\n" for l in CSS.splitlines()))

# ---------------------------------------------------------------- projects
PLAIN["projects/en.json"] = '''{
  "nav.home": "Home",
  "nav.cart": "Cart",
  "cart.total": "Total: {total}",
  "order.placed": "Order #{id} placed on {date}",
  "profile.greeting": "Hello, {name}!"
}
'''
PLAIN["projects/ar.json"] = '''{
  "nav.home": "الرئيسية",
  "cart.total": "المجموع: {sum}",
  "order.placed": "تم الطلب #{id} في {date}",
  "profile.greeting": "أهلاً يا {name}!",
  "profile.old": "إعداد قديم"
}
'''

NODE["projects/check-messages.ts"] = '''import { readFileSync } from "node:fs";

// {w_c4}
const load = (file: string) => JSON.parse(readFileSync(new URL(file, import.meta.url), "utf8")) as Record<string, string>;
const en = load("./en.json");
const ar = load("./ar.json");
const placeholders = (text: string) => [...text.matchAll(/\\{(\\w+)\\}/g)].map((m) => m[1]).sort().join(",");

let problems = 0;
for (const key of Object.keys(en)) {
  if (!(key in ar)) {
    console.log(`✗ ${key}: {w_missing} ar`);
    problems++;
  } else if (placeholders(en[key]!) !== placeholders(ar[key]!)) {
    console.log(`✗ ${key}: {w_ph} en {${placeholders(en[key]!)}} ar {${placeholders(ar[key]!)}}`);
    problems++;
  }
}
for (const key of Object.keys(ar)) {
  if (!(key in en)) {
    console.log(`✗ ${key}: {w_extra}`);
    problems++;
  }
}
console.log(problems === 0 ? "{w_ok}" : `${problems} {w_problems}`);
process.exitCode = problems ? 1 : 0;
'''

for lang in T:
    T[lang]["start"] = lang

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER, title_key="w_title")


# ---------------------------------------------------------------- the same example in Vue (Vue edition), under vue/
import subprocess  # noqa: E402
import vue_kit  # noqa: E402

VPLAIN, VBROWSER = {}, {}
VPLAIN["vue/tsconfig.json"] = """{
  "compilerOptions": {
    "strict": true, "noUncheckedIndexedAccess": true, "target": "es2024", "module": "esnext",
    "moduleResolution": "bundler", "lib": ["es2024", "dom", "dom.iterable"], "types": ["node"], "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["**/*.ts", "**/*.vue"]
}
"""
VPLAIN["vue/i18n.ts"] = """import { computed, inject, provide, ref, watchEffect, type ComputedRef, type InjectionKey, type Ref } from "vue";
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
"""
VPLAIN["vue/Cart.vue"] = """<script setup lang="ts">
import { useI18n } from "./i18n";

const LINES = [
  { name: "Code from Zero", price: 250 },
  { name: "Bit mug", price: 85 },
];
const { t, money, locale } = useI18n();
const total = LINES.reduce((sum, l) => sum + l.price, 0);
</script>

<template>
  <section class="card">
    <h2>
      {{ t("cart.title") }}
      <span class="badge">{{ t("cart.items", { count: LINES.length }) }}</span>
    </h2>
    <div v-for="l in LINES" :key="l.name" class="row">
      <bdi>{{ l.name }}</bdi>
      <span>{{ money(l.price) }}</span>
    </div>
    <p><b>{{ t("cart.total", { total: money(total) }) }}</b></p>
    <button type="button" class="next" @click="locale = locale === 'ar' ? 'en' : 'ar'">
      {{ locale === "ar" ? "English" : "العربية" }}
    </button>
  </section>
</template>
"""
VPLAIN["vue/CartApp.vue"] = """<script setup lang="ts">
import Cart from "./Cart.vue";
import { provideI18n } from "./i18n";

provideI18n("{start}");
</script>

<template>
  <Cart />
</template>
"""
VBROWSER["vue/cart.ts"] = ("""import { createApp } from "vue";
import CartApp from "./CartApp.vue";

createApp(CartApp).mount("#app");
""", CSS)

vue_kit.generate(HERE, T, plain=VPLAIN, browser_files=VBROWSER)
check = HERE.parent / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "vue" / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("vue types ok")
