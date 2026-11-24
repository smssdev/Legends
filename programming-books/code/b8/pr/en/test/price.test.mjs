import test from "node:test";
import assert from "node:assert/strict";
import {total} from "../src/price.mjs";

test("a round bill", () => assert.equal(total("100", 10).toFixed(2), "110.00"));
