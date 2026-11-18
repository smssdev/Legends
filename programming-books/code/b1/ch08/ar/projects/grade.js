const score = 83;
let grade;

if (score < 0 || score > 100) {
  grade = "درجة غير صحيحة";
} else if (score >= 90) {
  grade = "A";
} else if (score >= 80) {
  grade = "B";
} else if (score >= 70) {
  grade = "C";
} else if (score >= 50) {
  grade = "D";
} else {
  grade = "F";
}

const passed = score >= 50 && score <= 100;
console.log(`الدرجة ${score}: التقدير ${grade}`);
console.log(passed ? "ناجح. أحسنت!" : "لم تنجح. حاول مرة أخرى!");
