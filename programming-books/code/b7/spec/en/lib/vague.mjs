// Words that sound like requirements and cannot be tested.
export const VAGUE = [
  "fast", "quick", "easy", "simple", "intuitive", "user-friendly", "seamless", "appropriate",
  "properly", "correctly", "efficient", "robust", "flexible", "secure", "etc", "as needed",
  "and so on", "should be able to", "if possible", "some", "various",
  "سريع", "سهل", "بسيط", "مناسب", "بشكل صحيح", "بكفاءة", "مرن", "آمن", "إلخ", "وغيرها", "قدر الإمكان",
];

export function vagueWords(text) {
  const found = new Map();
  for (const word of VAGUE) {
    // \b only knows Latin letters, so Arabic words are counted as plain
    // text.
    const hits = /^[a-z]/i.test(word)
      ? text.match(new RegExp(`\\b${word}\\b`, "gi"))?.length ?? 0
      : text.split(word).length - 1;
    if (hits) {
      found.set(word, hits);
    }
  }
  return found;
}

// The acceptance criteria: paragraphs that start with Given, read as one
// line,
// and whether they have a Given, a When and a Then, in that order.
export function criteria(text) {
  const blocks = text.split(/\n\s*\n|\n(?=\s*[-*\d.]*\s*\**Given\b)/i);
  return blocks
    .map((block) => block.replace(/\s*\n\s*/g, " ").replace(/^[\s*>\-\d.]+/, "").trim())
    .filter((line) => /^\**Given\b/i.test(line))
    .map((line) => ({line, ok: /\bGiven\b.*\bWhen\b.*\bThen\b/i.test(line)}));
}
