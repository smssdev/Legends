import {ask} from "./lib/ask.mjs";

// The same request, vague and specific. Only the specific one says what
// correct means.
const vague = "Write a function that checks a phone number.";
const specific =
  "Write a JavaScript function isEgyptianMobile(text) that returns true only for " +
  "Egyptian mobile numbers: 11 digits starting with 010, 011, 012 or 015, or the same " +
  "number with +20 instead of the first 0. Spaces and dashes between digits are allowed. " +
  "Return only the code, in one code block.";

for (const prompt of [vague, specific]) {
  console.log(`> ${prompt}\n${await ask(prompt)}\n`);
}

// Then the specific answer is run against cases we wrote, as any code
// should be.
const answer = await ask(specific);
const code = answer.match(/```(?:\w+)?\n([\s\S]*?)```/)[1];
const isEgyptianMobile = Function(`${code}; return isEgyptianMobile;`)();
const cases = [
  ["01012345678", true],
  ["+20 101 234 5678", true],
  ["015-1234-5678", true],
  ["01312345678", false],
  ["0101234567", false],
  ["phone: 01012345678", false],
];
for (const [text, expected] of cases) {
  const got = isEgyptianMobile(text);
  console.log(`${got === expected ? "pass" : "FAIL"}  ${JSON.stringify(text)} -> ${got}`);
}
