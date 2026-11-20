import type { RouteRecordRaw } from "vue-router";
import Layout from "./views/Layout.vue";
import Home from "./views/Home.vue";
import Products from "./views/Products.vue";
import Product from "./views/Product.vue";
import NotFound from "./views/NotFound.vue";

// Each route maps an address to a component; children are drawn inside their parent's RouterView
export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    component: Layout,
    children: [
      { path: "", component: Home },
      {
        path: "products",
        children: [
          { path: "", component: Products },
          // Pass the id as a typed prop, so the component does not need to know about the router
          { path: ":id(\\d+)", component: Product, props: (route) => ({ id: Number(route.params.id) }) },
        ],
      },
      { path: ":path(.*)*", component: NotFound },
    ],
  },
];
