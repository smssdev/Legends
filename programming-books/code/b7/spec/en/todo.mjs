import fs from "node:fs";
import {criteria} from "./lib/vague.mjs";

// One pending test per acceptance criterion: the specification becomes
// the test list.
const lines = criteria(fs.readFileSync("spec.md", "utf8"));
const tests = lines.map(({line}) => `test(${JSON.stringify(line)}, {todo: true});`);
fs.writeFileSync("loyalty.test.mjs", `import {test} from "node:test";\n\n${tests.join("\n")}\n`);
console.log(`loyalty.test.mjs: ${tests.length} pending tests`);
