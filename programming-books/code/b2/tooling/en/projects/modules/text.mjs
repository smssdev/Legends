export function slugify(title) {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^\p{L}\p{N}]+/gu, "-")
    .replace(/^-|-$/g, "");
}

export function truncate(text, max) {
  return text.length <= max ? text : text.slice(0, max - 1).trimEnd() + "…";
}
