// At most three requests per user per minute.
const WINDOW = 60_000;
const MAX = 3;
const seen = new Map();

export function allow(user, now = Date.now()) {
  const recent = (seen.get(user) ?? []).filter((t) => now - t < WINDOW);
  if (recent.length >= MAX) {
    seen.set(user, recent);
    return false;
  }
  seen.set(user, [...recent, now]);
  return true;
}

let clock = 0;
for (const [user, step] of [["mona", 1], ["mona", 1], ["omar", 1], ["mona", 1], ["mona", 1], ["mona", 61]]) {
  clock += step * 1000;
  console.log(`${String(clock / 1000).padStart(3)} s  ${user.padEnd(5)} ${allow(user, clock) ? "allowed" : "429 too many requests"}`);
}
