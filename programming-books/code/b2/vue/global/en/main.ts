import { createApp } from "vue";
import { createPinia } from "pinia";
import ShopApp from "./ShopApp.vue";

createApp(ShopApp).use(createPinia()).mount("#app");
