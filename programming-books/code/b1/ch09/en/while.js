let savings = 0;
let week = 0;
const goal = 100;

while (savings < goal) {
  week++;
  savings = savings + 15;
}

console.log(`Reached ${savings} after ${week} weeks`);
