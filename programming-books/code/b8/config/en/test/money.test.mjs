import test from "node:test";
import assert from "node:assert/strict";
import {format} from "../src/money.mjs";

test("whole pounds", () => assert.equal(format(4500), "45.00"));
test("piastres", () => assert.equal(format(8550), "85.50"));
test("zero", () => assert.equal(format(0), "0.00"));
