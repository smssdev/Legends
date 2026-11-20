"""Writes the examples of Book 3, the shared chapter "Observability: Logs, Metrics and Traces".
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start, Redis through redis-start; PHP through bin/php)

The same small shop service in each edition, made observable: node/server.ts (Fastify with its pino logger and
prom-client) and php/router.php (PHP's built-in server with Monolog, and metrics kept in Redis, because a PHP
process forgets everything after each request). Both write one JSON log line per event with a trace id that
travels to a second service in the traceparent header, count requests and their durations for Prometheus,
and answer health and readiness checks, which are run with the database up and down. Transcripts are *.sh.
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_kit="Robot kit",
        w_c_json="one JSON object per line: machines can search it, people can still read it",
        w_c_trace="the trace id comes from the caller's traceparent header, or starts here",
        w_c_short="only what is useful: the method and the address, not every header",
        w_c_count="requests by route and status, and how long they took, for Prometheus to collect",
        w_c_route="the route's pattern, not the address: /products/1 and /products/2 are one series",
        w_c_call="the next service gets the same trace id, so its logs join this request's",
        w_c_health="alive: the process answers (restart it if not)",
        w_c_ready="ready: it can do its job, so send it traffic (stop sending if not)",
        w_c_redis="PHP forgets everything after each request: the counters live in Redis",
        w_c_after="after the response is sent: count it, without making the client wait",
        w_c_hide="the client gets a title and the trace id to quote; the details go to the log",
        w_c_pool="a dropped database connection is logged, not allowed to crash the process",
        w_m_checkout="checkout started", w_m_stock="stock checked", w_m_done="checkout done",
        w_m_fail="payment provider timed out",
        w_s_requests="A few requests, one with its own trace id",
        w_s_logs="What the server wrote",
        w_s_error="A request that fails",
        w_s_trace="One checkout, two services, one trace id",
        w_s_metrics="The metrics, as Prometheus reads them",
        w_s_health="Health and readiness, with the database up",
        w_s_down="The database stops",
    ),
    "ar": dict(
        w_kit="عدة الروبوت",
        w_c_json="كائن JSON واحد في كل سطر: تستطيع الآلات البحث فيه، ويستطيع الناس قراءته",
        w_c_trace="رقم التتبع يأتي من ترويسة traceparent عند المنادي، أو يبدأ هنا",
        w_c_short="المفيد وحده: الطريقة والعنوان، لا كل ترويسة",
        w_c_count="الطلبات بالمسار والحالة، وكم استغرقت، ليجمعها Prometheus",
        w_c_route="نمط المسار، لا العنوان: /products/1 و/products/2 سلسلة واحدة",
        w_c_call="الخدمة التالية تأخذ رقم التتبع نفسه، فتنضم سجلاتها إلى سجلات هذا الطلب",
        w_c_health="حي: العملية تجيب (أعد تشغيلها إن لم تجب)",
        w_c_ready="جاهز: يستطيع أداء عمله، فأرسل إليه الزيارات (وتوقف إن لم يكن)",
        w_c_redis="PHP تنسى كل شيء بعد كل طلب: العدادات تعيش في Redis",
        w_c_after="بعد إرسال الرد: عُدّه، دون أن يُجعل العميل ينتظر",
        w_c_hide="يأخذ العميل عنواناً ورقم التتبع ليذكره؛ والتفاصيل تذهب إلى السجل",
        w_c_pool="انقطاع اتصال بقاعدة البيانات يُسجَّل، ولا يُسمح له بإسقاط العملية",
        w_m_checkout="checkout started", w_m_stock="stock checked", w_m_done="checkout done",
        w_m_fail="payment provider timed out",
        w_s_requests="بضعة طلبات، أحدها برقم تتبع خاص به",
        w_s_logs="ما كتبه الخادم",
        w_s_error="طلب يفشل",
        w_s_trace="عملية دفع واحدة، وخدمتان، ورقم تتبع واحد",
        w_s_metrics="المقاييس، كما يقرؤها Prometheus",
        w_s_health="الحياة والجاهزية، وقاعدة البيانات تعمل",
        w_s_down="قاعدة البيانات تتوقف",
    ),
}

SCHEMA = '''CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL, price integer NOT NULL,
  stock integer NOT NULL);
INSERT INTO products VALUES (1, '{w_kit}', 45000, 3);
'''

FILES = {
    "schema.sql": SCHEMA,
    "node/server.ts": '''import { randomBytes } from "node:crypto";
import Fastify from "fastify";
import pg from "pg";
import client from "prom-client";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));
const db = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });
const port = Number(process.env.PORT ?? 3000);
const hex = (bytes: number) => randomBytes(bytes).toString("hex");
const round = (ms: unknown) => (typeof ms === "number" ? Math.round(ms * 100) / 100 : undefined);
// the file and line where the error was thrown, without the whole stack
const where = (err: Error) => /([^/\\s]+:\\d+):\\d+\\)?$/m.exec(err.stack ?? "")?.[1];

const app = Fastify({
  // {w_c_json}
  logger: {
    base: { service: `shop:${port}` },
    timestamp: () => `,"time":"${new Date().toISOString().slice(11, 23)}"`,
    formatters: {
      level: (label) => ({ level: label }),
      log: (line) => ({ ...line, responseTime: round(line.responseTime) }),
    },
    // {w_c_short}
    serializers: {
      req: (req) => ({ method: req.method, url: req.url }),
      res: (res) => ({ status: res.statusCode }),
      err: (err) => ({ type: err.name, message: err.message, at: where(err) }),
    },
  },
  // {w_c_trace}
  genReqId: (req) => String(req.headers.traceparent ?? "").split("-")[1] ?? hex(16),
});

// {w_c_count}
const requests = new client.Counter({
  name: "http_requests_total",
  help: "Requests by route and status",
  labelNames: ["method", "route", "status"],
});
const duration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "How long requests took",
  labelNames: ["route"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1],
});
app.addHook("onResponse", async (request, reply) => {
  // {w_c_route}
  const route = request.routeOptions.url ?? "unknown";
  if (["/health", "/ready", "/metrics"].includes(route)) return;
  requests.inc({ method: request.method, route, status: reply.statusCode });
  duration.observe({ route }, reply.elapsedTime / 1000);
});

app.get<{ Params: { id: string } }>("/products/:id", async (request, reply) => {
  const { rows } = await db.query("SELECT id, name, price FROM products WHERE id = $1", [
    request.params.id,
  ]);
  return rows[0] ?? reply.code(404).send({ title: "Not found" });
});

app.get<{ Params: { id: string } }>("/stock/:id", async (request) => {
  const { rows } = await db.query("SELECT stock FROM products WHERE id = $1", [
    request.params.id,
  ]);
  return { stock: rows[0]?.stock ?? 0 };
});

app.get("/checkout", async (request) => {
  request.log.info("{w_m_checkout}");
  // {w_c_call}
  const res = await fetch(`http://localhost:${process.env.STOCK_PORT}/stock/1`, {
    headers: { traceparent: `00-${request.id}-${hex(8)}-01` },
  });
  const { stock } = (await res.json()) as { stock: number };
  request.log.info({ stock }, "{w_m_stock}");
  return { ok: stock > 0 };
});

app.get("/boom", async () => {
  throw new Error("{w_m_fail}");
});

// {w_c_hide}
app.setErrorHandler((err, request, reply) => {
  request.log.error({ err }, err.message);
  return reply.code(500).send({ title: "Server error", trace: request.id });
});

// {w_c_pool}
db.on("error", (err) => app.log.warn({ err }, "database connection lost"));

// {w_c_health}
app.get("/health", { logLevel: "silent" }, async () => ({ status: "ok" }));
// {w_c_ready}
app.get("/ready", { logLevel: "silent" }, async (request, reply) => {
  try {
    await db.query({ text: "SELECT 1", query_timeout: 1000 });
    return { status: "ready" };
  } catch {
    return reply.code(503).send({ status: "database unavailable" });
  }
});

app.get("/metrics", { logLevel: "silent" }, async (_request, reply) =>
  reply.type(client.register.contentType).send(await client.register.metrics()),
);

await app.listen({ port });
''',
    "php/composer.json": '''{
    "require": {
        "monolog/monolog": "3.13.0",
        "predis/predis": "3.7.1"
    }
}
''',
    "php/router.php": r'''<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

use Monolog\Formatter\FormatterInterface;
use Monolog\Handler\StreamHandler;
use Monolog\Level;
use Monolog\Logger;
use Monolog\LogRecord;

// {w_c_json}
final class JsonLines implements FormatterInterface
{
    public function format(LogRecord $record): string
    {
        $line = ['time' => $record->datetime->format('H:i:s.v'),
            'level' => strtolower($record->level->name)] + $record->extra
            + ['msg' => $record->message] + $record->context;

        return json_encode($line, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)."\n";
    }

    public function formatBatch(array $records): string
    {
        return implode('', array_map($this->format(...), $records));
    }
}

$start = hrtime(true);
$port = (int) $_SERVER['SERVER_PORT'];
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// {w_c_trace}
$trace = explode('-', $_SERVER['HTTP_TRACEPARENT'] ?? '')[1] ?? bin2hex(random_bytes(16));

$handler = new StreamHandler('php://stderr', Level::Info);
$handler->setFormatter(new JsonLines);
$log = new Logger('shop', [$handler]);
$log->pushProcessor(fn (LogRecord $r) => $r->with(extra: ['service' => "shop:$port", 'trace' => $trace]));

$db = fn () => new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 1,
]);
$redis = new Predis\Client('tcp://localhost:6379');

function reply(int $status, array $body): void
{
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($body, JSON_UNESCAPED_UNICODE);
}

$quiet = in_array($path, ['/health', '/ready', '/metrics'], true);
$route = $path;
if (! $quiet) {
    // {w_c_short}
    $log->info('incoming request', ['req' => ['method' => $method, 'url' => $_SERVER['REQUEST_URI']]]);
}

try {
    if (preg_match('#^/products/(\d+)$#', $path, $m)) {
        $route = '/products/:id';
        $query = $db()->prepare('SELECT id, name, price FROM products WHERE id = ?');
        $query->execute([$m[1]]);
        $product = $query->fetch(PDO::FETCH_ASSOC);
        $product ? reply(200, $product) : reply(404, ['title' => 'Not found']);
    } elseif (preg_match('#^/stock/(\d+)$#', $path, $m)) {
        $route = '/stock/:id';
        $query = $db()->prepare('SELECT stock FROM products WHERE id = ?');
        $query->execute([$m[1]]);
        reply(200, ['stock' => (int) $query->fetchColumn()]);
    } elseif ($path === '/checkout') {
        $log->info('{w_m_checkout}');
        // {w_c_call}
        $span = bin2hex(random_bytes(8));
        $context = stream_context_create(['http' => ['header' => "traceparent: 00-$trace-$span-01"]]);
        $stock = json_decode(file_get_contents('http://localhost:8001/stock/1', false, $context), true)['stock'];
        $log->info('{w_m_stock}', ['stock' => $stock]);
        reply(200, ['ok' => $stock > 0]);
    } elseif ($path === '/boom') {
        throw new RuntimeException('{w_m_fail}');
    } elseif ($path === '/health') {
        // {w_c_health}
        reply(200, ['status' => 'ok']);
    } elseif ($path === '/ready') {
        // {w_c_ready}
        try {
            $db()->query('SELECT 1');
            reply(200, ['status' => 'ready']);
        } catch (PDOException) {
            reply(503, ['status' => 'database unavailable']);
        }
    } elseif ($path === '/metrics') {
        header('Content-Type: text/plain; version=0.0.4');
        echo metrics($redis);
    } else {
        reply(404, ['title' => 'Not found']);
    }
} catch (Throwable $e) {
    $log->error($e->getMessage(), ['err' => ['type' => $e::class, 'at' => basename($e->getFile()).':'.$e->getLine()]]);
    reply(500, ['title' => 'Server error', 'trace' => $trace]);
}

if (! $quiet) {
    $ms = (hrtime(true) - $start) / 1e6;
    $log->info('request completed', ['res' => ['status' => http_response_code()], 'responseTime' => round($ms, 2)]);
}

// {w_c_after}
register_shutdown_function(function () use ($redis, $method, $route, $start, $quiet) {
    if ($quiet) {
        return;
    }
    // {w_c_redis}
    $seconds = (hrtime(true) - $start) / 1e9;
    $redis->hincrby('metrics:requests', "$method $route ".http_response_code(), 1);
    foreach ([0.01, 0.05, 0.1, 0.5, 1, '+Inf'] as $le) {
        if ($le === '+Inf' || $seconds <= $le) {
            $redis->hincrby('metrics:duration', "$route $le", 1);
        }
    }
    $redis->hincrbyfloat('metrics:duration', "$route sum", $seconds);
});

function metrics(Predis\Client $redis): string
{
    $out = "# HELP http_requests_total Requests by route and status\n# TYPE http_requests_total counter\n";
    foreach ($redis->hgetall('metrics:requests') as $key => $count) {
        [$method, $route, $status] = explode(' ', $key);
        $out .= "http_requests_total{method=\"$method\",route=\"$route\",status=\"$status\"} $count\n";
    }
    $out .= "# HELP http_request_duration_seconds How long requests took\n";
    $out .= "# TYPE http_request_duration_seconds histogram\n";
    $fields = $redis->hgetall('metrics:duration');
    $order = function (string $key) {
        [$route, $le] = explode(' ', $key);

        return [$route, $le === 'sum', $le === '+Inf' ? INF : (float) $le];
    };
    uksort($fields, fn ($a, $b) => $order($a) <=> $order($b));
    foreach ($fields as $key => $value) {
        [$route, $le] = explode(' ', $key);
        $out .= $le === 'sum'
            ? "http_request_duration_seconds_sum{route=\"$route\"} $value\n"
            : "http_request_duration_seconds_bucket{route=\"$route\",le=\"$le\"} $value\n";
    }

    return $out;
}
''',
}


def logs(server):
    """The JSON lines the server wrote (PHP's built-in server adds its own lines, without JSON)."""
    out = []
    for line in server.log().split("\n"):
        line = line.strip()
        if line.startswith("{"):
            out.append(line)
    return "\n".join(out)


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    subprocess.run(["redis-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.run("psql shop -q -f schema.sql")
    s.run("cd php && composer install -q --no-progress 2>&1")
    s.lines.clear()
    for ed, port, cmd, stock in (("node", 3000, "STOCK_PORT=3001 node node/server.ts", "PORT=3001 node node/server.ts"),
                                  ("php", 8000, "php -S localhost:8000 php/router.php",
                                   "php -S localhost:8001 php/router.php")):
        shown = cmd.split(" node/")[0].replace("STOCK_PORT=3001 ", "") + (" node/server.ts" if ed == "node" else "")
        with Server(cmd, folder, f"http://localhost:{port}/health") as main, \
                Server(stock, folder, f"http://localhost:{port + 1}/health") as other:
            base = f"localhost:{port}"
            s.note(t["w_s_requests"])
            s.run(f"curl -s {base}/products/1 | jq -c")
            s.run(f"curl -s {base}/products/9 | jq -c")
            s.run(f"curl -s {base}/products/1 -H 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01' "
                  "| jq -c")
            s.save(folder / f"{ed}-requests.sh")
            s.add("$ " + (shown if ed == "php" else "node node/server.ts"))
            s.add(logs(main))
            s.save(folder / f"{ed}-logs.sh")
            main.skip = len(main.out.read_bytes())
            main.head = other.head = ""

            s.note(t["w_s_error"])
            s.run(f"curl -s {base}/boom | jq -c")
            s.add(logs(main))
            s.save(folder / f"{ed}-error.sh")
            main.skip = len(main.out.read_bytes())

            s.note(t["w_s_trace"])
            s.run(f"curl -s {base}/checkout | jq -c")
            joined = sorted((logs(main) + "\n" + logs(other)).strip().split("\n"),
                            key=lambda line: json.loads(line)["time"])
            s.add("\n".join(joined))
            s.save(folder / f"{ed}-trace.sh")

            s.note(t["w_s_metrics"])
            s.run(f"curl -s {base}/metrics | grep -E '^http_requests_total|duration_seconds_(bucket|sum).*products'")
            s.save(folder / f"{ed}-metrics.sh")

            s.note(t["w_s_health"])
            s.run(f"curl -s -w ' %{{http_code}}\\n' {base}/health")
            s.run(f"curl -s -w ' %{{http_code}}\\n' {base}/ready")
            s.note(t["w_s_down"])
            s.run("docker stop b3-pg > /dev/null", shown="docker stop b3-pg")
            s.run(f"curl -s -w ' %{{http_code}}\\n' {base}/health")
            s.run(f"curl -s -w ' %{{http_code}}\\n' {base}/ready")
            s.save(folder / f"{ed}-health.sh")
            subprocess.run(["pg-start"], env=CLEAN, check=True)
            subprocess.run(["psql", "shop", "-q", "-f", "schema.sql"], cwd=folder, env=CLEAN, capture_output=True)
        subprocess.run(["redis-cli", "DEL", "metrics:requests", "metrics:duration"], env=CLEAN, capture_output=True)


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B3 / "node_modules", folder / "node_modules")
    subprocess.run(["npx", "prettier", "--print-width", "84", "--write", "node"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    shutil.rmtree(folder / "php" / "vendor")
    print("wrote", lang)
