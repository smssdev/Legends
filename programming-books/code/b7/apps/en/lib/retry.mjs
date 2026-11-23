// Retry what can succeed later (429, 503, network errors), with growing
// waits; never forever.
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

// Every call has a deadline.
export function deadline(ms) {
  return AbortSignal.timeout(ms);
}
