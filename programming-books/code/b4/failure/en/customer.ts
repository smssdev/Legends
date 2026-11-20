import { CircuitBreaker, call, fallback } from "./resilience.ts";

const breaker = new CircuitBreaker(2, 60_000);
for (let i = 1; i <= 4; i++) {
  const answer = await breaker
    .run(() => call("http://localhost:4000/checkouts", 500))
    .catch((error: Error) => ({ ...fallback, cause: error.message }));
  console.log(i, JSON.stringify(answer));
}
