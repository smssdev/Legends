// السلة المتروكة 30 دقيقة تُحرَّر
export const EXPIRES_AFTER = 30 * 60 * 1000;

export function isExpired(lastTouched: number, now = Date.now()) {
  return now - lastTouched >= EXPIRES_AFTER;
}
