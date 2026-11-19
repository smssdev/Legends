import { createApp } from "vue";
import ThemeApp from "./ThemeApp.vue";

localStorage.clear();
createApp(ThemeApp).mount("#app");
