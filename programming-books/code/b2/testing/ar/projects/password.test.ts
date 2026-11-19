import { expect, it } from "vitest";
import { strength } from "./password";

it.each([
  ["", "weak"],
  ["cat", "weak"],
  ["sunshine", "weak"],
  ["sunshine2026", "okay"],
  ["Sunshine2026", "strong"],
  ["correct horse battery staple", "okay"],
] as const)("يقيّم %s بأنها %s", (password, expected) => {
  expect(strength(password)).toBe(expected);
});
