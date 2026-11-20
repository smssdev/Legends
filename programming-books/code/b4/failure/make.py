"""Writes the examples of Book 4, chapter "Designing for Failure", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4)

provider.ts plays Bit Booking's payment provider on a bad day: in "flaky" mode every 4th request fails
and every 10th takes 3 seconds; in "down" mode every request fails. It counts the requests it receives.
caller.ts makes 40 deposit calls, 4 at a time, with one strategy at a time from resilience.ts: none,
a timeout, retries with backoff and jitter, and a circuit breaker with a fallback. Each run prints what the
customers got and how many requests the provider had to absorb. Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_mode="flaky: every 4th request fails, every 10th takes 3 s; down: every request fails",
        w_c_timeout="give up after a deadline: a slow answer is a failure, not a wait",
        w_c_retry="retry only what may succeed next time, and wait longer each time",
        w_c_jitter="full jitter: a random wait, so clients that failed together do not retry together",
        w_c_breaker="after enough failures, stop calling for a while; then let one call test the water",
        w_c_open="open: fail at once, without touching the provider",
        w_c_half="half-open: one trial call decides whether to close again",
        w_c_fallback="what the customer gets when the provider cannot be reached",
        w_c_pool="4 calls at a time, 40 in all, like 4 busy customers",
        w_t_strategy="strategy", w_t_ok="ok", w_t_failed="failed", w_t_slowest="slowest",
        w_t_total="total", w_t_load="provider saw",
        w_fallback="Deposits are unavailable right now; your time is held for 30 minutes.",
        w_s_flaky="The provider has a bad day", w_s_down="The provider is down",
        w_s_fallback="What a customer sees while the breaker is open",
    ),
    "ar": dict(
        w_c_mode="flaky: كل رابع طلب يفشل، وكل عاشر يستغرق 3 ثوانٍ؛ down: كل طلب يفشل",
        w_c_timeout="استسلم بعد مهلة: الإجابة البطيئة فشل، لا انتظار",
        w_c_retry="أعد فقط ما قد ينجح في المرة التالية، وانتظر أطول في كل مرة",
        w_c_jitter="تشويش كامل: انتظار عشوائي، كي لا يعيد معاً العملاءُ الذين فشلوا معاً",
        w_c_breaker="بعد فشل كافٍ، توقف عن النداء فترة؛ ثم دع نداءً واحداً يجس النبض",
        w_c_open="مفتوح: افشل فوراً، دون أن تلمس المزوّد",
        w_c_half="نصف مفتوح: نداء تجريبي واحد يقرر هل يُغلق من جديد",
        w_c_fallback="ما يحصل عليه الزبون حين لا يمكن الوصول إلى المزوّد",
        w_c_pool="4 نداءات في كل مرة، 40 في المجموع، كأربعة زبائن مشغولين",
        w_t_strategy="الإستراتيجية", w_t_ok="نجح", w_t_failed="فشل", w_t_slowest="الأبطأ",
        w_t_total="المجموع", w_t_load="رأى المزوّد",
        w_fallback="العربون غير متاح الآن؛ موعدك محجوز 30 دقيقة.",
        w_s_flaky="المزوّد في يوم سيئ", w_s_down="المزوّد معطل",
        w_s_fallback="ما يراه الزبون والقاطع مفتوح",
    ),
}

FILES = {
    "provider.ts": '''import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";

// {w_c_mode}
let mode = process.env.MODE ?? "flaky";
let seen = 0;

createServer(async (request, response) => {
  if (request.url === "/stats") return response.end(JSON.stringify({ seen }));
  if (request.url?.startsWith("/mode/")) {
    mode = request.url.slice(6);
    seen = 0;
    return response.end(mode);
  }
  const n = ++seen;
  if (mode === "down") {
    await sleep(20);
    return response.writeHead(503).end("down");
  }
  if (n % 10 === 0) await sleep(3000);
  if (n % 4 === 0) return response.writeHead(500).end("error");
  response.end(JSON.stringify({ checkout: `cs_${n}` }));
}).listen(4000);
''',
    "resilience.ts": '''import { setTimeout as sleep } from "node:timers/promises";

// {w_c_fallback}
export const fallback = { error: "{w_fallback}" };

export class HttpError extends Error {
  status: number;
  constructor(status: number) {
    super(`HTTP ${status}`);
    this.status = status;
  }
}

// {w_c_timeout}
export async function call(url: string, timeoutMs?: number) {
  const signal = timeoutMs ? AbortSignal.timeout(timeoutMs) : undefined;
  const response = await fetch(url, { method: "POST", signal });
  if (!response.ok) throw new HttpError(response.status);
  return response.json();
}

const retryable = (error: unknown) =>
  !(error instanceof HttpError) || error.status >= 500 || error.status === 429;

// {w_c_retry}
export async function retry<T>(work: () => Promise<T>, attempts = 3, baseMs = 100): Promise<T> {
  for (let attempt = 1; ; attempt++) {
    try {
      return await work();
    } catch (error) {
      if (attempt === attempts || !retryable(error)) throw error;
      // {w_c_jitter}
      await sleep(Math.random() * baseMs * 2 ** attempt);
    }
  }
}

// {w_c_breaker}
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
      // {w_c_open}
      if (Date.now() - this.openedAt < this.cooldownMs) throw new Error("circuit open");
      // {w_c_half}
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
''',
    "caller.ts": '''import { CircuitBreaker, call, retry } from "./resilience.ts";

const URL = "http://localhost:4000/checkouts";
const strategy = process.argv[2] ?? "none";
const breaker = new CircuitBreaker();

const attempt: Record<string, () => Promise<unknown>> = {
  none: () => call(URL),
  timeout: () => call(URL, 500),
  retry: () => retry(() => call(URL, 500)),
  breaker: () => breaker.run(() => retry(() => call(URL, 500))),
};

let ok = 0;
let failed = 0;
let slowest = 0;
const started = performance.now();
// {w_c_pool}
const queue = Array.from({ length: 40 }, (_, i) => i);
await Promise.all(
  Array.from({ length: 4 }, async () => {
    while (queue.shift() !== undefined) {
      const start = performance.now();
      try {
        await attempt[strategy]!();
        ok++;
      } catch {
        failed++;
      }
      slowest = Math.max(slowest, performance.now() - start);
    }
  }),
);
const { seen } = await (await fetch("http://localhost:4000/stats")).json();
const ms = (n: number) => `${Math.round(n)} ms`;
console.log(
  strategy.padEnd(9), String(ok).padStart(3), String(failed).padStart(7),
  ms(slowest).padStart(9), ms(performance.now() - started).padStart(9), String(seen).padStart(12),
);
''',
    "header.ts": '''console.log(
  "{w_t_strategy}".padEnd(9), "{w_t_ok}".padStart(3), "{w_t_failed}".padStart(7),
  "{w_t_slowest}".padStart(9), "{w_t_total}".padStart(9), "{w_t_load}".padStart(12),
);
''',
    "customer.ts": '''import { CircuitBreaker, call, fallback } from "./resilience.ts";

const breaker = new CircuitBreaker(2, 60_000);
for (let i = 1; i <= 4; i++) {
  const answer = await breaker
    .run(() => call("http://localhost:4000/checkouts", 500))
    .catch((error: Error) => ({ ...fallback, cause: error.message }));
  console.log(i, JSON.stringify(answer));
}
''',
}


def record(folder, t):
    s = Session(folder)
    with Server("node provider.ts", folder, "http://localhost:4000/stats"):
        s.note(t["w_s_flaky"])
        s.run("node header.ts")
        s.lines.pop(-2)
        for strategy in ("none", "timeout", "retry"):
            s.run("curl -s localhost:4000/mode/flaky > /dev/null")
            s.lines.pop()
            s.run(f"node caller.ts {strategy}", timeout=120)
        s.save(folder / "flaky.sh")
        s.note(t["w_s_down"])
        s.run("node header.ts")
        s.lines.pop(-2)
        for strategy in ("none", "retry", "breaker"):
            s.run("curl -s localhost:4000/mode/down > /dev/null")
            s.lines.pop()
            s.run(f"node caller.ts {strategy}", timeout=120)
        s.save(folder / "down.sh")
        s.note(t["w_s_fallback"])
        s.run("curl -s localhost:4000/mode/down > /dev/null")
        s.lines.pop()
        s.run("node customer.ts | sed -n '1,4p'")
        s.save(folder / "fallback.sh")


_orig = Session.run


def run(self, cmd, shown=None, check=True, timeout=60):
    r = subprocess.run(["bash", "-c", cmd], cwd=self.cwd, capture_output=True, text=True, timeout=timeout,
                       env=CLEAN)
    out = (r.stdout + r.stderr).replace("\r", "").rstrip("\n")
    if check and r.returncode:
        raise RuntimeError(f"{cmd} failed ({r.returncode}):\n{out}")
    self.lines.append("$ " + (shown or cmd))
    if out:
        self.lines.extend(out.split("\n"))
    return out


Session.run = run

for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    (folder / "package.json").write_text('{\n  "private": true,\n  "type": "module"\n}\n')
    os.symlink(B4 / "node_modules", folder / "node_modules")
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "."],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
