const secret = 73;
let low = 1;
let high = 100;
let tries = 0;

while (true) {
  const guess = Math.floor((low + high) / 2);
  tries++;
  if (guess === secret) {
    console.log(`Guess ${tries}: ${guess}. Got it!`);
    break;
  }
  if (guess < secret) {
    console.log(`Guess ${tries}: ${guess}, too low`);
    low = guess + 1;
  } else {
    console.log(`Guess ${tries}: ${guess}, too high`);
    high = guess - 1;
  }
}
