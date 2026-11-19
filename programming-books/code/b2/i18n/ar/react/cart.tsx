import { createRoot } from "react-dom/client";
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
  <I18nProvider initial="ar">
    <Cart />
  </I18nProvider>,
);
