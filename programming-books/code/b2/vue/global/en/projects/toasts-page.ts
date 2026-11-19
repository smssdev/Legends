import { createApp } from "vue";
import { createPinia } from "pinia";
import Shelf from "./Shelf.vue";

createApp(Shelf).use(createPinia()).mount("#app");
