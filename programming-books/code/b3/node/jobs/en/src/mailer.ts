import { UnrecoverableError } from "bullmq";

const attempts = new Map<number, number>();

// A stand-in for a real mail service, with its bad days.
export async function sendMail(orderId: number, email: string) {
  await new Promise((resolve) => setTimeout(resolve, 300));
  const n = (attempts.get(orderId) ?? 0) + 1;
  attempts.set(orderId, n);
  // a mail service that fails the first two times for order 1003
  if (orderId === 1003 && n <= 2) throw new Error("mail service unavailable");
  // an address that can never work: no point trying forever
  if (!email.includes("@"))
    throw new UnrecoverableError(`invalid address: ${email}`);
}
