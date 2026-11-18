// Used inside the folder only: index.mjs does not export it
export function countWords(text) {
  return text.split(/\s+/).filter(Boolean).length;
}
