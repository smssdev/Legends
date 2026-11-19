// vue/reactivity/en/lost.ts
import { reactive, toRefs } from "vue";
var product = reactive({ name: "Bit mug", stock: 3 });
var { stock } = product;
var { stock: stockRef } = toRefs(product);
product.stock = 2;
console.log("Copied value:", stock);
console.log("Linked ref:", stockRef.value);
