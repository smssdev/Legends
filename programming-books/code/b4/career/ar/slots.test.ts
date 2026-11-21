import assert from "node:assert/strict";
import { test } from "node:test";
import { type Booking, gaps, gapsNaive } from "./slots.ts";

// الحالات التي يسأل عنها المقابِلون: لا شيء، ومتداخلة، ومتلامسة، وغير مرتبة، وممتلئ
const cases: [string, Booking[], Booking[]][] = [
  ["اليوم الفارغ فجوة واحدة", [], [{ start: 0, end: 600 }]],
  [
    "حجوزات متداخلة",
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
    "الحجوزات المتلامسة لا تترك فجوة",
    [
      { start: 0, end: 300 },
      { start: 300, end: 600 },
    ],
    [],
  ],
  [
    "مدخلات غير مرتبة",
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
  ["اليوم الممتلئ بلا فجوات", [{ start: 0, end: 600 }], []],
];

for (const [name, bookings, expected] of cases) {
  test(name, () => {
    assert.deepEqual(gaps(bookings, 0, 600), expected);
    assert.deepEqual(gapsNaive(bookings, 0, 600), expected);
  });
}

// في أيام عشوائية، يجب أن تتفق النسختان
test("تتفقان في 200 يوم عشوائي", () => {
  for (let day = 0; day < 200; day++) {
    const bookings = Array.from({ length: 12 }, () => {
      const start = Math.floor(Math.random() * 570);
      return { start, end: start + 15 + Math.floor(Math.random() * 60) };
    });
    assert.deepEqual(gaps(bookings, 0, 600), gapsNaive(bookings, 0, 600));
  }
});
