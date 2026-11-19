import type { RouteRecordRaw } from "vue-router";
import Layout from "./views/Layout.vue";
import Home from "./views/Home.vue";
import Products from "./views/Products.vue";
import Product from "./views/Product.vue";
import NotFound from "./views/NotFound.vue";

// كل مسار يربط عنواناً بمكوّن، والأبناء يُرسمون داخل RouterView الخاص بأبيهم
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
          // مرّر المعرّف خاصيةً بنوعها، فلا يحتاج المكوّن أن يعرف شيئاً عن الموجّه
          { path: ":id(\\d+)", component: Product, props: (route) => ({ id: Number(route.params.id) }) },
        ],
      },
      { path: ":path(.*)*", component: NotFound },
    ],
  },
];
