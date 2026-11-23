import test from 'node:test';
import assert from 'node:assert/strict';
import { linePrice } from './price.mjs';

test('linePrice returns correct price for normal cases', () => {
  assert.strictEqual(linePrice(100, 1), 100);
  assert.strictEqual(linePrice(100, 5), 500);
  assert.strictEqual(linePrice(100, 10), 900);
  assert.strictEqual(linePrice(100, 15), 1350);
});

test('linePrice applies 10% off from the 10th cup', () => {
  assert.strictEqual(linePrice(100, 10), 900);
  assert.strictEqual(linePrice(100, 11), 990);
  assert.strictEqual(linePrice(100, 20), 1800);
});

test('linePrice caps discount at 5000', () => {
  assert.strictEqual(linePrice(100000, 10), 900000);
  assert.strictEqual(linePrice(100000, 11), 990000);
  assert.strictEqual(linePrice(100000, 100), 9000000);
  assert.strictEqual(linePrice(100000, 1000), 9000000);
});

test('linePrice throws error for invalid quantity', () => {
  assert.throws(() => linePrice(100, 0), RangeError, 'quantity must be at least 1');
  assert.throws(() => linePrice(100, -1), RangeError, 'quantity must be at least 1');
});

test('linePrice handles edge cases with unit price 0', () => {
  assert.strictEqual(linePrice(0, 1), 0);
  assert.strictEqual(linePrice(0, 10), 0);
});

test('linePrice handles large quantities with high unit price', () => {
  assert.strictEqual(linePrice(1000, 10), 9000);
  assert.strictEqual(linePrice(1000, 100), 90000);
  assert.strictEqual(linePrice(1000, 1000), 900000);
});
