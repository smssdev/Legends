import { percentile, random } from "./random.ts";

// items finished in each of the last 12 weeks, from the tracker
const done = [4, 6, 3, 5, 0, 7, 5, 4, 6, 2, 5, 6];
// what is left: stories already sliced to a similar small size
const backlog = 38;

const next = random(7);
const weeks: number[] = [];
for (let run = 0; run < 10_000; run++) {
  let left = backlog;
  let week = 0;
  while (left > 0) {
    // a future week looks like a past week, picked at random
    left -= done[Math.floor(next() * done.length)]!;
    week++;
  }
  weeks.push(week);
}
weeks.sort((a, b) => a - b);

// the forecast from the average week, for comparison
const average = done.reduce((a, b) => a + b, 0) / done.length;
console.log(`left: ${backlog} items, average week: ${average.toFixed(1)}`);
console.log(`from the average: ${Math.ceil(backlog / average)} weeks`);
for (const p of [50, 85, 95]) {
  console.log(`P${p}: ${percentile(weeks, p)} weeks`);
}
