import assert from "node:assert/strict";
import { test } from 'node:test';
import { linePrice } from './price.mjs';

test('linePrice should return correct price for normal cases', () => {
  assert.equal(linePrice(1000, 9), 9000);
  assert.equal(linePrice(1000, 10), 9000);
  assert.equal(linePrice(6000, 10), 55000);
  assert.equal(linePrice(500, 1), 500);
  assert.equal(linePrice(2000, 5), 10000);
});

test('linePrice should throw RangeError when quantity is less than 1', () => {
  assert.throws(() => linePrice(1000, 0), RangeError, 'quantity must be at least 1');
  assert.throws(() => linePrice(1000, -1), RangeError, 'quantity must be at least 1');
  assert.throws(() => linePrice(1000, -5), RangeError, 'quantity must be at least 1');
});

test('linePrice should not apply discount for quantity less than 10', () => {
  assert.equal(linePrice(500, 5), 2500);
  assert.equal(linePrice(200, 8), 1600);
  assert.equal(linePrice(100, 1), 100);
});

