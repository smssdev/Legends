// one post, and one view of a follower's feed showing posts from 200 accounts they follow
const cases = [
  ["ordinary account (300 followers)", 300],
  ["popular account (2,000,000 followers)", 2_000_000],
] as const;
const followed = 200;

console.log(
  "strategy".padEnd(20),
  "writes per post".padStart(20),
  "reads per feed view".padStart(22),
);
for (const [account, followers] of cases) {
  console.log(account);
  console.log(
    "  fan-out on write".padEnd(20),
    followers.toLocaleString("en").padStart(20),
    "1".padStart(22),
  );
  console.log(
    "  fan-out on read".padEnd(20),
    "1".padStart(20),
    String(followed).padStart(22),
  );
}
