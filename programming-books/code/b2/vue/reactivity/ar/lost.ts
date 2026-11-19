import { reactive, toRefs } from "vue";

const product = reactive({ name: "كوب بِت", stock: 3 });

// التفكيك ينسخ العدد مرة واحدة، وtoRefs تحفظ رابطاً بالكائن
const { stock } = product;
const { stock: stockRef } = toRefs(product);

product.stock = 2;
console.log("القيمة المنسوخة:", stock);
console.log("المرجع المرتبط:", stockRef.value);
