import { createWriteStream } from "node:fs";
import { once } from "node:events";

const file = createWriteStream("orders.csv");
file.write("id,customer,total\n");
for (let id = 1; id <= 1_000_000; id++) {
  const line = `${id},customer-${id % 97},${(id * 7919) % 100000}\n`;
  // write() returns false when the buffer is full: wait until it drains
  if (!file.write(line)) await once(file, "drain");
}
file.end();
await once(file, "finish");
console.log("1000000 orders written to orders.csv");
