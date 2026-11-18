function makeCounter(start = 0) {
  let count = start; // خاص: لا تراه إلا الدوال الثلاث
  return {
    up: () => ++count,
    down: () => --count,
    value: () => count,
  };
}

const likes = makeCounter();
const stock = makeCounter(10);
likes.up();
likes.up();
stock.down();
console.log(likes.value(), stock.value());
console.log(likes.count); // undefined: لا طريق إليه من الخارج
