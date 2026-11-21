// حجز من بدايته إلى نهايته، بالدقائق منذ فتح الصالون
export type Booking = { start: number; end: number };

// النسخة الأولى: افحص كل دقيقة أمام كل حجز
export function gapsNaive(
  bookings: Booking[],
  open: number,
  close: number,
) {
  const gaps: Booking[] = [];
  for (let minute = open; minute < close; minute++) {
    const busy = bookings.some((b) => b.start <= minute && minute < b.end);
    const last = gaps.at(-1);
    if (busy) continue;
    if (last && last.end === minute) last.end++;
    else gaps.push({ start: minute, end: minute + 1 });
  }
  return gaps;
}

// أفضل: رتّب مرة، وامشِ مرة، وتذكّر أين انتهى آخر حجز
export function gaps(bookings: Booking[], open: number, close: number) {
  const sorted = [...bookings].sort((a, b) => a.start - b.start);
  const result: Booking[] = [];
  let free = open;
  for (const b of sorted) {
    if (b.start > free)
      result.push({ start: free, end: Math.min(b.start, close) });
    // الحجوزات المتداخلة تندمج: تبدأ الفجوة بعد أبعد نهاية
    free = Math.max(free, b.end);
  }
  if (free < close) result.push({ start: free, end: close });
  return result;
}
