function memoize(fn) {
  const cache = new Map();
  return (arg) => {
    if (cache.has(arg)) return cache.get(arg);
    const result = fn(arg);
    cache.set(arg, result);
    return result;
  };
}

let calls = 0;
function slowSquare(n) {
  calls++;
  return n * n;
}

const fastSquare = memoize(slowSquare);
console.log(fastSquare(9), fastSquare(9), fastSquare(12), fastSquare(9));
console.log("Real calls:", calls);

// Without the cache, fib(70) would need trillions of calls
const fib = memoize((n) => (n < 2 ? n : fib(n - 1) + fib(n - 2)));
console.log("fib(70) =", fib(70));
