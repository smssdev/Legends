import assert from "node:assert/strict";
import { test } from "node:test";
import { type Booking, gaps, gapsNaive } from "./slots.ts";

// what interviewers ask: empty, overlapping, touching, unsorted, full
const cases: [string, Booking[], Booking[]][] = [
  ["an empty day is one gap", [], [{ start: 0, end: 600 }]],
  [
    "overlapping bookings",
    [
      { start: 60, end: 120 },
      { start: 90, end: 150 },
    ],
    [
      { start: 0, end: 60 },
      { start: 150, end: 600 },
    ],
  ],
  [
    "bookings that touch leave no gap",
    [
      { start: 0, end: 300 },
      { start: 300, end: 600 },
    ],
    [],
  ],
  [
    "unsorted input",
    [
      { start: 400, end: 450 },
      { start: 100, end: 200 },
    ],
    [
      { start: 0, end: 100 },
      { start: 200, end: 400 },
      { start: 450, end: 600 },
    ],
  ],
  ["a full day has no gaps", [{ start: 0, end: 600 }], []],
];

for (const [name, bookings, expected] of cases) {
  test(name, () => {
    assert.deepEqual(gaps(bookings, 0, 600), expected);
    assert.deepEqual(gapsNaive(bookings, 0, 600), expected);
  });
}

// on random days, both versions must agree
test("both agree on 200 random days", () => {
  for (let day = 0; day < 200; day++) {
    const bookings = Array.from({ length: 12 }, () => {
      const start = Math.floor(Math.random() * 570);
      return { start, end: start + 15 + Math.floor(Math.random() * 60) };
    });
    assert.deepEqual(gaps(bookings, 0, 600), gapsNaive(bookings, 0, 600));
  }
});
