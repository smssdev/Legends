import { audit } from "./audit-lib";

const count = await audit("./after.html");
console.log(count === 0 ? "No violations found." : `After: ${count} issues`);
