// يعدّ الأعداد الأولية حتى limit بالطريقة البطيئة: عمل معالج خالص.
export function countPrimes(limit: number): number {
  let count = 0;
  for (let n = 2; n <= limit; n++) {
    let prime = true;
    for (let d = 2; d * d <= n; d++) {
      if (n % d === 0) {
        prime = false;
        break;
      }
    }
    if (prime) count++;
  }
  return count;
}
