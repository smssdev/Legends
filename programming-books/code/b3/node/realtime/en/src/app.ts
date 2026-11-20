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
  // one connection to publish; each subscriber gets its own, because a connection that subscribes can do nothing else
  const redis = await createClient({ url: "redis://localhost:6379" }).connect();
  const subscriber = () => redis.duplicate().connect();
  app.addHook("onClose", () => redis.close());

  app.post<{ Params: { id: string }; Body: { status: string } }>(
    "/orders/:id/status",
    async (request, reply) => {
      const id = Number(request.params.id);
      // the database would be updated here; then everyone watching hears about it, on any server
      const event = { order: id, status: request.body.status, by: name };
      await redis.publish(`order:${id}`, JSON.stringify(event));
      return reply.code(204).send();
    },
  );

  // server-sent events: an HTTP response that never ends, one event at a time
  app.get<{ Params: { id: string } }>(
    "/orders/:id/events",
    async (request, reply) => {
      // Fastify must not send a reply of its own: this route writes to the socket directly
      reply.hijack();
      reply.raw.writeHead(200, {
        "content-type": "text/event-stream",
        "cache-control": "no-cache",
      });
      reply.raw.write(`: connected to ${name}\n\n`);
      const sub = await subscriber();
      let n = 0;
      await sub.subscribe(`order:${request.params.id}`, (message) => {
        reply.raw.write(`id: ${++n}\nevent: status\ndata: ${message}\n\n`);
      });
      // a comment every 15 seconds keeps proxies from closing a quiet connection
      const ping = setInterval(() => reply.raw.write(": ping\n\n"), 15_000);
      // when the browser goes away, stop listening
      request.raw.on("close", () => {
        clearInterval(ping);
        void sub.close();
      });
    },
  );

  // WebSocket: a two-way connection; the client says what it wants to watch
  app.get("/live", { websocket: true }, async (socket) => {
    const sub = await subscriber();
    socket.on("message", async (raw) => {
      // never trust a message: anything that is not a watch request is refused
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
