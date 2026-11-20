import { hashPassword, verifyPassword } from "../src/password.ts";

const a = await hashPassword("correct horse battery staple");
const b = await hashPassword("correct horse battery staple");
console.log("التجزئة 1", a);
console.log("التجزئة 2", b);
console.log(
  "كلمة المرور الصحيحة:",
  await verifyPassword("correct horse battery staple", a),
);
console.log(
  "كلمة مرور خطأ:",
  await verifyPassword("correct horse battery stapler", a),
);
const start = performance.now();
await hashPassword("correct horse battery staple");
console.log("استغرقت التجزئة الواحدة", Math.round(performance.now() - start), "ms");
