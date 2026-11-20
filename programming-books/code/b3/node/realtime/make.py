"""Writes the examples of Book 3 (Node edition), the chapter "Real-time Features".
Run: python3 make.py   (Redis through code/b3/bin/redis-start)

A Fastify server that pushes an order's status to the screen the moment it changes: server-sent events with
curl as the client, WebSockets with Node's own WebSocket client, and Redis publish/subscribe between two
running copies of the server, so a change made on one reaches clients connected to the other. What the
terminal showed is saved as transcripts (*.sh).
"""
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_pub="one connection to publish; each subscriber gets its own, because a connection that "
                "subscribes can do nothing else",
        w_c_change="the database would be updated here; then everyone watching hears about it, on any server",
        w_c_sse="server-sent events: an HTTP response that never ends, one event at a time",
        w_c_hijack="Fastify must not send a reply of its own: this route writes to the socket directly",
        w_c_ping="a comment every 15 seconds keeps proxies from closing a quiet connection",
        w_c_close="when the browser goes away, stop listening",
        w_c_ws="WebSocket: a two-way connection; the client says what it wants to watch",
        w_c_check="never trust a message: anything that is not a watch request is refused",
        w_c_client="Node's own WebSocket client (the same API as in browsers)",
        w_s_sse="A screen follows order 1001 with server-sent events, while the shop changes its status",
        w_s_ws="Two copies of the server: the client is on 3001, the change is made on 3000",
        w_s_late="A change while nobody is listening, then a client that connects afterwards",
        w_d_connected="connected to",
    ),
    "ar": dict(
        w_c_pub="اتصال واحد للنشر؛ ولكل مشترك اتصاله، لأن الاتصال المشترك لا يستطيع فعل أي شيء آخر",
        w_c_change="هنا تُحدَّث قاعدة البيانات؛ ثم يسمع كل من يتابع، على أي خادم",
        w_c_sse="أحداث الخادم المرسلة: استجابة HTTP لا تنتهي، حدثاً بعد حدث",
        w_c_hijack="يجب ألا يرسل Fastify رداً من عنده: هذا المسار يكتب إلى المقبس مباشرة",
        w_c_ping="تعليق كل 15 ثانية يمنع الوسطاء من إغلاق اتصال هادئ",
        w_c_close="حين يغادر المتصفح، توقف عن الاستماع",
        w_c_ws="WebSocket: اتصال في الاتجاهين؛ والعميل يقول ما يريد متابعته",
        w_c_check="لا تثق بأي رسالة: ما ليس طلب متابعة يُرفض",
        w_c_client="عميل WebSocket الخاص بـ Node (الواجهة نفسها التي في المتصفحات)",
        w_s_sse="شاشة تتابع الطلب 1001 بأحداث الخادم المرسلة، بينما يغيّر المتجر حالته",
        w_s_ws="نسختان من الخادم: العميل على 3001، والتغيير يُجرى على 3000",
        w_s_late="تغيير لا يستمع إليه أحد، ثم عميل يتصل بعده",
        w_d_connected="متصل بـ",
    ),
}

FILES = {
    "package.json": '''{
  "name": "bit-shop-realtime",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node src/server.ts",
    "check": "tsc"
  },
  "dependencies": {
    "@fastify/websocket": "^11.3.6",
    "fastify": "^5.12.8",
    "redis": "^6.3.1",
    "zod": "^4.6.7"
  },
  "devDependencies": {
    "@types/node": "^22.20.5",
    "@types/ws": "^8.18.2",
    "typescript": "^7.0.2"
  }
}
''',
    "tsconfig.json": '''{
  "compilerOptions": {
    "target": "es2024",
    "module": "nodenext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "types": ["node"]
  },
  "include": ["src", "demos"]
}
''',
    "src/app.ts": '''import Fastify from "fastify";
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
  // {w_c_pub}
  const redis = await createClient({ url: "redis://localhost:6379" }).connect();
  const subscriber = () => redis.duplicate().connect();
  app.addHook("onClose", () => redis.close());

  app.post<{ Params: { id: string }; Body: { status: string } }>(
    "/orders/:id/status",
    async (request, reply) => {
      const id = Number(request.params.id);
      // {w_c_change}
      const event = { order: id, status: request.body.status, by: name };
      await redis.publish(`order:${id}`, JSON.stringify(event));
      return reply.code(204).send();
    },
  );

  // {w_c_sse}
  app.get<{ Params: { id: string } }>("/orders/:id/events", async (request, reply) => {
    // {w_c_hijack}
    reply.hijack();
    reply.raw.writeHead(200, {
      "content-type": "text/event-stream",
      "cache-control": "no-cache",
    });
    reply.raw.write(`: {w_d_connected} ${name}\\n\\n`);
    const sub = await subscriber();
    let n = 0;
    await sub.subscribe(`order:${request.params.id}`, (message) => {
      reply.raw.write(`id: ${++n}\\nevent: status\\ndata: ${message}\\n\\n`);
    });
    // {w_c_ping}
    const ping = setInterval(() => reply.raw.write(": ping\\n\\n"), 15_000);
    // {w_c_close}
    request.raw.on("close", () => {
      clearInterval(ping);
      void sub.close();
    });
  });

  // {w_c_ws}
  app.get("/live", { websocket: true }, async (socket) => {
    const sub = await subscriber();
    socket.on("message", async (raw) => {
      // {w_c_check}
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
''',
    "src/server.ts": '''import { buildApp } from "./app.ts";

const port = Number(process.env.PORT ?? 3000);
const app = await buildApp(`server ${port}`);
await app.listen({ port });
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
''',
    "demos/watch.ts": '''// {w_c_client}
const [url = "ws://localhost:3000/live", ms = "2000"] = process.argv.slice(2);
const socket = new WebSocket(url);
socket.addEventListener("open", () => socket.send(JSON.stringify({ watch: 1001 })));
socket.addEventListener("message", (event) => console.log("ws:", event.data));
setTimeout(() => socket.close(), Number(ms));
''',
}


def record(folder, t):
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("npx tsc")
    s.lines.clear()
    post = ("curl -s -X POST localhost:{port}/orders/1001/status -H 'content-type: application/json' "
            "-d '{{\"status\":\"{status}\"}}'")
    with Server("PORT=3000 node src/server.ts", folder, "http://localhost:3000/ready"), \
            Server("PORT=3001 node src/server.ts", folder, "http://localhost:3001/ready"):
        def two_terminals(client, shown, second, name):
            """The client runs in terminal 1 while terminal 2 makes the changes; one transcript each."""
            subprocess.Popen(f"{client} > .t1 2>&1", shell=True, cwd=folder, env=CLEAN)
            time.sleep(0.5)
            for cmd in second:
                s.run(cmd)
            s.save(folder / f"{name}-2.sh")
            time.sleep(1.5)
            s.add("$ " + shown)
            s.add((folder / ".t1").read_text())
            s.save(folder / f"{name}.sh")
            (folder / ".t1").unlink()

        s.note(t["w_s_sse"])
        two_terminals("curl -sN --max-time 1.5 localhost:3000/orders/1001/events",
                      "curl -sN localhost:3000/orders/1001/events",
                      [post.format(port=3000, status="paid"), post.format(port=3000, status="shipped")], "sse")
        s.note(t["w_s_ws"])
        two_terminals("node demos/watch.ts ws://localhost:3001/live 1500",
                      "node demos/watch.ts ws://localhost:3001/live",
                      ["redis-cli PUBSUB NUMSUB order:1001", post.format(port=3000, status="paid"),
                       post.format(port=3000, status="shipped")], "ws")
        s.note(t["w_s_late"])
        s.run(post.format(port=3000, status="delivered"))
        s.run("curl -sN --max-time 1 localhost:3000/orders/1001/events", check=False)
        s.save(folder / "answers.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src", "demos"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
