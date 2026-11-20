import Fastify from "fastify";
import websocket from "@fastify/websocket";
import { createClient } from "redis";
import { z } from "zod";

const Watch = z.strictObject({ watch: z.number().int() });
const parse = (text: string): unknown => {
  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
};

export async function buildApp(name: string) {
  const app = Fastify();
  await app.register(websocket);
  // اتصال واحد للنشر؛ ولكل مشترك اتصاله، لأن الاتصال المشترك لا يستطيع فعل أي شيء آخر
  const redis = await createClient({ url: "redis://localhost:6379" }).connect();
  const subscriber = () => redis.duplicate().connect();
  app.addHook("onClose", () => redis.close());

  app.post<{ Params: { id: string }; Body: { status: string } }>(
    "/orders/:id/status",
    async (request, reply) => {
      const id = Number(request.params.id);
      // هنا تُحدَّث قاعدة البيانات؛ ثم يسمع كل من يتابع، على أي خادم
      const event = { order: id, status: request.body.status, by: name };
      await redis.publish(`order:${id}`, JSON.stringify(event));
      return reply.code(204).send();
    },
  );

  // أحداث الخادم المرسلة: استجابة HTTP لا تنتهي، حدثاً بعد حدث
  app.get<{ Params: { id: string } }>(
    "/orders/:id/events",
    async (request, reply) => {
      // يجب ألا يرسل Fastify رداً من عنده: هذا المسار يكتب إلى المقبس مباشرة
      reply.hijack();
      reply.raw.writeHead(200, {
        "content-type": "text/event-stream",
        "cache-control": "no-cache",
      });
      reply.raw.write(`: متصل بـ ${name}\n\n`);
      const sub = await subscriber();
      let n = 0;
      await sub.subscribe(`order:${request.params.id}`, (message) => {
        reply.raw.write(`id: ${++n}\nevent: status\ndata: ${message}\n\n`);
      });
      // تعليق كل 15 ثانية يمنع الوسطاء من إغلاق اتصال هادئ
      const ping = setInterval(() => reply.raw.write(": ping\n\n"), 15_000);
      // حين يغادر المتصفح، توقف عن الاستماع
      request.raw.on("close", () => {
        clearInterval(ping);
        void sub.close();
      });
    },
  );

  // WebSocket: اتصال في الاتجاهين؛ والعميل يقول ما يريد متابعته
  app.get("/live", { websocket: true }, async (socket) => {
    const sub = await subscriber();
    socket.on("message", async (raw) => {
      // لا تثق بأي رسالة: ما ليس طلب متابعة يُرفض
      const parsed = Watch.safeParse(parse(String(raw)));
      if (!parsed.success) return socket.close(1008, "bad message");
      const { watch } = parsed.data;
      await sub.subscribe(`order:${watch}`, (message) => socket.send(message));
      socket.send(JSON.stringify({ watching: watch, server: name }));
    });
    socket.on("close", () => void sub.close());
  });

  app.get("/ready", async () => ({ ready: true }));
  return app;
}
