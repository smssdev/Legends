import { cartTotal, formatPrice, VAT } from "./index.mjs";
import * as prices from "./prices.mjs";

console.log("المستورد:", typeof cartTotal, typeof formatPrice, VAT);
console.log("مجموع السلة:", cartTotal([25, 8, 3]));
console.log(prices.withVat(100), prices.default(9));
console.log("عدد مرات تحميل وحدة الأسعار:", globalThis.priceLoads);
