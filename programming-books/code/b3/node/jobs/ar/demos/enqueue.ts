import { connection, mail, queueConfirmation } from "../src/queue.ts";

const orders = [
  [1001, "sara@example.com"],
  [1002, "omar@example.com"],
  [1003, "lina@example.com"],
  [1004, "karim-at-example.com"],
] as const;

for (const [orderId, email] of orders) {
  const start = performance.now();
  const job = await queueConfirmation(orderId, email);
  const ms = (performance.now() - start).toFixed(1);
  console.log(`المهمة ${job.id} في الطابور خلال ${ms} ms`);
}
const again = await queueConfirmation(1001, "sara@example.com");
console.log(
  `المهمة ${again.id} في الطابور مرة أخرى؛ المهام المنتظرة: ${await mail.count()}`,
);
await mail.close();
await connection.quit();
