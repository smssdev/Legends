import { h } from "vue";
import type { RouteRecordRaw } from "vue-router";
import OverviewPage from "../features/overview/OverviewPage.vue";
import OrdersPage from "../features/orders/OrdersPage.vue";
import OrderPage from "../features/orders/OrderPage.vue";

const id = (route: { params: Record<string, unknown> }) => ({ id: Number(route.params.id) });

export const routes: RouteRecordRaw[] = [
  { path: "/", component: OverviewPage },
  {
    path: "/orders",
    children: [
      { path: "", component: OrdersPage },
      { path: ":id(\\d+)", component: OrderPage, props: id },
    ],
  },
  {
    path: "/products",
    // يُحمَّل حين يُفتح فقط: كود النموذج ليس في التنزيل الأول
    children: [
      { path: "", component: () => import("../features/products/ProductsPage.vue") },
      { path: ":id(\\d+)", component: () => import("../features/products/ProductPage.vue"), props: id },
    ],
  },
  { path: "/:path(.*)*", component: { render: () => h("p", { role: "alert" }, "404") } },
];
