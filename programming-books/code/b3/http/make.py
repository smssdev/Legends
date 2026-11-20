"""Writes the examples of Book 3, chapter 1 "How Servers Work: HTTP in Depth", for both editions and languages.
Run: python3 make.py

The same small API (Bit's shop) is written twice, with no framework: node/server.ts on Node's own http
module, and php/server.php on PHP's built-in server. Each one is started for real, and curl and nc talk
to it; what the terminal showed is saved as the transcripts the chapter prints (*.sh).
"""
import json
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from rec import Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_p1="Robot kit", w_p2="Spare wheels", w_p3="Battery pack", w_new="USB cable",
        w_e_json="Send JSON", w_e_big="At most 1 KB", w_e_bad="The body is not valid JSON",
        w_e_req="Required", w_e_price="A whole number of piastres above 0", w_e_check="Check the fields",
        w_e_method="Use GET or POST here", w_e_none="No product with this id", w_e_here="Nothing here",
        w_e_500="Something went wrong on our side",
        w_c_web="the web app that may call this API from a browser", w_c_bytes="bytes, not characters",
        w_c_log="the details stay in the server's log", w_c_slow="a client that sends too slowly is cut off",
        w_c_forget="PHP forgets everything after each request: the products live in a file.",
        w_c_lock="two requests at once must not both write the file",
        w_c_powered="do not tell attackers which PHP version runs here",
        w_c_strlen="strlen counts bytes, not characters", w_c_run="Run: php -S localhost:8000 server.php",
        w_c_never="never reused, even after a delete", w_c_four="the file starts with 4",
        w_c_title="Bit's shop API in plain PHP.", w_c_type="no body, so no type",
        w_s_start="Start the server (and leave it running in this terminal)",
        w_s_raw="Type a request by hand: HTTP/1.1 is plain text over a TCP connection",
        w_s_v="Let curl show both sides: * is curl's own news, > is sent, < is received",
        w_s_list="A list, filtered by a query string", w_s_head="Only the headers (HEAD): the same answer without the body",
        w_s_create="Create a product: 201 Created, and Location says where it lives",
        w_s_after="It is there now", w_s_errors="Each mistake has its own status code",
        w_s_404="No such product", w_s_405="A method this address does not allow",
        w_s_415="A body that is not JSON", w_s_400="Broken JSON", w_s_422="JSON, but the fields are wrong",
        w_s_413="Too big", w_s_etag="The first visit: the server sends the list and its ETag",
        w_s_304="The next visit sends the ETag back: nothing changed, so 304 and no body",
        w_s_pre="A browser asks first (a preflight) before a POST from another site",
        w_s_evil="Another site is not on the list: no Access-Control header, so the browser blocks it",
        w_s_keep="Two requests in one curl command: is the connection reused?",
        w_s_log="Meanwhile, the server's terminal",
    ),
    "ar": dict(
        w_p1="عدة الروبوت", w_p2="عجلات احتياطية", w_p3="حزمة بطارية", w_new="كابل USB",
        w_e_json="أرسل JSON", w_e_big="الحد الأقصى 1 KB", w_e_bad="المحتوى ليس JSON صالحاً",
        w_e_req="مطلوب", w_e_price="عدد صحيح من القروش أكبر من 0", w_e_check="راجع الحقول",
        w_e_method="استخدم GET أو POST هنا", w_e_none="لا يوجد منتج بهذا الرقم", w_e_here="لا شيء هنا",
        w_e_500="حدث خطأ عندنا",
        w_c_web="تطبيق الويب المسموح له باستدعاء هذه الواجهة من المتصفح", w_c_bytes="بالبايت لا بالحروف",
        w_c_log="التفاصيل تبقى في سجل الخادم", w_c_slow="العميل البطيء جداً في الإرسال يُقطع",
        w_c_forget="تنسى PHP كل شيء حين ينتهي الطلب، لذلك تعيش المنتجات في ملف.",
        w_c_lock="لا يجوز أن يكتب طلبان في الملف في الوقت نفسه",
        w_c_powered="لا تخبر المهاجمين بإصدار PHP الذي يعمل هنا",
        w_c_strlen="الدالة strlen تعدّ البايتات لا الحروف", w_c_run="التشغيل: php -S localhost:8000 server.php",
        w_c_never="لا يُعاد استخدامه أبداً، حتى بعد الحذف", w_c_four="يبدأ الملف بالرقم 4",
        w_c_title="واجهة متجر Bit بلغة PHP وحدها.", w_c_type="لا محتوى، فلا نوع",
        w_s_start="شغّل الخادم (واتركه يعمل في هذه النافذة)",
        w_s_raw="اكتب طلباً بيدك: HTTP/1.1 نص عادي فوق اتصال TCP",
        w_s_v="اجعل curl يُظهر الجهتين: * أخبار curl نفسه، و> ما يُرسَل، و< ما يصل",
        w_s_list="قائمة مصفّاة بنص الاستعلام", w_s_head="الترويسات وحدها (HEAD): الجواب نفسه بلا محتوى",
        w_s_create="أنشئ منتجاً: 201 Created، وLocation يقول أين يعيش",
        w_s_after="صار موجوداً الآن", w_s_errors="لكل خطأ رمز حالة خاص به",
        w_s_404="لا يوجد منتج كهذا", w_s_405="طريقة لا يسمح بها هذا العنوان",
        w_s_415="محتوى ليس JSON", w_s_400="JSON مكسور", w_s_422="JSON، لكن الحقول خاطئة",
        w_s_413="كبير جداً", w_s_etag="الزيارة الأولى: يرسل الخادم القائمة ووسمها ETag",
        w_s_304="الزيارة التالية تعيد الوسم: لم يتغير شيء، فالجواب 304 بلا محتوى",
        w_s_pre="المتصفح يسأل أولاً (طلب تمهيدي) قبل POST من موقع آخر",
        w_s_evil="موقع آخر ليس في القائمة: لا ترويسة Access-Control، فيمنعه المتصفح",
        w_s_keep="طلبان في أمر curl واحد: هل يُعاد استخدام الاتصال؟",
        w_s_log="وفي الأثناء، نافذة الخادم",
    ),
}

NODE = r'''import { createServer } from "node:http";
import type { IncomingMessage, ServerResponse } from "node:http";
import { createHash } from "node:crypto";

type Product = { id: number; name: string; price: number };
type Headers = Record<string, string>;

const products: Product[] = [
  { id: 1, name: "{w_p1}", price: 45000 },
  { id: 2, name: "{w_p2}", price: 6000 },
  { id: 3, name: "{w_p3}", price: 12500 },
];
// {w_c_web}
const ORIGINS = ["http://localhost:5173"];
const MAX_BODY = 1024; // bytes

function send(res: ServerResponse, status: number, body?: unknown,
              headers: Headers = {}) {
  const text = body === undefined ? "" : JSON.stringify(body);
  res.writeHead(status, {
    ...(text && { "Content-Type": "application/json; charset=utf-8" }),
    "Content-Length": String(Buffer.byteLength(text)), // {w_c_bytes}
    ...headers,
  });
  res.end(text);
}

function fail(res: ServerResponse, status: number, code: string,
              message: string, extra = {}, headers: Headers = {}) {
  send(res, status, { error: { code, message, ...extra } }, headers);
}

async function handle(req: IncomingMessage, res: ServerResponse) {
  const url = new URL(req.url ?? "/", "http://localhost");
  const origin = req.headers.origin;
  if (origin && ORIGINS.includes(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  }

  if (req.method === "OPTIONS") {
    return send(res, 204, undefined, {
      "Access-Control-Allow-Methods": "GET, POST",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Max-Age": "600",
    });
  }

  if (url.pathname === "/products") {
    if (req.method === "GET" || req.method === "HEAD") {
      const max = Number(url.searchParams.get("max_price") ?? Infinity);
      const list = products.filter((p) => p.price <= max);
      const hash = createHash("md5").update(JSON.stringify(list)).digest("hex");
      const etag = `"${hash.slice(0, 16)}"`;
      if (req.headers["if-none-match"] === etag) {
        return send(res, 304, undefined, { ETag: etag });
      }
      return send(res, 200, list, { ETag: etag, "Cache-Control": "no-cache" });
    }
    if (req.method === "POST") return create(req, res);
    return fail(res, 405, "method_not_allowed", "{w_e_method}", {},
                { Allow: "GET, HEAD, POST" });
  }

  const one = url.pathname.match(/^\/products\/(\d+)$/);
  if (one && req.method === "GET") {
    const product = products.find((p) => p.id === Number(one[1]));
    if (!product) return fail(res, 404, "not_found", "{w_e_none}");
    return send(res, 200, product);
  }
  return fail(res, 404, "not_found", "{w_e_here}");
}

async function readBody(req: IncomingMessage): Promise<string> {
  let size = 0;
  const parts: Buffer[] = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_BODY) throw new Error("too_large");
    parts.push(chunk);
  }
  return Buffer.concat(parts).toString("utf8");
}

async function create(req: IncomingMessage, res: ServerResponse) {
  if (!req.headers["content-type"]?.startsWith("application/json")) {
    return fail(res, 415, "unsupported_media_type", "{w_e_json}");
  }
  let data: { name?: unknown; price?: unknown };
  try {
    data = JSON.parse(await readBody(req));
  } catch (e) {
    if (e instanceof Error && e.message === "too_large") {
      return fail(res, 413, "too_large", "{w_e_big}");
    }
    return fail(res, 400, "bad_json", "{w_e_bad}");
  }

  const { name, price } = data;
  const errors: Record<string, string> = {};
  if (typeof name !== "string" || !name.trim()) errors.name = "{w_e_req}";
  if (typeof price !== "number" || !Number.isInteger(price) || price <= 0) {
    errors.price = "{w_e_price}";
  }
  if (Object.keys(errors).length) {
    return fail(res, 422, "invalid", "{w_e_check}", { fields: errors });
  }

  const product = {
    id: products.length + 1,
    name: (name as string).trim(),
    price: price as number,
  };
  products.push(product);
  send(res, 201, product, { Location: `/products/${product.id}` });
}

const server = createServer((req, res) => {
  const start = performance.now();
  res.on("finish", () => {
    const ms = Math.round(performance.now() - start);
    console.log(`${req.method} ${req.url} ${res.statusCode} ${ms}ms`);
  });
  handle(req, res).catch((error) => {
    console.error(error); // {w_c_log}
    if (!res.headersSent) {
      fail(res, 500, "server_error", "{w_e_500}");
    }
  });
});
server.requestTimeout = 10_000; // {w_c_slow}
server.listen(3000, () => console.log("Listening on http://localhost:3000"));
'''

PHP = r'''<?php
// {w_c_title}
// {w_c_run}

// {w_c_web}
const ORIGINS = ['http://localhost:5173'];
const MAX_BODY = 1024; // bytes
const DATA = __DIR__ . '/products.json';

// {w_c_powered}
header_remove('X-Powered-By');
$start = hrtime(true);
register_shutdown_function(function () use ($start) {
    $ms = intdiv(hrtime(true) - $start, 1_000_000);
    $status = http_response_code();
    $request = "{$_SERVER['REQUEST_METHOD']} {$_SERVER['REQUEST_URI']}";
    error_log("$request $status {$ms}ms");
});

function send(int $status, mixed $body = null, array $headers = []): void
{
    $text = $body === null ? '' : json_encode($body, JSON_UNESCAPED_UNICODE);
    http_response_code($status);
    if ($text === '') {
        header('Content-Type:'); // {w_c_type}
    } else {
        header('Content-Type: application/json; charset=utf-8');
    }
    // {w_c_strlen}
    header('Content-Length: ' . strlen($text));
    foreach ($headers as $name => $value) {
        header("$name: $value");
    }
    echo $text;
}

function fail(int $status, string $code, string $message,
              array $extra = [], array $headers = []): void
{
    $error = ['code' => $code, 'message' => $message] + $extra;
    send($status, ['error' => $error], $headers);
}

function products(): array
{
    // {w_c_forget}
    return json_decode(file_get_contents(DATA), true);
}

function handle(): void
{
    $method = $_SERVER['REQUEST_METHOD'];
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $origin = $_SERVER['HTTP_ORIGIN'] ?? null;
    if ($origin && in_array($origin, ORIGINS, true)) {
        header("Access-Control-Allow-Origin: $origin");
        header('Vary: Origin');
    }

    if ($method === 'OPTIONS') {
        send(204, null, [
            'Access-Control-Allow-Methods' => 'GET, POST',
            'Access-Control-Allow-Headers' => 'Content-Type',
            'Access-Control-Max-Age' => '600',
        ]);
        return;
    }

    if ($path === '/products') {
        if ($method === 'GET' || $method === 'HEAD') {
            $max = (int) ($_GET['max_price'] ?? PHP_INT_MAX);
            $cheap = array_filter(products(), fn ($p) => $p['price'] <= $max);
            $list = array_values($cheap);
            $hash = md5(json_encode($list, JSON_UNESCAPED_UNICODE));
            $etag = '"' . substr($hash, 0, 16) . '"';
            if (($_SERVER['HTTP_IF_NONE_MATCH'] ?? null) === $etag) {
                send(304, null, ['ETag' => $etag]);
                return;
            }
            send(200, $list, ['ETag' => $etag, 'Cache-Control' => 'no-cache']);
            return;
        }
        if ($method === 'POST') {
            create();
            return;
        }
        fail(405, 'method_not_allowed', '{w_e_method}', [],
             ['Allow' => 'GET, HEAD, POST']);
        return;
    }

    if (preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'GET') {
        foreach (products() as $product) {
            if ($product['id'] === (int) $m[1]) {
                send(200, $product);
                return;
            }
        }
        fail(404, 'not_found', '{w_e_none}');
        return;
    }
    fail(404, 'not_found', '{w_e_here}');
}

function create(): void
{
    if (!str_starts_with($_SERVER['CONTENT_TYPE'] ?? '', 'application/json')) {
        fail(415, 'unsupported_media_type', '{w_e_json}');
        return;
    }
    if ((int) ($_SERVER['CONTENT_LENGTH'] ?? 0) > MAX_BODY) {
        fail(413, 'too_large', '{w_e_big}');
        return;
    }
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) {
        fail(400, 'bad_json', '{w_e_bad}');
        return;
    }

    $name = $data['name'] ?? null;
    $price = $data['price'] ?? null;
    $errors = [];
    if (!is_string($name) || trim($name) === '') {
        $errors['name'] = '{w_e_req}';
    }
    if (!is_int($price) || $price <= 0) {
        $errors['price'] = '{w_e_price}';
    }
    if ($errors) {
        fail(422, 'invalid', '{w_e_check}', ['fields' => $errors]);
        return;
    }

    $file = fopen(DATA, 'r+');
    flock($file, LOCK_EX); // {w_c_lock}
    $list = json_decode(stream_get_contents($file), true);
    $product = [
        'id' => count($list) + 1,
        'name' => trim($name),
        'price' => $price,
    ];
    $list[] = $product;
    ftruncate($file, 0);
    rewind($file);
    fwrite($file, json_encode($list, JSON_UNESCAPED_UNICODE));
    flock($file, LOCK_UN);
    fclose($file);
    send(201, $product, ['Location' => "/products/{$product['id']}"]);
}

try {
    handle();
} catch (Throwable $error) {
    error_log((string) $error); // {w_c_log}
    if (!headers_sent()) {
        fail(500, 'server_error', '{w_e_500}');
    }
}
'''


def record(folder, t, port, start_cmd):
    """Runs the chapter's sessions against a running server and saves each transcript."""
    base = f"localhost:{port}"
    s = Session(folder)
    with Server(start_cmd, folder, f"http://{base}/ready") as server:
        req = r"printf 'GET /products/1 HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n'"
        s.note(t["w_s_raw"])
        s.run(f"{req} | nc localhost {port}")
        s.save(folder / "raw.sh")

        s.note(t["w_s_v"])
        s.run(f"curl -sv {base}/products/2 2>&1", shown=f"curl -sv {base}/products/2")
        s.save(folder / "verbose.sh")

        s.note(t["w_s_list"])
        s.run(f"curl -s '{base}/products?max_price=15000'")
        s.note(t["w_s_head"])
        s.run(f"curl -sI {base}/products")
        s.save(folder / "read.sh")

        s.note(t["w_s_create"])
        body = json.dumps({"name": t["w_new"], "price": 2500}, ensure_ascii=False)
        s.run(f"curl -si -X POST {base}/products -H 'Content-Type: application/json' -d '{body}'")
        s.note(t["w_s_after"])
        s.run(f"curl -s {base}/products/4")
        s.save(folder / "create.sh")

        s.note(t["w_s_errors"])
        w = " -w ' %{http_code}\\n'"
        for note, cmd in (
            ("w_s_404", f"curl -s {base}/products/99{w}"),
            ("w_s_405", f"curl -s -X DELETE {base}/products{w}"),
            ("w_s_415", f"curl -s {base}/products -d 'name=Cable'{w}"),
            ("w_s_400", f"curl -s {base}/products -H 'Content-Type: application/json' -d '{{\"name\": '{w}"),
            ("w_s_422", f"curl -s {base}/products -H 'Content-Type: application/json' -d '{{\"price\": 9.5}}'{w}"),
            ("w_s_413", f"head -c 2000 /dev/zero | tr '\\0' x | curl -s {base}/products -H 'Content-Type: application/json' --data-binary @-{w}"),
        ):
            s.note(t[note])
            s.run(cmd)
        s.save(folder / "errors.sh")

        s.note(t["w_s_etag"])
        out = s.run(f"curl -si {base}/products")
        etag = next(l.split(": ", 1)[1] for l in out.split("\n") if l.lower().startswith("etag:"))
        s.note(t["w_s_304"])
        s.run(f"curl -si {base}/products -H 'If-None-Match: {etag}'")
        s.save(folder / "etag.sh")

        s.note(t["w_s_pre"])
        s.run(f"curl -si -X OPTIONS {base}/products -H 'Origin: http://localhost:5173' "
              "-H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: content-type'")
        s.note(t["w_s_evil"])
        s.run(f"curl -si {base}/products/1 -H 'Origin: https://evil.example'")
        s.save(folder / "cors.sh")

        s.note(t["w_s_keep"])
        s.run(f"curl -sv {base}/products/1 {base}/products/2 -o /dev/null -o /dev/null 2>&1 "
              "| grep -E 'Connected|Re-using|left intact|Closing|^< HTTP'")
        s.save(folder / "keepalive.sh")

        log = server.log(12 if port == 8000 else 8)
    s.note(t["w_s_start"])
    s.lines.append("$ " + start_cmd)
    s.add(log)
    s.save(folder / "log.sh")
    s.note(t["w_s_start"])
    s.lines.append("$ " + start_cmd)
    s.add(server.head)
    s.save(folder / "start.sh")


# The answers to exercises 3 and 5, applied to the chapter's servers and checked against them for real
# (answers/<lang>/<edition>/: the changed server and what curl showed).
NODE_DELETE = (
    '  const one = url.pathname.match(/^\\/products\\/(\\d+)$/);\n',
    '  const one = url.pathname.match(/^\\/products\\/(\\d+)$/);\n'
    '  if (one && req.method === "DELETE") {\n'
    '    const i = products.findIndex((p) => p.id === Number(one[1]));\n'
    '    if (i === -1) return fail(res, 404, "not_found", "{w_e_none}");\n'
    '    products.splice(i, 1);\n'
    '    return send(res, 204);\n'
    '  }\n')
NODE_ID = ('    id: products.length + 1,', '    id: nextId++,')
NODE_NEXT = ('const MAX_BODY', 'let nextId = products.length + 1; // {w_c_never}\nconst MAX_BODY')
NODE_GZIP = (
    '  const text = body === undefined ? "" : JSON.stringify(body);\n  res.writeHead(status, {\n'
    '    ...(text && { "Content-Type": "application/json; charset=utf-8" }),\n'
    '    "Content-Length": String(Buffer.byteLength(text)), // {w_c_bytes}\n    ...headers,\n  });\n  res.end(text);\n',
    '  const text = body === undefined ? "" : JSON.stringify(body);\n'
    '  const accepts = res.req.headers["accept-encoding"] ?? "";\n'
    '  const gzip = Buffer.byteLength(text) >= 100 && /\\bgzip\\b/.test(accepts);\n'
    '  const data = gzip ? gzipSync(text) : Buffer.from(text);\n'
    '  res.writeHead(status, {\n'
    '    ...(text && { "Content-Type": "application/json; charset=utf-8" }),\n'
    '    ...(gzip && { "Content-Encoding": "gzip" }),\n'
    '    "Content-Length": String(data.length),\n'
    '    Vary: "Accept-Encoding",\n    ...headers,\n  });\n  res.end(data);\n')
NODE_ZLIB = ('import { createHash } from "node:crypto";\n',
             'import { createHash } from "node:crypto";\nimport { gzipSync } from "node:zlib";\n')

PHP_DELETE = (
    "    if (preg_match('#^/products/(\\d+)$#', $path, $m) && $method === 'GET') {",
    "    if (preg_match('#^/products/(\\d+)$#', $path, $m) && $method === 'DELETE') {\n"
    "        $file = fopen(DATA, 'r+');\n"
    "        flock($file, LOCK_EX);\n"
    "        $list = json_decode(stream_get_contents($file), true);\n"
    "        $id = (int) $m[1];\n"
    "        $left = array_values(array_filter($list, fn ($p) => $p['id'] !== $id));\n"
    "        if (count($left) < count($list)) {\n"
    "            ftruncate($file, 0);\n"
    "            rewind($file);\n"
    "            fwrite($file, json_encode($left, JSON_UNESCAPED_UNICODE));\n"
    "        }\n"
    "        flock($file, LOCK_UN);\n"
    "        fclose($file);\n"
    "        if (count($left) === count($list)) {\n"
    "            fail(404, 'not_found', '{w_e_none}');\n"
    "            return;\n"
    "        }\n"
    "        send(204);\n"
    "        return;\n"
    "    }\n\n"
    "    if (preg_match('#^/products/(\\d+)$#', $path, $m) && $method === 'GET') {")
PHP_ID = ("    $product = [\n        'id' => count($list) + 1,",
          "    $next = __DIR__ . '/next-id.txt'; // {w_c_never}\n"
          "    $id = (int) file_get_contents($next); // {w_c_four}\n"
          "    file_put_contents($next, $id + 1);\n"
          "    $product = [\n        'id' => $id,")
PHP_GZIP = (
    "    $text = $body === null ? '' : json_encode($body, JSON_UNESCAPED_UNICODE);\n",
    "    $text = $body === null ? '' : json_encode($body, JSON_UNESCAPED_UNICODE);\n"
    "    header('Vary: Accept-Encoding');\n"
    "    $accepts = $_SERVER['HTTP_ACCEPT_ENCODING'] ?? '';\n"
    "    if (strlen($text) >= 100 && preg_match('/\\bgzip\\b/', $accepts)) {\n"
    "        $text = gzencode($text);\n"
    "        header('Content-Encoding: gzip');\n"
    "    }\n")


def patch(src, t, *pairs):
    for old, new in pairs:
        old, new = fill(old, t), fill(new, t)
        assert src.count(old) == 1, old
        src = src.replace(old, new)
    return src


def answers(lang, t):
    for ed, port, cmd, src, pairs in (
        ("node", 3000, "node server.ts", fill(NODE, t),
         [NODE_DELETE, NODE_ID, NODE_NEXT, NODE_GZIP, NODE_ZLIB]),
        ("php", 8000, "php -S localhost:8000 server.php", fill(PHP, t),
         [PHP_DELETE, PHP_ID, PHP_GZIP]),
    ):
        folder = HERE / "answers" / lang / ed
        if folder.exists():
            shutil.rmtree(folder)
        folder.mkdir(parents=True)
        (folder / ("server.ts" if ed == "node" else "server.php")).write_text(patch(src, t, *pairs))
        def seed():
            if ed == "php":
                shutil.copy(HERE / lang / "php" / "products.json", folder / "products.json")
                (folder / "next-id.txt").write_text("4")
        seed()
        base = f"localhost:{port}"
        s = Session(folder)
        w = " -w ' %{http_code}\\n'"
        with Server(cmd, folder, f"http://{base}/ready"):
            s.run(f"curl -s -X DELETE {base}/products/3{w}")
            s.run(f"curl -s -X DELETE {base}/products/3{w}")
            s.run(f"curl -s {base}/products/3{w}")
            body = json.dumps({"name": t["w_new"], "price": 2500}, ensure_ascii=False)
            s.run(f"curl -s {base}/products -H 'Content-Type: application/json' -d '{body}'{w}")
            s.save(folder / "delete.sh")
            s.run(f"curl -s -D - -o /dev/null {base}/products -H 'Accept-Encoding: gzip'")
            s.run(f"curl -s -D - -o /dev/null {base}/products")
            s.run(f"curl -s --compressed {base}/products")
            s.save(folder / "gzip.sh")
            req = r"printf 'GET /products/1 HTTP/1.1\r\nConnection: close\r\n\r\n'"
            s.run(f"{req} | nc localhost {port}")
            s.save(folder / "nohost.sh")
        seed()


for lang, t in T.items():
    for ed in ("node", "php"):
        folder = HERE / lang / ed
        if folder.exists():
            shutil.rmtree(folder)
        folder.mkdir(parents=True)
    node, php = HERE / lang / "node", HERE / lang / "php"
    (node / "server.ts").write_text(fill(NODE, t))
    (php / "server.php").write_text(fill(PHP, t))
    seed = [{"id": 1, "name": t["w_p1"], "price": 45000}, {"id": 2, "name": t["w_p2"], "price": 6000},
            {"id": 3, "name": t["w_p3"], "price": 12500}]
    (php / "products.json").write_text(json.dumps(seed, ensure_ascii=False))
    record(node, t, 3000, "node server.ts")
    record(php, t, 8000, "php -S localhost:8000 server.php")
    (php / "products.json").write_text(json.dumps(seed, ensure_ascii=False))  # the reader starts with three
    answers(lang, t)
    print("wrote", lang)
