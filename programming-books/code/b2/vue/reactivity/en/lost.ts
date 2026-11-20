import { reactive, toRefs } from "vue";

const product = reactive({ name: "Bit mug", stock: 3 });

// Destructuring copies the number once; toRefs keeps a link to the object
const { stock } = product;
const { stock: stockRef } = toRefs(product);

product.stock = 2;
console.log("Copied value:", stock);
console.log("Linked ref:", stockRef.value);
