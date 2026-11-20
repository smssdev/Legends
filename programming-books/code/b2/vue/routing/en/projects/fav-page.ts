// For the book's screenshots only: the same routes, with a memory history
import { createApp, h } from "vue";
import { VueQueryPlugin } from "@tanstack/vue-query";
import FavouriteButton from "./FavouriteButton.vue";
import { server } from "../api";

server.failNextSave = false;
createApp({ render: () => h(FavouriteButton, { id: 2 }) })
  .use(VueQueryPlugin)
  .mount("#app");
