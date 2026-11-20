import { audit } from "./audit-lib";

const count = await audit("./after.html");
console.log(count === 0 ? "لا مخالفات." : `بعد: ${count} مشكلات`);
