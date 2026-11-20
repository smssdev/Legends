// للصور واختبارات الطرف إلى الطرف فقط
import { createApp } from "vue";
import { createPinia } from "pinia";
import { createMemoryHistory, createRouter } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { fakeFetch, server } from "./src/api/fake-server";
import App from "./src/app/App.vue";
import { routes } from "./src/app/routes";

window.fetch = fakeFetch;
Object.assign(window, { server }); // so a test can say: server.failNextChange = true
localStorage.clear(); // start from the page's own language and the light theme

const router = createRouter({ history: createMemoryHistory(), routes });
await router.push("/");
createApp(App)
  .use(createPinia())
  .use(router)
  .use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 30_000, retry: false } } } })
  .mount("#app");
