import { cartTotal, formatPrice, VAT } from "./index.mjs";
import * as prices from "./prices.mjs";

console.log("Imported:", typeof cartTotal, typeof formatPrice, VAT);
console.log("Cart total:", cartTotal([25, 8, 3]));
console.log(prices.withVat(100), prices.default(9));
console.log("Times the price module was loaded:", globalThis.priceLoads);
