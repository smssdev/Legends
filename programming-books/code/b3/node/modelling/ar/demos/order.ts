import { db } from "../src/db.ts";
import { findOrder } from "../src/orders.ts";

const order = await findOrder(2);
console.log(order);
await db.destroy();
