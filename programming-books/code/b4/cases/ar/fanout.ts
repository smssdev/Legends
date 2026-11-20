// one post, and one view of a follower's feed showing posts from 200 accounts they follow
const cases = [
  ["حساب عادي (300 متابع)", 300],
  ["حساب مشهور (2,000,000 متابع)", 2_000_000],
] as const;
const followed = 200;

console.log(
  "الإستراتيجية".padEnd(20),
  "كتابات لكل منشور".padStart(20),
  "قراءات لكل عرض للخلاصة".padStart(22),
);
for (const [account, followers] of cases) {
  console.log(account);
  console.log(
    "  التوزيع عند الكتابة".padEnd(20),
    followers.toLocaleString("en").padStart(20),
    "1".padStart(22),
  );
  console.log(
    "  التوزيع عند القراءة".padEnd(20),
    "1".padStart(20),
    String(followed).padStart(22),
  );
}
