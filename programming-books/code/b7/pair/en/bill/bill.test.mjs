import { test, describe } from 'node:test';
import { strict as assert } from 'node:assert';

import { splitBill } from './bill.mjs';

describe('splitBill', () => {
  test('normal case with even division', () => {
    const result = splitBill(1000, 4, 0);
    assert.deepEqual(result, [250, 250, 250, 250]);
  });

  test('uneven division with tip', () => {
    const result = splitBill(1000, 3, 10);
    assert.deepEqual(result, [367, 367, 366]);
  });

  test('tip that needs rounding', () => {
    const result = splitBill(995, 2, 15);
    assert.deepEqual(result, [572, 572]);
  });

  test('throws RangeError when people is less than 1', () => {
    assert.throws(() => splitBill(100, 0, 10), RangeError);
  });

  test('handles tip rounding correctly', () => {
    const result = splitBill(100, 2, 1);
    assert.deepEqual(result, [51, 50]);
  });

  test('single person pays full amount', () => {
    const result = splitBill(100, 1, 10);
    assert.deepEqual(result, [110]);
  });
});
