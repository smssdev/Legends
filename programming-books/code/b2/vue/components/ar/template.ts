import { createSSRApp, h } from "vue";
import { renderToString } from "vue/server-renderer";
import CartSummary from "./CartSummary.vue";

console.log(await renderToString(createSSRApp({ render: () => h(CartSummary, { count: 3, total: 41 }) })));
console.log(await renderToString(createSSRApp({ render: () => h(CartSummary, { count: 0, total: 0 }) })));
