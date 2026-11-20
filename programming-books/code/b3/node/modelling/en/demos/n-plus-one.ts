import * as data from "../src/db.ts";
import { customerOrdersAtOnce, customerOrdersOneByOne } from "../src/orders.ts";

for (const [label, load] of [
  ["one by one", customerOrdersOneByOne],
  ["at once", customerOrdersAtOnce],
] as const) {
  const before = data.queries;
  const start = performance.now();
  const orders = await load(1);
  const ms = Math.round(performance.now() - start);
  console.log(
    `${label.padEnd(11)} ${orders.length} orders, ${data.queries - before} queries, ${ms} ms`,
  );
}
await data.db.destroy();
