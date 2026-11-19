// For the book's screenshots only: the same routes, with a memory history
import { createApp } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import App from "./App.vue";
import { routes } from "./routes";

const router = createRouter({ history: createMemoryHistory(), routes });
await router.push("/");
createApp(App)
  .use(router)
  .use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 30_000 } } } })
  .mount("#app");
