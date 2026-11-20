"""Writes the examples of Book 3 (Node edition), the chapter "Security: Attacks and Defences".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start)

A Fastify API where each attack has two routes side by side: /unsafe/... written the obvious way, and the
safe version. SQL injection that leaks password hashes, over-posting that makes a customer an admin, a path
that reads the .env file, then the defences: parameters, strict schemas, checked paths, security headers
(@fastify/helmet), CORS for one origin, a body size limit, and configuration checked at start-up. Every
request is made with curl against the running server; transcripts are saved as *.sh.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Server, Session, fill  # noqa: E402

URL = "postgres://bit:secret@localhost:5432/shop"

T = {
    "en": dict(
        w_kit="Robot kit", w_wheels="Spare wheels", w_sara="Sara", w_omar="Omar",
        w_terms="Terms of sale: prices include VAT; returns within 14 days.",
        w_c_concat="DANGER: the input becomes part of the SQL text",
        w_c_param="the input travels separately, as $1: it is only ever a value",
        w_c_mass="DANGER: every field the client sends is written, role included",
        w_c_strict="only the fields a customer may change; any other key is refused",
        w_c_join="DANGER: '../' climbs out of the folder",
        w_c_inside="resolve the full path, then check it is still inside the folder",
        w_c_config="checked once, at start-up: a missing or wrong setting stops the server at once",
        w_c_helmet="security headers on every response",
        w_c_cors="browsers may call this API only from the shop's own website",
        w_c_limit="bodies above 100 KB are refused before they are read",
        w_c_hide="the details stay in the log; the client learns nothing about the code",
        w_c_status="a missing file is a 404, a body that fails its schema a 422 (as in Chapter 3)",
        w_p_invalid="Invalid body", w_p_not_found="Not found", w_p_too_large="Body too large",
        w_p_server="Server error",
        w_s_search="An ordinary search", w_s_inject="The same search, with SQL in the input",
        w_s_safe_inject="The same input, as a parameter",
        w_s_mass="Omar changes his name, and his role", w_s_check="His account now",
        w_s_strict="The same request, on the safe route",
        w_s_file="A public file", w_s_climb="Climbing out of the folder",
        w_s_safe_climb="The same path, on the safe route",
        w_s_headers="The headers of every response",
        w_s_cors_ok="A request from the shop's website", w_s_cors_bad="A request from another website",
        w_s_big="A body of 200 KB", w_s_config="A wrong setting at start-up",
        w_s_audit="Known vulnerabilities in the dependencies",
        w_s_preflight="What a browser asks before a PATCH from the shop's website",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية", w_sara="سارة", w_omar="عمر",
        w_terms="شروط البيع: الأسعار تشمل الضريبة؛ والإرجاع خلال 14 يوماً.",
        w_c_concat="خطر: المدخل يصير جزءاً من نص SQL",
        w_c_param="المدخل يسافر منفصلاً، بصفة $1: لا يكون إلا قيمة",
        w_c_mass="خطر: كل حقل يرسله العميل يُكتب، والدور معه",
        w_c_strict="الحقول التي يجوز للزبون تغييرها وحدها؛ وأي مفتاح آخر يُرفض",
        w_c_join="خطر: '../' تصعد خارج المجلد",
        w_c_inside="احسب المسار الكامل، ثم تحقق أنه ما زال داخل المجلد",
        w_c_config="يُفحص مرة عند البدء: إعداد ناقص أو خاطئ يوقف الخادم في الحال",
        w_c_helmet="ترويسات أمان مع كل استجابة",
        w_c_cors="المتصفحات تستدعي هذا API من موقع المتجر وحده",
        w_c_limit="الأجسام فوق 100 KB تُرفض قبل قراءتها",
        w_c_hide="التفاصيل تبقى في السجل؛ والعميل لا يعرف شيئاً عن الكود",
        w_c_status="الملف المفقود 404، والجسم الذي يخالف مخططه 422 (كما في الفصل 3)",
        w_p_invalid="جسم غير صالح", w_p_not_found="غير موجود", w_p_too_large="الجسم أكبر من اللازم",
        w_p_server="خطأ في الخادم",
        w_s_search="بحث عادي", w_s_inject="البحث نفسه، وفي المدخل SQL",
        w_s_safe_inject="المدخل نفسه، بصفة معامل",
        w_s_mass="عمر يغيّر اسمه، ودوره", w_s_check="حسابه الآن",
        w_s_strict="الطلب نفسه، على المسار الآمن",
        w_s_file="ملف عام", w_s_climb="الصعود خارج المجلد",
        w_s_safe_climb="المسار نفسه، على المسار الآمن",
        w_s_headers="ترويسات كل استجابة",
        w_s_cors_ok="طلب من موقع المتجر", w_s_cors_bad="طلب من موقع آخر",
        w_s_big="جسم من 200 KB", w_s_config="إعداد خاطئ عند البدء",
        w_s_audit="الثغرات المعروفة في الاعتماديات",
        w_s_preflight="ما يسأله المتصفح قبل PATCH من موقع المتجر",
    ),
}

FILES = {
    ".env": f"DATABASE_URL={URL}\nALLOWED_ORIGIN=https://shop.example\n",
    "package.json": '''{
  "name": "bit-shop-security",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node --env-file=.env src/server.ts",
    "check": "tsc"
  },
  "dependencies": {
    "@fastify/cors": "^11.4.0",
    "@fastify/helmet": "^13.2.0",
    "fastify": "^5.12.8",
    "fastify-type-provider-zod": "^7.0.0",
    "pg": "^8.23.1",
    "zod": "^4.6.7"
  },
  "devDependencies": {
    "@types/node": "^22.20.5",
    "@types/pg": "^8.23.1",
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
    "types": ["node"]
  },
  "include": ["src"]
}
''',
    "schema.sql": '''CREATE TABLE users (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name          text NOT NULL,
  email         text NOT NULL UNIQUE,
  role          text NOT NULL DEFAULT 'customer',
  password_hash text NOT NULL
);
CREATE TABLE products (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL
);
INSERT INTO users (name, email, role, password_hash) VALUES
  ('{w_sara}', 'sara@example.com', 'admin', 'scrypt$32768$nNSMalEv_zb9$Kj18iYtLJHiZb'),
  ('{w_omar}', 'omar@example.com', 'customer', 'scrypt$32768$j84P2D9FMN8n$6kpcvb9TyJSt0');
INSERT INTO products (name, price) VALUES ('{w_kit}', 45000), ('{w_wheels}', 6000);
''',
    "public/terms.txt": "{w_terms}\n",
    "src/config.ts": '''import { z } from "zod";

// {w_c_config}
const Config = z.object({
  DATABASE_URL: z.url(),
  ALLOWED_ORIGIN: z.url(),
  PORT: z.coerce.number().int().default(3000),
});

const parsed = Config.safeParse(process.env);
if (!parsed.success) {
  console.error("Invalid configuration:");
  for (const issue of parsed.error.issues) {
    console.error(`  ${issue.path.join(".")}: ${issue.message}`);
  }
  process.exit(1);
}
export const config = parsed.data;
''',
    "src/db.ts": '''import pg from "pg";
import { config } from "./config.ts";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));
export const db = new pg.Pool({ connectionString: config.DATABASE_URL });
''',
    "src/routes/search.ts": '''import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { db } from "../db.ts";

const Query = z.object({ q: z.string().max(100) });

export const searchRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get("/unsafe/products", { schema: { querystring: Query } }, async (request) => {
    // {w_c_concat}
    const sql = `SELECT name, price FROM products WHERE name = '${request.query.q}'`;
    return (await db.query(sql)).rows;
  });

  app.get("/products", { schema: { querystring: Query } }, async (request) => {
    // {w_c_param}
    const sql = "SELECT name, price FROM products WHERE name = $1";
    return (await db.query(sql, [request.query.q])).rows;
  });
};
''',
    "src/routes/users.ts": '''import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { db } from "../db.ts";

const Id = z.object({ id: z.coerce.number().int() });
const show = "RETURNING id, name, role";

export const userRoutes: FastifyPluginAsyncZod = async (app) => {
  app.patch(
    "/unsafe/users/:id",
    { schema: { params: Id, body: z.record(z.string(), z.string()) } },
    async (request) => {
      // {w_c_mass}
      const fields = Object.keys(request.body);
      const set = fields.map((f, i) => `"${f}" = $${i + 2}`).join(", ");
      const values = [request.params.id, ...Object.values(request.body)];
      const sql = `UPDATE users SET ${set} WHERE id = $1 ${show}`;
      return (await db.query(sql, values)).rows[0];
    },
  );

  app.patch(
    "/users/:id",
    {
      schema: {
        params: Id,
        // {w_c_strict}
        body: z.strictObject({ name: z.string().trim().min(1).max(100) }),
      },
    },
    async (request) => {
      const sql = `UPDATE users SET name = $2 WHERE id = $1 ${show}`;
      return (await db.query(sql, [request.params.id, request.body.name])).rows[0];
    },
  );
};
''',
    "src/routes/files.ts": '''import { readFile } from "node:fs/promises";
import path from "node:path";
import type { FastifyPluginAsync } from "fastify";

const folder = path.join(import.meta.dirname, "../../public");

export const fileRoutes: FastifyPluginAsync = async (app) => {
  app.get<{ Params: { "*": string } }>("/unsafe/files/*", async (request, reply) => {
    // {w_c_join}
    const file = path.join(folder, request.params["*"]);
    return reply.type("text/plain").send(await readFile(file, "utf8"));
  });

  app.get<{ Params: { "*": string } }>("/files/*", async (request, reply) => {
    // {w_c_inside}
    const file = path.resolve(folder, request.params["*"]);
    if (!file.startsWith(folder + path.sep)) return reply.callNotFound();
    return reply.type("text/plain").send(await readFile(file, "utf8"));
  });
};
''',
    "src/app.ts": '''import Fastify, { type FastifyError } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import { serializerCompiler, validatorCompiler } from "fastify-type-provider-zod";
import { config } from "./config.ts";
import { fileRoutes } from "./routes/files.ts";
import { searchRoutes } from "./routes/search.ts";
import { userRoutes } from "./routes/users.ts";

export async function buildApp() {
  // {w_c_limit}
  const app = Fastify({ bodyLimit: 100 * 1024 });
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // {w_c_helmet}
  await app.register(helmet);
  // {w_c_cors}
  await app.register(cors, { origin: [config.ALLOWED_ORIGIN], methods: ["GET", "PATCH"] });

  const titles: Record<number, string> = {
    404: "{w_p_not_found}",
    413: "{w_p_too_large}",
    422: "{w_p_invalid}",
  };
  app.setErrorHandler((error: FastifyError, request, reply) => {
    // {w_c_status}
    const status =
      error.code === "ENOENT" ? 404 : error.validation ? 422 : (error.statusCode ?? 500);
    // {w_c_hide}
    if (status >= 500) request.log.error(error);
    return reply.code(status).send({ title: titles[status] ?? "{w_p_server}", status });
  });

  app.setNotFoundHandler((request, reply) =>
    reply.code(404).send({ title: "{w_p_not_found}", status: 404 }),
  );

  await app.register(searchRoutes);
  await app.register(userRoutes);
  await app.register(fileRoutes);
  return app;
}
''',
    "src/server.ts": '''import { buildApp } from "./app.ts";
import { config } from "./config.ts";

const app = await buildApp();
await app.listen({ port: config.PORT });
console.log(`Listening on http://localhost:${config.PORT}`);
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.run("npx tsc")
    s.lines.clear()

    s.note(t["w_s_config"])
    s.run("ALLOWED_ORIGIN=shop node --env-file=.env src/server.ts", check=False)
    s.save(folder / "config.sh")

    with Server("node --env-file=.env src/server.ts", folder, "http://localhost:3000/files/terms.txt"):
        q = "curl -s -G localhost:3000{} --data-urlencode \"q={}\" | jq -c"
        evil = "x' UNION SELECT email || ' ' || password_hash, 0 FROM users --"
        s.note(t["w_s_search"])
        s.run(q.format("/unsafe/products", t["w_kit"]))
        s.note(t["w_s_inject"])
        s.run(q.format("/unsafe/products", evil).replace("jq -c", "jq -c '.[]'"))
        s.note(t["w_s_safe_inject"])
        s.run(q.format("/products", evil))
        s.save(folder / "injection.sh")

        patch = ("curl -s -X PATCH localhost:3000PREFIX/users/2 -H 'content-type: application/json' "
                 f"-d '{{\"name\":\"{t['w_omar']}\",\"role\":\"admin\"}}' | jq -c")
        s.note(t["w_s_mass"])
        s.run(patch.replace("PREFIX", "/unsafe"))
        s.run("psql shop -q -c \"UPDATE users SET role = 'customer' WHERE id = 2\"")
        s.lines.pop()
        s.note(t["w_s_strict"])
        s.run(patch.replace("PREFIX", ""))
        s.save(folder / "overposting.sh")

        s.note(t["w_s_file"])
        s.run("curl -s localhost:3000/unsafe/files/terms.txt")
        s.note(t["w_s_climb"])
        s.run("curl -s --path-as-is localhost:3000/unsafe/files/../.env")
        s.note(t["w_s_safe_climb"])
        s.run("curl -s --path-as-is localhost:3000/files/../.env | jq -c")
        s.save(folder / "traversal.sh")

        s.note(t["w_s_headers"])
        s.run("curl -s -I localhost:3000/files/terms.txt | grep -v -i "
              "'^date\\|^connection\\|^keep-alive\\|^content-length\\|^\\s*$'",
              shown="curl -s -I localhost:3000/files/terms.txt")
        s.save(folder / "headers.sh")

        s.note(t["w_s_cors_ok"])
        s.run("curl -s -I localhost:3000/files/terms.txt -H 'Origin: https://shop.example' "
              "| grep -i '^HTTP\\|^access-control\\|^vary'")
        s.note(t["w_s_cors_bad"])
        s.run("curl -s -I localhost:3000/files/terms.txt -H 'Origin: https://evil.example' "
              "| grep -i '^HTTP\\|^access-control\\|^vary'")
        s.save(folder / "cors.sh")

        s.note(t["w_s_big"])
        s.run("head -c 200000 /dev/zero | tr '\\0' 'a' | sed 's/.*/{\"name\":\"&\"}/' "
              "| curl -s -X PATCH localhost:3000/users/2 -H 'content-type: application/json' "
              "--data-binary @- | jq -c")
        s.save(folder / "limit.sh")

        s.note(t["w_s_preflight"])
        s.run("curl -s -i -X OPTIONS localhost:3000/users/2 -H 'Origin: https://shop.example' "
              "-H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type' "
              "| grep -i '^HTTP\\|^access-control'")
        s.save(folder / "answers.sh")

    s.note(t["w_s_audit"])
    s.run("cd ../../.. && npm audit", shown="npm audit")
    s.save(folder / "audit.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
