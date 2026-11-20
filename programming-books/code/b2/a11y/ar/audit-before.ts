import { audit } from "./audit-lib";

const count = await audit("./before.html");
console.log(`قبل: ${count} مشكلات`);
