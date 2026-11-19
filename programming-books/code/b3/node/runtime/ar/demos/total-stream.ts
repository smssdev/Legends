import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";

const lines = createInterface({ input: createReadStream("orders.csv") });
let total = 0;
let first = true;
for await (const line of lines) {
  if (first) {
    first = false; // the header
    continue;
  }
  total += Number(line.split(",")[2]);
}
const peak = Math.round(process.resourceUsage().maxRSS / 1024);
console.log(`الإجمالي: ${total}, أقصى ذاكرة: ${peak} MB`);
