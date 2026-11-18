const scores = [72, 85, -1, 90, 64];

for (const score of scores) {
  if (score < 0) {
    console.log("Invalid score, stopping.");
    break;
  }
  if (score < 75) {
    continue;
  }
  console.log(`Great score: ${score}`);
}
