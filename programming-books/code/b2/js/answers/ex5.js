function* take(iterable, n) {
  if (n <= 0) return;
  let count = 0;
  for (const value of iterable) {
    yield value;
    if (++count >= n) return;
  }
}

function* evens() {
  for (let n = 0; ; n += 2) yield n;
}

console.log([...take(evens(), 5)]);
