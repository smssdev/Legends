// The average of 10, 20 and 30 should be 20…
function average(numbers) {
  let total = 0;
  for (let i = 1; i < numbers.length; i++) {
    total = total + numbers[i];
  }
  return total / numbers.length;
}

console.log(average([10, 20, 30]));
