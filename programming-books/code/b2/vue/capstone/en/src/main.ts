import { createApp } from "vue";
import { createPinia } from "pinia";
import { createRouter, createWebHistory } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import App from "./app/App.vue";
import { routes } from "./app/routes";

createApp(App)
  .use(createPinia())
  .use(createRouter({ history: createWebHistory(), routes }))
  .use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 30_000, retry: 1 } } } })
  .mount("#app");
