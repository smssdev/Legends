import assert from 'node:assert/strict';
import { linePrice } from './price.mjs';

// Test normal cases
test('linePrice with valid inputs', () => {
  assert.equal(linePrice(100, 1), 100);
  assert.equal(linePrice(100, 5), 500);
  assert.equal(linePrice(100, 10), 900);
  assert.equal(linePrice(100, 15), 1350);
});

// Test boundary cases: quantity = 1
test('linePrice with quantity = 1', () => {
  assert.equal(linePrice(100, 1), 100);
});

// Test boundary cases: quantity = 10 (threshold for discount)
test('linePrice with quantity = 10', () => {
  assert.equal(linePrice(100, 10), 900);
});

// Test boundary cases: quantity = 11 (after threshold)
test('linePrice with quantity = 11', () => {
  assert.equal(linePrice(100, 11), 990);
});

// Test maximum discount (5000 off)
test('linePrice with quantity >= 10 and full price > 50000', () => {
  assert.equal(linePrice(6000, 10), 6000 - 5000, 1000);
});

// Test when discount would exceed 5000
test('linePrice with quantity >= 10 and full price <= 50000', () => {
  assert.equal(linePrice(10000, 10), 10000 - 1000, 9000);
});

// Test edge case: very large quantity
test('linePrice with large quantity', () => {
  assert.equal(linePrice(100, 100), 9000);
});

// Test error case: quantity less than 1
test('linePrice throws error for quantity < 1', () => {
  assert.throws(() => linePrice(100, 0), RangeError, 'quantity must be at least 1');
  assert.throws(() => linePrice(100, -1), RangeError, 'quantity must be at least 1');
});

// Test edge case: unit price is 0
test('linePrice with unit price 0', () => {
  assert.equal(linePrice(0, 10), 0);
});

// Test edge case: unit price is 1, quantity is 10
test('linePrice with unit price 1 and quantity 10', () => {
  assert.equal(linePrice(1, 10), 9);
});
