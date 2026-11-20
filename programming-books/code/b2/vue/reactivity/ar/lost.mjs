// vue/reactivity/ar/lost.ts
import { reactive, toRefs } from "vue";
var product = reactive({ name: "\u0643\u0648\u0628 \u0628\u0650\u062A", stock: 3 });
var { stock } = product;
var { stock: stockRef } = toRefs(product);
product.stock = 2;
console.log("\u0627\u0644\u0642\u064A\u0645\u0629 \u0627\u0644\u0645\u0646\u0633\u0648\u062E\u0629:", stock);
console.log("\u0627\u0644\u0645\u0631\u062C\u0639 \u0627\u0644\u0645\u0631\u062A\u0628\u0637:", stockRef.value);
