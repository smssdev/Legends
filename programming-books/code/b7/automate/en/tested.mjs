let toIso;
try {
  ({toIso} = await import("./toIso.mjs"));
} catch (error) {
  console.log(`not safe: toIso.mjs does not load (${error.message})`);
  process.exit(0);
}

// The generated function is tested on rows with known answers before it
// touches the rest.
const known = [
  ["12/01/2026", "2026-01-12"],
  ["2026-1-3", "2026-01-03"],
  ["01.02.2026", "2026-02-01"],
  ["2026/02/28", "2026-02-28"],
];
let right = 0;
for (const [input, expected] of known) {
  let got;
  try {
    got = toIso(input);
  } catch (error) {
    got = error.name;
  }
  right += got === expected ? 1 : 0;
  console.log(`${got === expected ? "pass" : "FAIL"} ${input} -> ${got} (expected ${expected})`);
}
console.log(right === known.length ? "safe to run on the rest" : "not safe: fix the function first");
