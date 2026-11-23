import {total} from "./orders.mjs";

const orders = [
  {id: 41, items: [{name: "latte", count: 2}]},
  {id: 42, items: [{name: "flat white", count: 1}]},
  {id: 43, items: [{name: "tea", count: 3}]},
];

for (const order of orders) {
  console.log(`order ${order.id}: ${total(order)}`);
}
