import { createSSRApp, h } from "vue";
import { renderToString } from "vue/server-renderer";
import CartTotal from "./CartTotal.vue";
import { counts } from "./counts";

console.log(await renderToString(createSSRApp({ render: () => h(CartTotal, { prices: [25, 8, 12] }) })));
console.log("Calls to the method:", counts.method);
console.log("Calls to the computed value:", counts.computed);
