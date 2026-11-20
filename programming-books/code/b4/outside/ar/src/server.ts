import Fastify from "fastify";
import { acceptLogo, isType, logoUploadUrl } from "./files.ts";
import { applyEvent, startDeposit, verifySignature } from "./payments.ts";

const app = Fastify();
const problem = (status: number, title: string) => ({ status, title });

app.post<{ Params: { id: string } }>(
  "/bookings/:id/deposit",
  async (request, reply) => {
    const url = await startDeposit(Number(request.params.id));
    if (!url) return reply.code(404).send(problem(404, "غير موجود"));
    return { checkout_url: url };
  },
);

await app.register(async (hooks) => {
  // التوقيع يغطي البايتات المرسلة بالضبط: اقرأ الجسم نصاً، وحلّله بعد الفحص
  hooks.removeContentTypeParser("application/json");
  hooks.addContentTypeParser(
    "application/json",
    { parseAs: "string" },
    (_req, body, done) => done(null, body),
  );
  hooks.post("/webhooks/payments", async (request, reply) => {
    const body = request.body as string;
    const signature = String(request.headers["bit-signature"] ?? "");
    if (!verifySignature(signature, body)) {
      return reply.code(400).send(problem(400, "توقيع غير صالح"));
    }
    return { result: await applyEvent(JSON.parse(body)) };
  });
});

// in Bit Booking these two need requireUser(["owner"]) from Chapter 4; left out to keep the example short
app.post<{ Params: { id: string }; Body: { type: string; size: number } }>(
  "/businesses/:id/logo",
  async (request, reply) => {
    const { type, size } = request.body;
    if (!isType(type))
      return reply
        .code(422)
        .send(problem(422, "يجب أن يكون الشعار PNG أو JPEG أو WebP"));
    const upload = await logoUploadUrl(Number(request.params.id), type, size);
    if ("error" in upload)
      return reply.code(422).send(problem(422, "الشعار كبير جداً"));
    return upload;
  },
);

app.post<{ Params: { id: string }; Body: { key: string } }>(
  "/businesses/:id/logo/confirm",
  async (request, reply) => {
    const result = await acceptLogo(Number(request.params.id), request.body.key);
    if (result === "ok") return { logo: request.body.key };
    const [status, title] =
      result === "not-found"
        ? [404, "غير موجود"]
        : result === "too-big"
          ? [422, "الشعار كبير جداً"]
          : [422, "يجب أن يكون الشعار PNG أو JPEG أو WebP"];
    return reply.code(status).send(problem(status, title));
  },
);

await app.listen({ port: 3000 });
