import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { Ajv2020 } from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import type { LightMyRequestResponse } from "fastify";
import { parse } from "yaml";
import { buildApp } from "../src/app.ts";

const contract = parse(readFileSync("openapi.yaml", "utf8"));
const ajv = new Ajv2020({ strict: false, allErrors: true });
addFormats.default(ajv);
ajv.addSchema(contract, "api");
const pointer = (part: string) => part.replaceAll("~", "~0").replaceAll("/", "~1");

// every response must be in the contract, with its documented type and shape
function check(method: string, path: string, res: LightMyRequestResponse) {
  const responses = contract.paths[path]?.[method]?.responses ?? {};
  const doc = responses[res.statusCode];
  assert.ok(
    doc,
    `${method.toUpperCase()} ${path} ${res.statusCode} is not in the contract`,
  );
  const [type] = Object.keys(doc.content);
  assert.equal(String(res.headers["content-type"]).split(";")[0], type);
  // the response's schema, found in the contract by its JSON pointer
  const ref = `/paths/${pointer(path)}/${method}/responses/${res.statusCode}/content/${pointer(type!)}/schema`;
  const validate = ajv.getSchema(`api#${ref}`)!;
  assert.ok(validate(res.json()), ajv.errorsText(validate.errors));
}

const booking = {
  staff_id: 1,
  starts_at: "2026-12-01T10:00:00+02:00",
  email: "sara@example.com",
};

test("lists free slots in the documented shape", async () => {
  const res = await buildApp().inject({ url: "/slots?staff_id=1&date=2026-12-01" });
  check("get", "/slots", res);
});

test("creates a booking in the documented shape", async () => {
  const res = await buildApp().inject({
    method: "POST",
    url: "/bookings",
    body: booking,
  });
  check("post", "/bookings", res);
});

test("answers 409 with a Problem when the slot is taken", async () => {
  const app = buildApp();
  await app.inject({ method: "POST", url: "/bookings", body: booking });
  const res = await app.inject({ method: "POST", url: "/bookings", body: booking });
  assert.equal(res.statusCode, 409);
  check("post", "/bookings", res);
});

test("answers 422 with a Problem when the email is invalid", async () => {
  const body = { ...booking, email: "not an email" };
  const res = await buildApp().inject({ method: "POST", url: "/bookings", body });
  check("post", "/bookings", res);
});
