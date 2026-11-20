import { createSSRApp } from "vue";
import { renderToString } from "vue/server-renderer";
import Greeting from "./Greeting.vue";

console.log(await renderToString(createSSRApp(Greeting)));
