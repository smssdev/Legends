import crypto from "node:crypto";
import fs from "node:fs";

// Every citation names a document that was given, and its numbers are in
// that document (Chapter 14).
export function citations(answer, sources) {
  const cited = [...answer.matchAll(/\[([\w-]+)\]/g)].map((m) => m[1]);
  const problems = cited
    .filter((id) => !sources.some((s) => s.id === id))
    .map((id) => `[${id}] was not given`);
  for (const id of cited) {
    const source = sources.find((s) => s.id === id);
    const numbers = answer.match(/\d+/g) ?? [];
    for (const n of numbers.filter((n) => source && !source.text.includes(n))) {
      problems.push(`${n} is not in [${id}]`);
    }
  }
  return {cited, problems};
}

// No secret leaves, whatever the documents or the model say (Chapter 15).
export function secrets(answer) {
  return /\b(sk|pk)-[A-Za-z0-9-]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(answer) ? ["a secret"] : [];
}

// One line per question: the user hashed, emails and phones masked, the
// outcome (Chapter 15).
export function audit(user, question, result) {
  const masked = question.replace(/[\w.+-]+@[\w-]+\.[\w.]+/g, "[EMAIL]").replace(/\b01\d(?:[ -]?\d){8}\b/g, "[PHONE]");
  const entry = {
    user: crypto.createHash("sha256").update(`team:${user}`).digest("hex").slice(0, 10),
    question: masked,
    sources: result.sources.map((s) => s.id),
    ok: result.ok,
  };
  fs.appendFileSync("audit.log", `${JSON.stringify(entry)}\n`);
}
