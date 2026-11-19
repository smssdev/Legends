// Runs in its own thread, so a long count never blocks the event loop.
import { parentPort, workerData } from "node:worker_threads";
import { countPrimes } from "./primes.ts";

parentPort?.postMessage(countPrimes(workerData as number));
