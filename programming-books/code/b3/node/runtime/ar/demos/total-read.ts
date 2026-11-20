import { readFile } from "node:fs/promises";

const text = await readFile("orders.csv", "utf8"); // the whole file in memory
let total = 0;
for (const line of text.split("\n").slice(1)) {
  if (line) total += Number(line.split(",")[2]);
}
const peak = Math.round(process.resourceUsage().maxRSS / 1024);
console.log(`الإجمالي: ${total}, أقصى ذاكرة: ${peak} MB`);
