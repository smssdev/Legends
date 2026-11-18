const scores = [72, 85, -1, 90, 64];

for (const score of scores) {
  if (score < 0) {
    console.log("درجة غير صحيحة، توقفنا.");
    break;
  }
  if (score < 75) {
    continue;
  }
  console.log(`درجة ممتازة: ${score}`);
}
