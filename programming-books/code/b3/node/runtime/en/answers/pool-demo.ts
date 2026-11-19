import { Worker } from "node:worker_threads";
import { WorkerPool } from "./pool.ts";

const jobs = 100;
const limit = 20_000;

let start = performance.now();
for (let i = 0; i < jobs; i++) {
  await new Promise((resolve) => {
    const worker = new Worker(new URL("../src/primes-worker.ts", import.meta.url), {
      workerData: limit,
    });
    worker.once("message", resolve);
  });
}
console.log(`a new thread per job: ${Math.round(performance.now() - start)} ms`);

const pool = new WorkerPool(new URL("./pool-worker.ts", import.meta.url), 4);
start = performance.now();
for (let i = 0; i < jobs; i++) await pool.run(limit);
console.log(`a pool of 4 threads:  ${Math.round(performance.now() - start)} ms`);
await pool.close();
