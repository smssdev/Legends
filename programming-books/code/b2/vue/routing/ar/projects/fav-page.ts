// لصور الكتاب فقط: المسارات نفسها، بسجل في الذاكرة
import { createApp, h } from "vue";
import { VueQueryPlugin } from "@tanstack/vue-query";
import FavouriteButton from "./FavouriteButton.vue";
import { server } from "../api";

server.failNextSave = false;
createApp({ render: () => h(FavouriteButton, { id: 2 }) })
  .use(VueQueryPlugin)
  .mount("#app");
