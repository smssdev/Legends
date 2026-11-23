// The numbers in a text (dates, prices, counts), as strings.
export function numbers(text) {
  return new Set(text.match(/\d+(?:[.,]\d+)?/g) ?? []);
}

// Numbers in a draft that are not in its sources: invented, or changed.
export function newNumbers(draft, ...sources) {
  const known = new Set(sources.flatMap((source) => [...numbers(source)]));
  return [...numbers(draft)].filter((n) => !known.has(n));
}
