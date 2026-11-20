import { setTimeout as sleep } from "node:timers/promises";

// ما يحصل عليه الزبون حين لا يمكن الوصول إلى المزوّد
export const fallback = { error: "العربون غير متاح الآن؛ موعدك محجوز 30 دقيقة." };

export class HttpError extends Error {
  status: number;
  constructor(status: number) {
    super(`HTTP ${status}`);
    this.status = status;
  }
}

// استسلم بعد مهلة: الإجابة البطيئة فشل، لا انتظار
export async function call(url: string, timeoutMs?: number) {
  const signal = timeoutMs ? AbortSignal.timeout(timeoutMs) : undefined;
  const response = await fetch(url, { method: "POST", signal });
  if (!response.ok) throw new HttpError(response.status);
  return response.json();
}

const retryable = (error: unknown) =>
  !(error instanceof HttpError) || error.status >= 500 || error.status === 429;

// أعد فقط ما قد ينجح في المرة التالية، وانتظر أطول في كل مرة
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
      // تشويش كامل: انتظار عشوائي، كي لا يعيد معاً العملاءُ الذين فشلوا معاً
      await sleep(Math.random() * baseMs * 2 ** attempt);
    }
  }
}

// بعد فشل كافٍ، توقف عن النداء فترة؛ ثم دع نداءً واحداً يجس النبض
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
      // مفتوح: افشل فوراً، دون أن تلمس المزوّد
      if (Date.now() - this.openedAt < this.cooldownMs)
        throw new Error("circuit open");
      // نصف مفتوح: نداء تجريبي واحد يقرر هل يُغلق من جديد
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
