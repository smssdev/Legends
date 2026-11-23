// Prints the day's orders. Usage: node report.mjs [--date YYYY-MM-DD]
// [--vip] [--json]
import {parseArgs} from "node:util";

const {values} = parseArgs({
  options: {
    date: {type: "string", default: new Date().toISOString().slice(0, 10)},
    vip: {type: "boolean", default: false},
    json: {type: "boolean", default: false},
  },
});

const orders = [
  {id: 41, date: "2026-11-20", vip: true, total: 8500},
  {id: 42, date: "2026-11-20", vip: false, total: 22500},
];
const shown = orders.filter((o) => o.date === values.date && (!values.vip || o.vip));
console.log(values.json ? JSON.stringify(shown) : shown.map((o) => `${o.id} ${o.total}`).join("\n"));
