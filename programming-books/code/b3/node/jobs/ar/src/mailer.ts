import { UnrecoverableError } from "bullmq";

const attempts = new Map<number, number>();

// A stand-in for a real mail service, with its bad days.
export async function sendMail(orderId: number, email: string) {
  await new Promise((resolve) => setTimeout(resolve, 300));
  const n = (attempts.get(orderId) ?? 0) + 1;
  attempts.set(orderId, n);
  // خدمة بريد تفشل أول مرتين للطلب 1003
  if (orderId === 1003 && n <= 2) throw new Error("خدمة البريد غير متاحة");
  // عنوان لا يمكن أن ينجح أبداً: لا فائدة من المحاولة إلى الأبد
  if (!email.includes("@"))
    throw new UnrecoverableError(`عنوان غير صالح: ${email}`);
}
