import { createHmac, randomBytes } from "node:crypto";
import Fastify from "fastify";

// بديل لمزوّد دفع: جلسات دفع وwebhooks موقَّعة
const app = Fastify();
const checkouts = new Map<
  string,
  { amount: number; reference: string; event?: string }
>();
const id = (prefix: string) => `${prefix}_${randomBytes(6).toString("hex")}`;

app.post<{ Body: { amount: number; reference: string } }>(
  "/checkouts",
  async (request, reply) => {
    if (request.headers.authorization !== `Bearer ${process.env.PROVIDER_KEY}`) {
      return reply.code(401).send({ error: "invalid api key" });
    }
    const checkout = id("cs");
    checkouts.set(checkout, request.body);
    return { id: checkout, url: `http://localhost:4000/pay/${checkout}` };
  },
);

// ينادي المزوّد الـ webhook الخاص بالمتجر، موقَّعاً بالسر المشترك
async function deliver(body: string) {
  const t = Math.floor(Date.now() / 1000);
  const v1 = createHmac("sha256", process.env.WEBHOOK_SECRET!)
    .update(`${t}.${body}`)
    .digest("hex");
  const res = await fetch("http://localhost:3000/webhooks/payments", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "bit-signature": `t=${t},v1=${v1}`,
    },
    body,
  });
  return { status: res.status, answer: await res.json() };
}

app.post<{ Params: { checkout: string } }>("/pay/:checkout", async (request) => {
  const checkout = checkouts.get(request.params.checkout)!;
  checkout.event = JSON.stringify({
    id: id("evt"),
    type: "checkout.paid",
    data: { checkout_id: request.params.checkout },
  });
  return deliver(checkout.event);
});

app.post<{ Params: { checkout: string } }>(
  "/pay/:checkout/redeliver",
  async (request) => deliver(checkouts.get(request.params.checkout)!.event!),
);

await app.listen({ port: 4000 });
