import {test} from "node:test";
import assert from "node:assert/strict";
import {linePrice} from "../src/price.mjs";

test("no discount below 10 cups", () => {
  assert.equal(linePrice(1000, 9), 9000);
});

test("10% off from the 10th cup", () => {
  assert.equal(linePrice(1000, 10), 9000);
});

test("at most 5000 off", () => {
  assert.equal(linePrice(6000, 10), 55000);
});
