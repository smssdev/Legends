const secret = 73;
let low = 1;
let high = 100;
let tries = 0;

while (true) {
  const guess = Math.floor((low + high) / 2);
  tries++;
  if (guess === secret) {
    console.log(`المحاولة ${tries}: ${guess}. وجدته!`);
    break;
  }
  if (guess < secret) {
    console.log(`المحاولة ${tries}: ${guess}، أصغر من الرقم`);
    low = guess + 1;
  } else {
    console.log(`المحاولة ${tries}: ${guess}، أكبر من الرقم`);
    high = guess - 1;
  }
}
