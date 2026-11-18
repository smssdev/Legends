const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function retry(fn, { retries = 3, delay = 10 } = {}) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await fn(attempt);
    } catch (error) {
      if (attempt > retries) {
        throw new Error(`استسلمت بعد ${attempt} محاولات`, { cause: error });
      }
      const pause = delay * 2 ** (attempt - 1); // انتظار متضاعف: 10 ثم 20 ثم 40 ملي ثانية…
      console.log(`  المحاولة ${attempt} فشلت، انتظار ${pause} ms`);
      await wait(pause);
    }
  }
}

// واجهة وهمية تفشل عدداً محدداً من المرات أولاً
function flaky(failures) {
  let left = failures;
  return async (attempt) => {
    if (left-- > 0) throw new Error("خطأ في الشبكة");
    return `OK (في المحاولة ${attempt})`;
  };
}

console.log("واجهة تفشل مرتين:");
console.log(await retry(flaky(2)));

console.log("واجهة تفشل خمس مرات:");
try {
  await retry(flaky(5), { retries: 2 });
} catch (error) {
  console.log(error.message, "-", error.cause.message);
}
