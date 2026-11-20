// a basket left alone for 30 minutes is released
export const EXPIRES_AFTER = 30 * 60 * 1000;

export function isExpired(lastTouched: number, now = Date.now()) {
  return now - lastTouched >= EXPIRES_AFTER;
}
