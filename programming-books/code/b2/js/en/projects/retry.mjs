const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function retry(fn, { retries = 3, delay = 10 } = {}) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await fn(attempt);
    } catch (error) {
      if (attempt > retries) {
        throw new Error(`Gave up after ${attempt} attempts`, { cause: error });
      }
      const pause = delay * 2 ** (attempt - 1); // exponential backoff: 10, 20, 40 ms…
      console.log(`  attempt ${attempt} failed, waiting ${pause} ms`);
      await wait(pause);
    }
  }
}

// A fake API that fails a fixed number of times first
function flaky(failures) {
  let left = failures;
  return async (attempt) => {
    if (left-- > 0) throw new Error("Network error");
    return `OK (on attempt ${attempt})`;
  };
}

console.log("API that fails twice:");
console.log(await retry(flaky(2)));

console.log("API that fails five times:");
try {
  await retry(flaky(5), { retries: 2 });
} catch (error) {
  console.log(error.message, "-", error.cause.message);
}
