import { Queue } from "bullmq";
import { Redis } from "ioredis";

// one connection setting for the queue and the worker
export const connection = new Redis("redis://localhost:6379", {
  maxRetriesPerRequest: null,
});

export type Confirmation = { orderId: number; email: string };

export const mail = new Queue<Confirmation>("mail", {
  connection,
  // what every confirmation job gets unless it says otherwise
  defaultJobOptions: {
    // up to 3 attempts, waiting 1, then 2 seconds between them
    attempts: 3,
    backoff: { type: "exponential", delay: 1000 },
    // finished jobs are kept for an hour (to look at), failed ones for a week
    removeOnComplete: { age: 3600 },
    removeOnFail: { age: 7 * 24 * 3600 },
  },
});

export function queueConfirmation(orderId: number, email: string) {
  // the job id is the order id: queuing the same order twice keeps one job
  return mail.add(
    "confirmation",
    { orderId, email },
    { jobId: `order-${orderId}` },
  );
}
