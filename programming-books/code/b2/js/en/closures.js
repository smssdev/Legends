function makeCounter(start = 0) {
  let count = start; // private: only the three functions can see it
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
console.log(likes.count); // undefined: there is no way in from outside
