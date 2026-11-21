import { type Booking, gaps, gapsNaive } from "./slots.ts";

function calendar(minutes: number, count: number): Booking[] {
  return Array.from({ length: count }, (_, i) => {
    const start = Math.floor((i * minutes) / count);
    return { start, end: start + 20 };
  });
}

function time(work: () => unknown) {
  const start = performance.now();
  work();
  return `${(performance.now() - start).toFixed(1)} ms`;
}

// bigger and bigger calendars: one booking every 30 minutes
for (const count of [20, 200, 2_000, 20_000]) {
  const minutes = count * 30;
  const bookings = calendar(minutes, count);
  const naive = time(() => gapsNaive(bookings, 0, minutes));
  const sorted = time(() => gaps(bookings, 0, minutes));
  const label = `${count.toLocaleString("en")} bookings`.padEnd(16);
  console.log(
    `${label} every minute ${naive.padStart(11)}   sort once ${sorted}`,
  );
}
