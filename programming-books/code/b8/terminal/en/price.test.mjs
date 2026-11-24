import test from "node:test";
import assert from "node:assert/strict";
import {total} from "./price.mjs";

test("a round bill", () => assert.equal(total("100", 10).toFixed(2), "110.00"));
test("a bill with piastres", () => assert.equal(total("85.50", 10).toFixed(2), "94.05"));
