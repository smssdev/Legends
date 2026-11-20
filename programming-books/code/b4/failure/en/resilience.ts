import { setTimeout as sleep } from "node:timers/promises";

// what the customer gets when the provider cannot be reached
export const fallback = {
  error: "Deposits are unavailable right now; your time is held for 30 minutes.",
};

export class HttpError extends Error {
  status: number;
  constructor(status: number) {
    super(`HTTP ${status}`);
    this.status = status;
  }
}

// give up after a deadline: a slow answer is a failure, not a wait
export async function call(url: string, timeoutMs?: number) {
  const signal = timeoutMs ? AbortSignal.timeout(timeoutMs) : undefined;
  const response = await fetch(url, { method: "POST", signal });
  if (!response.ok) throw new HttpError(response.status);
  return response.json();
}

const retryable = (error: unknown) =>
  !(error instanceof HttpError) || error.status >= 500 || error.status === 429;

// retry only what may succeed next time, and wait longer each time
export async function retry<T>(
  work: () => Promise<T>,
  attempts = 3,
  baseMs = 100,
): Promise<T> {
  for (let attempt = 1; ; attempt++) {
    try {
      return await work();
    } catch (error) {
      if (attempt === attempts || !retryable(error)) throw error;
      // full jitter: a random wait, so clients that failed together do not retry together
      await sleep(Math.random() * baseMs * 2 ** attempt);
    }
  }
}

// after enough failures, stop calling for a while; then let one call test the water
export class CircuitBreaker {
  private failures = 0;
  private openedAt = 0;
  private state: "closed" | "open" | "half-open" = "closed";
  private threshold: number;
  private cooldownMs: number;

  constructor(threshold = 5, cooldownMs = 2000) {
    this.threshold = threshold;
    this.cooldownMs = cooldownMs;
  }

  async run<T>(work: () => Promise<T>): Promise<T> {
    if (this.state === "open") {
      // open: fail at once, without touching the provider
      if (Date.now() - this.openedAt < this.cooldownMs)
        throw new Error("circuit open");
      // half-open: one trial call decides whether to close again
      this.state = "half-open";
    }
    try {
      const result = await work();
      this.failures = 0;
      this.state = "closed";
      return result;
    } catch (error) {
      this.failures++;
      if (this.state === "half-open" || this.failures >= this.threshold) {
        this.state = "open";
        this.openedAt = Date.now();
      }
      throw error;
    }
  }
}
