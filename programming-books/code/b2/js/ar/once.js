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
  console.log("جارٍ الاتصال بالخادم…");
  return "connection #1";
});

console.log(connect());
console.log(connect());
