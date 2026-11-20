import { Worker } from "node:worker_threads";

type Job = { data: unknown; resolve: (value: unknown) => void; reject: (error: unknown) => void };

// A fixed number of workers, started once and reused; jobs wait in a queue.
export class WorkerPool {
  #file: URL;
  #idle: Worker[] = [];
  #queue: Job[] = [];

  constructor(file: URL, size: number) {
    this.#file = file;
    for (let i = 0; i < size; i++) this.#idle.push(new Worker(file));
  }

  run(data: unknown): Promise<unknown> {
    return new Promise((resolve, reject) => {
      this.#queue.push({ data, resolve, reject });
      this.#next();
    });
  }

  #next(): void {
    if (!this.#idle.length || !this.#queue.length) return;
    const worker = this.#idle.pop() as Worker;
    const job = this.#queue.shift() as Job;
    const onMessage = (value: unknown) => {
      worker.off("error", onError);
      this.#idle.push(worker);
      job.resolve(value);
      this.#next();
    };
    const onError = (error: unknown) => {
      worker.off("message", onMessage);
      this.#idle.push(new Worker(this.#file)); // a crashed worker is gone: start a fresh one
      job.reject(error);
      this.#next();
    };
    worker.once("message", onMessage);
    worker.once("error", onError);
    worker.postMessage(job.data);
  }

  async close(): Promise<void> {
    await Promise.all(this.#idle.map((worker) => worker.terminate()));
  }
}
