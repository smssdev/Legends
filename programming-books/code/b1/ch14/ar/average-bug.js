// متوسط 10 و20 و30 يجب أن يكون 20…
function average(numbers) {
  let total = 0;
  for (let i = 1; i < numbers.length; i++) {
    total = total + numbers[i];
  }
  return total / numbers.length;
}

console.log(average([10, 20, 30]));
