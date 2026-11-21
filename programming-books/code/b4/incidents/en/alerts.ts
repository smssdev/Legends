import { during, month } from "./traffic.ts";

const minutes = month();
const budgetRate = 1 - 0.999;
// running totals, so any window is one subtraction
const req = [0];
const bad = [0];
for (const m of minutes) {
  req.push(req.at(-1)! + m.requests);
  bad.push(bad.at(-1)! + m.failed);
}
const rate = (end: number, length: number) => {
  const start = Math.max(0, end - length);
  return (bad[end]! - bad[start]!) / (req[end]! - req[start]!);
};

// page a person only when the budget burns fast; open a ticket when it burns slowly
const rules = [
  // the alert many teams start with: more than 1% failed in the last minute
  { name: "naive: >1% in 1 min", check: (i: number) => rate(i, 1) > 0.01 },
  // a long window proves it matters, a short one proves it is still happening
  {
    name: "page: 14.4x for 1 h and 5 min",
    check: (i: number) => burns(i, 14.4, 60, 5),
  },
  {
    name: "page: 6x for 6 h and 30 min",
    check: (i: number) => burns(i, 6, 360, 30),
  },
  {
    name: "ticket: 3x for 1 d and 2 h",
    check: (i: number) => burns(i, 3, 1440, 120),
  },
];
function burns(i: number, factor: number, long: number, short: number) {
  return (
    rate(i, long) > factor * budgetRate && rate(i, short) > factor * budgetRate
  );
}

console.log(
  "rule".padEnd(31),
  "fired".padStart(6),
  "real".padStart(6),
  "false".padStart(7),
);
for (const rule of rules) {
  const fired: number[] = [];
  let firing = false;
  for (let i = 1; i <= minutes.length; i++) {
    const now = rule.check(i);
    if (now && !firing) fired.push(i - 1);
    firing = now;
  }
  const real = fired.filter(during).length;
  const at = (i: number) => `day ${minutes[i]!.day} ${minutes[i]!.time}`;
  const when = fired.length < 4 ? fired.map(at).join(", ") : "";
  console.log(
    [
      rule.name.padEnd(31),
      String(fired.length).padStart(6),
      String(real).padStart(6),
      String(fired.length - real).padStart(7),
      when,
    ]
      .join(" ")
      .trimEnd(),
  );
}
