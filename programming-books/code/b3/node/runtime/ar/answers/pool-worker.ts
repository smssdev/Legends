import { parentPort } from "node:worker_threads";
import { countPrimes } from "../src/primes.ts";

parentPort?.on("message", (limit: number) => {
  parentPort?.postMessage(countPrimes(limit));
});
