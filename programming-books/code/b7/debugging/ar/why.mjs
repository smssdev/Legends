import {ask} from "./lib/ask.mjs";

// مخرجات أي أمر، عبر أنبوب: node broken.mjs 2>&1 | node why.mjs
let output = "";
for await (const chunk of process.stdin) {
  output += chunk;
}
const lines = output.split("\n").filter((line) => !line.includes("node:internal"));
console.log(await ask(`اشرح مخرجات الخطأ هذه لمطور في أربعة أسطر على الأكثر: ما الذي فشل، والسبب المحتمل، وأول ما يجب فحصه.\n\n${lines.join("\n")}`, {maxTokens: 200}));
