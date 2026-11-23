// البيانات الشخصية تُستبدل بعلامات قبل أن يغادر النص الجهاز.
const PATTERNS = [
  ["EMAIL", /[\w.+-]+@[\w-]+\.[\w.]+/g],
  ["CARD", /\b(?:\d{4}[ -]?){3}\d{4}\b/g],
  // An Egyptian mobile: 01 and nine more digits, spaces or dashes
  // allowed.
  ["PHONE", /\b01\d(?:[ -]?\d){8}\b/g],
];

export function redact(text) {
  const found = new Map();
  let safe = text;
  for (const [kind, pattern] of PATTERNS) {
    safe = safe.replace(pattern, (value) => {
      const key = `[${kind}_${found.size + 1}]`;
      found.set(key, value);
      return key;
    });
  }
  return {safe, found};
}

// الجواب يعود بالعلامات؛ والقيم الحقيقية تُعاد هنا فقط.
export function restore(text, found) {
  return [...found].reduce((result, [key, value]) => result.replaceAll(key, value), text);
}
