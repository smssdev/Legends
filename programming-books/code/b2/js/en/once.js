function once(fn) {
  let done = false;
  let result;
  return (...args) => {
    if (!done) {
      done = true;
      result = fn(...args);
    }
    return result;
  };
}

const connect = once(() => {
  console.log("Connecting to the server…");
  return "connection #1";
});

console.log(connect());
console.log(connect());
