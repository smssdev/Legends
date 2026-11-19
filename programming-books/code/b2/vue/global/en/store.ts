import { createApp } from "vue";
import { createPinia } from "pinia";
import ShopApp from "./ShopApp.vue";

localStorage.clear(); // for the screenshot: start with an empty cart
createApp(ShopApp).use(createPinia()).mount("#app");
