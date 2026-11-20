import { Queue } from "bullmq";
import { Redis } from "ioredis";

// إعداد اتصال واحد للطابور والعامل
export const connection = new Redis("redis://localhost:6379", {
  maxRetriesPerRequest: null,
});

export type Confirmation = { orderId: number; email: string };

export const mail = new Queue<Confirmation>("mail", {
  connection,
  // ما تأخذه كل مهمة تأكيد ما لم تقل غير ذلك
  defaultJobOptions: {
    // حتى 3 محاولات، بانتظار ثانية ثم ثانيتين بينها
    attempts: 3,
    backoff: { type: "exponential", delay: 1000 },
    // المهام المنتهية تُحفظ ساعة (للاطلاع عليها)، والفاشلة أسبوعاً
    removeOnComplete: { age: 3600 },
    removeOnFail: { age: 7 * 24 * 3600 },
  },
});

export function queueConfirmation(orderId: number, email: string) {
  // رقم المهمة هو رقم الطلب: وضع الطلب نفسه في الطابور مرتين يُبقي مهمة واحدة
  return mail.add(
    "confirmation",
    { orderId, email },
    { jobId: `order-${orderId}` },
  );
}
