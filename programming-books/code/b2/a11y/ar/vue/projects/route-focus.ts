import { createApp, h } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import FocusApp from "./FocusApp.vue";
import { routeFocus } from "./routeFocus";

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", component: { render: () => h("h1", "الرئيسية") } },
    { path: "/orders", component: { render: () => h("h1", "طلباتك") } },
  ],
});
routeFocus(router, "متجر بِت");
await router.push("/");
createApp(FocusApp).use(router).mount("#app");
