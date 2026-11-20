import { useEffect } from "react";
import { NavLink, Outlet } from "react-router";
import type { RouteObject } from "react-router";
import { OrderPage } from "../features/orders/OrderPage";
import { OrdersPage } from "../features/orders/OrdersPage";
import { OverviewPage } from "../features/overview/OverviewPage";
import { useSettings, useT } from "../settings";

function Layout() {
  const t = useT();
  const { lang, dark, toggleLanguage, toggleDark } = useSettings();

  useEffect(() => {
    const html = document.documentElement;
    html.lang = lang;
    html.dir = lang === "ar" ? "rtl" : "ltr";
    html.classList.toggle("dark", dark);
  }, [lang, dark]);

  return (
    <div className="app">
      <a className="skip" href="#main">
        {t("skip")}
      </a>
      <nav className="side" aria-label={t("brand")}>
        <span className="brand">{t("brand")}</span>
        <NavLink to="/" end>
          {t("overview")}
        </NavLink>
        <NavLink to="/orders">{t("orders")}</NavLink>
        <NavLink to="/products">{t("products")}</NavLink>
      </nav>
      <div>
        <header className="top">
          <button type="button" className="secondary" onClick={toggleLanguage} lang={lang === "en" ? "ar" : "en"}>
            {t("switchLanguage")}
          </button>
          <button type="button" className="secondary" aria-pressed={dark} onClick={toggleDark}>
            {t("dark")}
          </button>
        </header>
        <main id="main">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

function NotFound() {
  const t = useT();
  return <p role="alert">{t("notFound")}</p>;
}

export const routes: RouteObject[] = [
  {
    element: <Layout />,
    children: [
      { path: "/", element: <OverviewPage /> },
      { path: "/orders", element: <OrdersPage /> },
      { path: "/orders/:id", element: <OrderPage /> },
      // Loaded only when opened: the form library is not part of the first download
      { path: "/products", lazy: () => import("../features/products/ProductsPage").then((m) => ({ Component: m.ProductsPage })) },
      { path: "/products/:id", lazy: () => import("../features/products/ProductsPage").then((m) => ({ Component: m.ProductPage })) },
      { path: "*", element: <NotFound /> },
    ],
  },
];
