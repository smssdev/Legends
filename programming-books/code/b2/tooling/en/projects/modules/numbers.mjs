export function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

export function percent(part, whole) {
  return whole === 0 ? 0 : Math.round((part / whole) * 100);
}
