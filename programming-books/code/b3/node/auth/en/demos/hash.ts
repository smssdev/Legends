import { hashPassword, verifyPassword } from "../src/password.ts";

const a = await hashPassword("correct horse battery staple");
const b = await hashPassword("correct horse battery staple");
console.log("hash 1", a);
console.log("hash 2", b);
console.log(
  "right password:",
  await verifyPassword("correct horse battery staple", a),
);
console.log(
  "wrong password:",
  await verifyPassword("correct horse battery stapler", a),
);
const start = performance.now();
await hashPassword("correct horse battery staple");
console.log("one hash took", Math.round(performance.now() - start), "ms");
