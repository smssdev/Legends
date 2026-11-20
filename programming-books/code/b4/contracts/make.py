"""Writes the examples of Book 4, chapter "API Contracts Between Frontend and Backend", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4)

Bit Booking's first two endpoints, contract first: openapi.yaml describes them; openapi-typescript generates
the types both sides use; the Fastify server validates requests with the contract's own schemas; a contract
test checks every response against the document (and catches an undocumented error format); a typed client
built with openapi-fetch calls the running server; the type checker catches a misspelt field; and a small
script lists the breaking changes between two versions of the contract. Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_y_slots="Free start times for one staff member on one day",
        w_y_free="The free slots, earliest first", w_y_book="Book a slot",
        w_y_made="The booking", w_y_taken="The slot is already booked", w_y_bad="The request is invalid",
        w_m_taken="Slot taken", w_m_taken_d="Another booking starts or ends inside this time.",
        w_m_bad="Invalid request",
        w_c_contract="the contract is the source: its schemas validate every request",
        w_c_types="types generated from the same contract",
        w_c_hours="opening hours and the service length are fixed here; Chapter 1 put them in tables",
        w_c_problem="every error leaves as a Problem, as the contract promises",
        w_c_bug="BUG=errors leaves Fastify's own error format in place, to show what the contract test catches",
        w_c_client="a client typed by the contract: paths, parameters, bodies and answers",
        w_c_check="every response must be in the contract, with its documented type and shape",
        w_c_ref="the response's schema, found in the contract by its JSON pointer",
        w_c_walk="compare every operation of the old version with the new one",
        w_c_req="a field the old clients do not send, now required",
        w_c_res="a field the old clients read, now gone",
        w_c_enum="a value the old clients have never seen",
        w_t_slots="lists free slots in the documented shape",
        w_t_book="creates a booking in the documented shape",
        w_t_taken="answers 409 with a Problem when the slot is taken",
        w_t_bad="answers 422 with a Problem when the email is invalid",
        w_b_removed="removed", w_b_required="new required request field",
        w_b_gone="response field removed", w_b_enum="new value clients may not handle",
        w_b_ok="no breaking changes", w_b_found="breaking changes",
        w_s_gen="Types from the contract", w_s_test="The contract test",
        w_s_bug="The same test, with Fastify's own error format",
        w_s_client="The typed client against the running server",
        w_s_typo="A misspelt field, caught before the code runs",
        w_s_breaking="What would break if we published the next version",
        w_d_slots="first free slots", w_d_first="first booking", w_d_again="same slot again",
    ),
    "ar": dict(
        w_y_slots="أوقات البدء المتاحة لموظف واحد في يوم واحد",
        w_y_free="المواعيد المتاحة، الأقرب أولاً", w_y_book="احجز موعداً",
        w_y_made="الحجز", w_y_taken="الموعد محجوز من قبل", w_y_bad="الطلب غير صالح",
        w_m_taken="الموعد محجوز", w_m_taken_d="حجز آخر يبدأ أو ينتهي داخل هذا الوقت.",
        w_m_bad="طلب غير صالح",
        w_c_contract="العقد هو المصدر: مخططاته تتحقق من كل طلب",
        w_c_types="أنواع مولَّدة من العقد نفسه",
        w_c_hours="ساعات العمل ومدة الخدمة ثابتة هنا؛ والفصل 1 وضعها في جداول",
        w_c_problem="كل خطأ يخرج Problem، كما يعد العقد",
        w_c_bug="BUG=errors يترك صيغة أخطاء Fastify نفسه، لنرى ما يمسكه اختبار العقد",
        w_c_client="عميل أنواعه من العقد: المسارات والمعاملات والأجسام والإجابات",
        w_c_check="كل إجابة يجب أن تكون في العقد، بنوعها وشكلها الموثقين",
        w_c_ref="مخطط الإجابة، يُعثر عليه في العقد بمؤشر JSON",
        w_c_walk="قارن كل عملية في النسخة القديمة بالجديدة",
        w_c_req="حقل لا يرسله العملاء القدامى، صار مطلوباً",
        w_c_res="حقل يقرؤه العملاء القدامى، اختفى",
        w_c_enum="قيمة لم يرها العملاء القدامى قط",
        w_t_slots="lists free slots in the documented shape",
        w_t_book="creates a booking in the documented shape",
        w_t_taken="answers 409 with a Problem when the slot is taken",
        w_t_bad="answers 422 with a Problem when the email is invalid",
        w_b_removed="حُذف", w_b_required="حقل جديد مطلوب في الطلب",
        w_b_gone="حُذف حقل من الإجابة", w_b_enum="قيمة جديدة قد لا يعالجها العملاء",
        w_b_ok="لا تغييرات كاسرة", w_b_found="تغييرات كاسرة",
        w_s_gen="الأنواع من العقد", w_s_test="اختبار العقد",
        w_s_bug="الاختبار نفسه، بصيغة أخطاء Fastify نفسه",
        w_s_client="العميل ذو الأنواع على الخادم العامل",
        w_s_typo="حقل مكتوب خطأ، يُمسك قبل أن يعمل الكود",
        w_s_breaking="ما الذي سينكسر لو نشرنا النسخة التالية",
        w_d_slots="أول المواعيد المتاحة", w_d_first="الحجز الأول", w_d_again="الموعد نفسه ثانية",
    ),
}

OPENAPI = '''openapi: 3.1.0
info:
  title: Bit Booking API
  version: 1.0.0
paths:
  /slots:
    get:
      operationId: listSlots
      summary: {w_y_slots}
      parameters:
        - name: staff_id
          in: query
          required: true
          schema: { type: integer, minimum: 1 }
        - name: date
          in: query
          required: true
          schema: { type: string, format: date }
      responses:
        "200":
          description: {w_y_free}
          content:
            application/json:
              schema:
                type: object
                required: [data]
                properties:
                  data:
                    type: array
                    items: { $ref: "#/components/schemas/Slot" }
  /bookings:
    post:
      operationId: createBooking
      summary: {w_y_book}
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: "#/components/schemas/BookingIn" }
      responses:
        "201":
          description: {w_y_made}
          content:
            application/json:
              schema: { $ref: "#/components/schemas/Booking" }
        "409":
          description: {w_y_taken}
          content:
            application/problem+json:
              schema: { $ref: "#/components/schemas/Problem" }
        "422":
          description: {w_y_bad}
          content:
            application/problem+json:
              schema: { $ref: "#/components/schemas/Problem" }
components:
  schemas:
    Slot:
      type: object
      required: [starts_at, ends_at]
      additionalProperties: false
      properties:
        starts_at: { type: string, format: date-time }
        ends_at: { type: string, format: date-time }
    BookingIn:
      type: object
      required: [staff_id, starts_at, email]
      additionalProperties: false
      properties:
        staff_id: { type: integer, minimum: 1 }
        starts_at: { type: string, format: date-time }
        email: { type: string, format: email, maxLength: 254 }
    Booking:
      type: object
      required: [id, staff_id, starts_at, ends_at, email, status]
      additionalProperties: false
      properties:
        id: { type: integer }
        staff_id: { type: integer }
        starts_at: { type: string, format: date-time }
        ends_at: { type: string, format: date-time }
        email: { type: string }
        status: { type: string, enum: [confirmed, cancelled] }
    Problem:
      type: object
      required: [title, status]
      properties:
        title: { type: string }
        status: { type: integer }
        detail: { type: string }
'''

FILES = {
    "package.json": '''{
  "name": "bit-booking-contracts",
  "private": true,
  "type": "module",
  "scripts": {
    "types": "openapi-typescript openapi.yaml -o src/api.d.ts",
    "start": "node src/server.ts",
    "test": "node --test --test-reporter=spec",
    "check": "tsc"
  }
}
''',
    "tsconfig.json": '''{
  "compilerOptions": {
    "target": "es2023",
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
  "include": ["src", "test"]
}
''',
    "src/app.ts": '''import { readFileSync } from "node:fs";
import Fastify, { type FastifyError } from "fastify";
import { parse } from "yaml";
import type { components } from "./api.d.ts";

// {w_c_types}
type Booking = components["schemas"]["Booking"];
type BookingIn = components["schemas"]["BookingIn"];
type Problem = components["schemas"]["Problem"];

// {w_c_contract}
const contract = parse(readFileSync("openapi.yaml", "utf8"));
const schemas = contract.components.schemas;

// {w_c_hours}
const MINUTES = 30;
const OPEN = "10:00";
const CLOSE = "14:00";

const problem = (status: number, title: string, detail?: string): Problem => ({
  title,
  status,
  ...(detail && { detail }),
});

export function buildApp() {
  const app = Fastify();
  const bookings: Booking[] = [];
  let nextId = 1;

  const overlaps = (staffId: number, start: number, end: number) =>
    bookings.some(
      (b) =>
        b.staff_id === staffId &&
        b.status === "confirmed" &&
        Date.parse(b.starts_at) < end &&
        start < Date.parse(b.ends_at),
    );

  // {w_c_problem}
  if (process.env.BUG !== "errors") {
    app.setErrorHandler((error: FastifyError, _request, reply) => {
      const status = error.validation ? 422 : 500;
      const body = problem(status, "{w_m_bad}", error.validation ? error.message : undefined);
      return reply.code(status).type("application/problem+json").send(body);
    });
  }

  app.get<{ Querystring: { staff_id: number; date: string } }>(
    "/slots",
    {
      schema: {
        querystring: {
          type: "object",
          required: ["staff_id", "date"],
          properties: { staff_id: { type: "integer", minimum: 1 }, date: { type: "string", format: "date" } },
        },
      },
    },
    async (request) => {
      const { staff_id, date } = request.query;
      const data = [];
      const close = Date.parse(`${date}T${CLOSE}:00+02:00`);
      for (let t = Date.parse(`${date}T${OPEN}:00+02:00`); t + MINUTES * 60_000 <= close; t += MINUTES * 60_000) {
        const end = t + MINUTES * 60_000;
        if (!overlaps(staff_id, t, end)) {
          data.push({ starts_at: new Date(t).toISOString(), ends_at: new Date(end).toISOString() });
        }
      }
      return { data };
    },
  );

  app.post<{ Body: BookingIn }>(
    "/bookings",
    { schema: { body: schemas.BookingIn } },
    async (request, reply) => {
      const { staff_id, starts_at, email } = request.body;
      const start = Date.parse(starts_at);
      const end = start + MINUTES * 60_000;
      if (overlaps(staff_id, start, end)) {
        const body = problem(409, "{w_m_taken}", "{w_m_taken_d}");
        return reply.code(409).type("application/problem+json").send(body);
      }
      const booking: Booking = {
        id: nextId++,
        staff_id,
        starts_at: new Date(start).toISOString(),
        ends_at: new Date(end).toISOString(),
        email,
        status: "confirmed",
      };
      bookings.push(booking);
      return reply.code(201).send(booking);
    },
  );

  return app;
}
''',
    "src/server.ts": '''import { buildApp } from "./app.ts";

await buildApp().listen({ port: 3000 });
''',
    "src/demo.ts": '''import createClient from "openapi-fetch";
import type { paths } from "./api.d.ts";

// {w_c_client}
const api = createClient<paths>({ baseUrl: "http://localhost:3000" });

const slots = await api.GET("/slots", {
  params: { query: { staff_id: 1, date: "2026-12-01" } },
});
const free = slots.data?.data ?? [];
console.log("{w_d_slots}:", free.slice(0, 3).map((s) => s.starts_at));

const body = { staff_id: 1, starts_at: free[0]!.starts_at, email: "sara@example.com" };
const first = await api.POST("/bookings", { body });
console.log("{w_d_first}:", first.response.status, first.data?.id, first.data?.status);

const again = await api.POST("/bookings", { body: { ...body, email: "karim@example.com" } });
console.log("{w_d_again}:", again.response.status, again.error?.title);
''',
    "test/contract.test.ts": '''import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { Ajv2020 } from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import type { LightMyRequestResponse } from "fastify";
import { parse } from "yaml";
import { buildApp } from "../src/app.ts";

const contract = parse(readFileSync("openapi.yaml", "utf8"));
const ajv = new Ajv2020({ strict: false, allErrors: true });
addFormats.default(ajv);
ajv.addSchema(contract, "api");
const pointer = (part: string) => part.replaceAll("~", "~0").replaceAll("/", "~1");

// {w_c_check}
function check(method: string, path: string, res: LightMyRequestResponse) {
  const responses = contract.paths[path]?.[method]?.responses ?? {};
  const doc = responses[res.statusCode];
  assert.ok(doc, `${method.toUpperCase()} ${path} ${res.statusCode} is not in the contract`);
  const [type] = Object.keys(doc.content);
  assert.equal(String(res.headers["content-type"]).split(";")[0], type);
  // {w_c_ref}
  const ref = `/paths/${pointer(path)}/${method}/responses/${res.statusCode}/content/${pointer(type!)}/schema`;
  const validate = ajv.getSchema(`api#${ref}`)!;
  assert.ok(validate(res.json()), ajv.errorsText(validate.errors));
}

const booking = { staff_id: 1, starts_at: "2026-12-01T10:00:00+02:00", email: "sara@example.com" };

test("{w_t_slots}", async () => {
  const res = await buildApp().inject({ url: "/slots?staff_id=1&date=2026-12-01" });
  check("get", "/slots", res);
});

test("{w_t_book}", async () => {
  const res = await buildApp().inject({ method: "POST", url: "/bookings", body: booking });
  check("post", "/bookings", res);
});

test("{w_t_taken}", async () => {
  const app = buildApp();
  await app.inject({ method: "POST", url: "/bookings", body: booking });
  const res = await app.inject({ method: "POST", url: "/bookings", body: booking });
  assert.equal(res.statusCode, 409);
  check("post", "/bookings", res);
});

test("{w_t_bad}", async () => {
  const body = { ...booking, email: "not an email" };
  const res = await buildApp().inject({ method: "POST", url: "/bookings", body });
  check("post", "/bookings", res);
});
''',
    "breaking.ts": '''import { readFileSync } from "node:fs";
import { parse } from "yaml";

type Schema = { $ref?: string; required?: string[]; properties?: Record<string, Schema>; enum?: string[] };
const [before, after] = process.argv.slice(2).map((f) => parse(readFileSync(f!, "utf8")));
const resolve = (doc: any, s: Schema = {}): Schema =>
  s.$ref ? doc.components.schemas[s.$ref.split("/").pop()!] : s;
const found: string[] = [];

// {w_c_walk}
for (const [path, item] of Object.entries<any>(before.paths)) {
  for (const [method, op] of Object.entries<any>(item)) {
    const name = `${method.toUpperCase()} ${path}`;
    const next = after.paths[path]?.[method];
    if (!next) {
      found.push(`{w_b_removed}: ${name}`);
      continue;
    }
    // {w_c_req}
    const oldIn = resolve(before, op.requestBody?.content["application/json"]?.schema);
    const newIn = resolve(after, next.requestBody?.content["application/json"]?.schema);
    for (const field of newIn.required ?? []) {
      if (!oldIn.required?.includes(field)) found.push(`${name}: {w_b_required} "${field}"`);
    }
    for (const [status, res] of Object.entries<any>(op.responses)) {
      const [type] = Object.keys(res.content ?? {});
      const oldOut = resolve(before, res.content?.[type!]?.schema);
      const newOut = resolve(after, next.responses[status]?.content?.[type!]?.schema);
      for (const [field, schema] of Object.entries(oldOut.properties ?? {})) {
        // {w_c_res}
        if (!newOut.properties?.[field]) found.push(`${name} ${status}: {w_b_gone} "${field}"`);
        // {w_c_enum}
        const added = (newOut.properties?.[field]?.enum ?? []).filter((v) => !schema.enum?.includes(v));
        if (schema.enum && added.length) found.push(`${name} ${status}: "${field}" {w_b_enum}: ${added.join(", ")}`);
      }
    }
  }
}

console.log(found.length ? `${found.length} {w_b_found}:` : "{w_b_ok}");
for (const line of found) console.log(`- ${line}`);
process.exitCode = found.length ? 1 : 0;
''',
}

TYPO = '''import type { components } from "./api.d.ts";

type Booking = components["schemas"]["Booking"];

export const label = (b: Booking) =>
  b.status === "canceled" ? `(${b.start_at})` : b.starts_at;
'''


def next_version(text):
    """The next version of the contract: what a team might change without thinking about clients."""
    text = text.replace("version: 1.0.0", "version: 2.0.0")
    text = text.replace("required: [staff_id, starts_at, email]", "required: [staff_id, starts_at, email, phone]")
    text = text.replace("        email: { type: string, format: email, maxLength: 254 }\n",
                        "        email: { type: string, format: email, maxLength: 254 }\n"
                        "        phone: { type: string }\n        notes: { type: string }\n")
    text = text.replace("      required: [id, staff_id, starts_at, ends_at, email, status]",
                        "      required: [id, staff_id, starts_at, email, status]")
    text = text.replace("        ends_at: { type: string, format: date-time }\n        email: { type: string }\n",
                        "        email: { type: string }\n")
    text = text.replace("enum: [confirmed, cancelled]", "enum: [confirmed, cancelled, no_show]")
    return text


def record(folder, t):
    s = Session(folder)
    s.note(t["w_s_gen"])
    s.run("npm run --silent types 2>&1 | sed -E 's/ \\[[0-9.]+ms\\]//'", shown="npm run types")
    s.run("grep -A9 '  Booking: {' src/api.d.ts", shown="grep -A9 'Booking: {' src/api.d.ts")
    s.save(folder / "generate.sh")
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "src", "test", "breaking.ts"],
                   cwd=folder, check=True, capture_output=True)
    s.run("npx tsc")
    s.lines.clear()

    test = ("npm test --silent 2>&1 | grep -v '^$\\|duration_ms' | sed -E 's/\\(([0-9.]+)ms\\)/(…ms)/' "
            "| grep -v '^ℹ \\(suites\\|cancelled\\|skipped\\|todo\\)'")
    s.note(t["w_s_test"])
    s.run(test, shown="npm test")
    s.save(folder / "test.sh")
    s.note(t["w_s_bug"])
    s.run("BUG=errors " + test + " | grep -E '^✖ answers|is not in|^ℹ (pass|fail)' | sed -E 's/^ +//' "
          "| awk '!seen[$0]++'",
          shown="BUG=errors npm test", check=False)
    s.save(folder / "bug.sh")

    with Server("node src/server.ts", folder, "http://localhost:3000/slots?staff_id=1&date=2026-12-01"):
        s.note(t["w_s_client"])
        s.run("node src/demo.ts")
        s.save(folder / "client.sh")

    (folder / "src/wrong.ts").write_text(TYPO)
    s.note(t["w_s_typo"])
    s.run("npx tsc | sed -E 's/: error TS[0-9]+:/:/'", shown="npx tsc", check=False)
    s.save(folder / "typo.sh")
    (folder / "src/wrong.ts").unlink()

    (folder / "openapi.next.yaml").write_text(next_version((folder / "openapi.yaml").read_text()))
    s.note(t["w_s_breaking"])
    s.run("node breaking.ts openapi.yaml openapi.next.yaml", check=False)
    s.save(folder / "breaking.sh")


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    (folder / "openapi.yaml").write_text(fill(OPENAPI, t))
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B4 / "node_modules", folder / "node_modules")
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
