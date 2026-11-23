// Every "name(args) // => value" line of a text, run against a module's
// exports.
export function docExamples(text, exports) {
  const results = [];
  for (const match of text.matchAll(/(\w+\([^)]*\))\s*\/\/\s*=>\s*(.+)$/gm)) {
    const [, call, claimed] = match;
    let actual;
    try {
      actual = Function(...Object.keys(exports), `return ${call};`)(...Object.values(exports));
    } catch (error) {
      actual = error.name;
    }
    const ok = String(actual) === claimed.trim().replace(/^["']|["']$/g, "");
    results.push({call, claimed: claimed.trim(), actual, ok});
  }
  return results;
}
