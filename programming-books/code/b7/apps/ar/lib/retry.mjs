// أعد محاولة ما قد ينجح لاحقاً (429 و503 وأخطاء الشبكة)، بانتظار يكبر؛
// ولا إلى الأبد.
export async function withRetry(call, {tries = 4, firstWait = 200, log = () => {}} = {}) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await call();
    } catch (error) {
      const temporary = [429, 500, 502, 503].includes(error.status) || error.code === "ECONNRESET";
      if (!temporary || attempt === tries) {
        throw error;
      }
      const wait = firstWait * 2 ** (attempt - 1);
      log(`attempt ${attempt}: ${error.message}, waiting ${wait} ms`);
      await new Promise((resolve) => setTimeout(resolve, wait));
    }
  }
}

// لكل استدعاء موعد نهائي.
export function deadline(ms) {
  return AbortSignal.timeout(ms);
}
