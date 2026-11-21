// a booking from start to end, in minutes since the salon opened
export type Booking = { start: number; end: number };

// first version: check every minute against every booking
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

// better: sort once, walk once, and remember where the last booking ended
export function gaps(bookings: Booking[], open: number, close: number) {
  const sorted = [...bookings].sort((a, b) => a.start - b.start);
  const result: Booking[] = [];
  let free = open;
  for (const b of sorted) {
    if (b.start > free)
      result.push({ start: free, end: Math.min(b.start, close) });
    // overlapping bookings merge: the gap starts after the latest end
    free = Math.max(free, b.end);
  }
  if (free < close) result.push({ start: free, end: close });
  return result;
}
