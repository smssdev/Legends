import test from 'node:test';
import assert from 'node:assert/strict';
import { linePrice } from './price.mjs';

test('linePrice returns correct value for normal cases', () => {
  assert.strictEqual(linePrice(1000, 9), 9000);
  assert.strictEqual(linePrice(1000, 10), 9000);
  assert.strictEqual(linePrice(6000, 10), 55000);
});

test('linePrice applies 10% off from the 10th cup', () => {
  assert.strictEqual(linePrice(1000, 10), 9000);
  assert.strictEqual(linePrice(2000, 10), 18000);
  assert.strictEqual(linePrice(1000, 15), 13500);
});

test('linePrice throws error for invalid quantity', () => {
  assert.throws(() => linePrice(1000, 0), RangeError, 'quantity must be at least 1');
  assert.throws(() => linePrice(1000, -1), RangeError, 'quantity must be at least 1');
});

test('linePrice handles edge cases with quantity = 1', () => {
  assert.strictEqual(linePrice(1000, 1), 1000);
  assert.strictEqual(linePrice(5000, 1), 5000);
});

test('linePrice with unit price 0', () => {
  assert.strictEqual(linePrice(0, 10), 0);
  assert.strictEqual(linePrice(0, 1), 0);
});

