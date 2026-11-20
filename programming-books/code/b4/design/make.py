"""Writes the examples of Book 4, chapter "System Design Fundamentals", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4; PostgreSQL through code/b3/bin/pg-start)

Numbers measured on the machine that built the book, not copied from a table:
- latency.ts times common operations, from a Map lookup to a password hash;
- queue.ts is a server whose every request costs 10 ms of CPU; load.ts drives it with more and more
  concurrent clients, showing that throughput stays flat while latency grows (Little's law);
- balancer.ts is a round-robin reverse proxy: the same load against one, two and three copies.
Each language's run measures again, so its numbers differ slightly. Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_op="operation", w_median="median",
        w_l_map="look up a key in a Map", w_l_json="parse 1 KB of JSON", w_l_sha="SHA-256 of 1 KB",
        w_l_read="read 4 KB from a cached file", w_l_http="HTTP request to localhost",
        w_l_pg="PostgreSQL SELECT 1 (localhost)", w_l_fsync="write 4 KB and fsync to disk",
        w_l_scrypt="hash a password with scrypt",
        w_c_measure="run each operation many times and keep the median: one run proves nothing",
        w_c_busy="10 ms of work on the CPU: one request at a time, as a single Node.js process does",
        w_c_rr="round robin: each request to the next copy, in turn",
        w_c_keep="keep connections to the copies open, as real load balancers do",
        w_c_load="the same load at each concurrency: 5 seconds, then throughput and latency",
        w_t_clients="clients", w_t_rps="requests/s", w_t_p50="p50 ms", w_t_p99="p99 ms",
        w_s_latency="How long things take, on this machine", w_s_queue="One copy, more and more clients",
        w_s_scale="The same 16 clients, through a load balancer",
        w_s_one="one copy", w_s_two="two copies", w_s_three="three copies",
    ),
    "ar": dict(
        w_op="العملية", w_median="الوسيط",
        w_l_map="البحث عن مفتاح في Map", w_l_json="تحليل 1 KB من JSON", w_l_sha="SHA-256 لـ 1 KB",
        w_l_read="قراءة 4 KB من ملف في الذاكرة المؤقتة", w_l_http="طلب HTTP إلى localhost",
        w_l_pg="SELECT 1 في PostgreSQL (localhost)", w_l_fsync="كتابة 4 KB وfsync إلى القرص",
        w_l_scrypt="بصمة كلمة مرور بـ scrypt",
        w_c_measure="شغّل كل عملية مرات كثيرة واحتفظ بالوسيط: تشغيل واحد لا يثبت شيئاً",
        w_c_busy="10 ms من العمل على المعالج: طلب واحد في كل مرة، كما تفعل عملية Node.js واحدة",
        w_c_rr="التناوب الدائري: كل طلب إلى النسخة التالية، بالدور",
        w_c_keep="أبقِ الاتصالات بالنسخ مفتوحة، كما تفعل موزّعات الحمل الحقيقية",
        w_c_load="الحمل نفسه عند كل مستوى تزامن: 5 ثوانٍ، ثم الإنتاجية وزمن الاستجابة",
        w_t_clients="العملاء", w_t_rps="طلب/ث", w_t_p50="p50 ms", w_t_p99="p99 ms",
        w_s_latency="كم تستغرق الأشياء، على هذه الآلة", w_s_queue="نسخة واحدة، وعملاء يزيدون",
        w_s_scale="العملاء الستة عشر أنفسهم، عبر موزّع حمل",
        w_s_one="نسخة واحدة", w_s_two="نسختان", w_s_three="ثلاث نسخ",
    ),
}

FILES = {
    ".env": "DATABASE_URL=postgres://bit:secret@localhost:5432/shop\n",
    "latency.ts": '''import { createHash, scryptSync } from "node:crypto";
import { closeSync, fsyncSync, openSync, readFileSync, writeFileSync, writeSync } from "node:fs";
import { createServer } from "node:http";
import pg from "pg";

// {w_c_measure}
async function median(times: number, work: () => unknown) {
  const runs: number[] = [];
  for (let i = 0; i < times; i++) {
    const start = process.hrtime.bigint();
    await work();
    runs.push(Number(process.hrtime.bigint() - start));
  }
  return runs.sort((a, b) => a - b)[Math.floor(runs.length / 2)]!;
}

const show = (ns: number) =>
  ns < 1_000 ? `${ns} ns` : ns < 1_000_000 ? `${(ns / 1_000).toFixed(1)} µs` : `${(ns / 1_000_000).toFixed(1)} ms`;

const map = new Map(Array.from({ length: 100_000 }, (_, i) => [`key${i}`, i]));
const json = JSON.stringify(Array.from({ length: 20 }, (_, i) => ({ id: i, name: `item ${i}` })));
const kb = Buffer.alloc(1024, 7);
writeFileSync("data.bin", Buffer.alloc(4096, 1));
readFileSync("data.bin");
const server = createServer((_req, res) => res.end("ok")).listen(4100);
const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();

const rows: [string, number][] = [
  ["{w_l_map}", await median(100_000, () => map.get("key5000"))],
  ["{w_l_json}", await median(10_000, () => JSON.parse(json))],
  ["{w_l_sha}", await median(10_000, () => createHash("sha256").update(kb).digest())],
  ["{w_l_read}", await median(10_000, () => readFileSync("data.bin"))],
  ["{w_l_http}", await median(1_000, () => fetch("http://localhost:4100").then((r) => r.text()))],
  ["{w_l_pg}", await median(1_000, () => db.query("SELECT 1"))],
  ["{w_l_fsync}", await median(200, () => {
    const fd = openSync("data.bin", "w");
    writeSync(fd, kb);
    fsyncSync(fd);
    closeSync(fd);
  })],
  ["{w_l_scrypt}", await median(20, () => scryptSync("a long password", "salt", 32, { N: 2 ** 15, maxmem: 64 * 1024 * 1024 }))],
];

console.log("{w_op}".padEnd(38), "{w_median}");
for (const [name, ns] of rows) console.log(name.padEnd(38), show(ns));
server.close();
await db.end();
''',
    "queue.ts": '''import { createServer } from "node:http";

const work = Number(process.env.WORK_MS ?? 10);
const port = Number(process.env.PORT ?? 3000);

// {w_c_busy}
function busy(ms: number) {
  const end = performance.now() + ms;
  while (performance.now() < end);
}

createServer((_request, response) => {
  busy(work);
  response.end("ok");
}).listen(port);
''',
    "balancer.ts": '''import { Agent, createServer, request } from "node:http";

const ports = process.argv.slice(2).map(Number);
// {w_c_keep}
const agent = new Agent({ keepAlive: true });
let next = 0;

createServer((incoming, outgoing) => {
  // {w_c_rr}
  const port = ports[next++ % ports.length];
  const upstream = request(
    { host: "127.0.0.1", port, path: incoming.url, method: incoming.method, headers: incoming.headers, agent },
    (answer) => {
      outgoing.writeHead(answer.statusCode ?? 502, answer.headers);
      answer.pipe(outgoing);
    },
  );
  upstream.on("error", () => outgoing.writeHead(502).end());
  incoming.pipe(upstream);
}).listen(3000);
''',
    "load.ts": '''import autocannon from "autocannon";

const [url, ...levels] = process.argv.slice(2);
console.log(
  "{w_t_clients}".padEnd(9), "{w_t_rps}".padStart(11), "{w_t_p50}".padStart(8), "{w_t_p99}".padStart(8),
);
// {w_c_load}
for (const connections of levels.map(Number)) {
  const result = await autocannon({ url: url!, connections, duration: 5 });
  console.log(
    String(connections).padEnd(9),
    String(Math.round(result.requests.average)).padStart(11),
    String(result.latency.p50).padStart(8),
    String(result.latency.p99).padStart(8),
  );
}
''',
}


def record(folder, t):
    subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
    s = Session(folder)
    s.note(t["w_s_latency"])
    s.run("node --env-file=.env latency.ts")
    s.save(folder / "latency.sh")

    with Server("node queue.ts", folder, "http://localhost:3000/"):
        s.note(t["w_s_queue"])
        s.run("node load.ts http://localhost:3000 1 4 16 64", timeout=120)
        s.save(folder / "queue.sh")

    s.note(t["w_s_scale"])
    for label, ports in ((t["w_s_one"], [3001]), (t["w_s_two"], [3001, 3002]),
                         (t["w_s_three"], [3001, 3002, 3003])):
        copies = " & ".join(f"PORT={p} node queue.ts" for p in ports)
        procs = [subprocess.Popen(["node", "queue.ts"], cwd=folder, env=dict(CLEAN, PORT=str(p)),
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for p in ports]
        time.sleep(1)
        command = "node balancer.ts " + " ".join(map(str, ports))
        with Server(command, folder, "http://localhost:3000/"):
            s.note(label)
            s.add(f"$ {copies} &")
            s.add(f"$ {command} &")
            s.run("node load.ts http://localhost:3000 16", timeout=60)
        for p in procs:
            p.terminate()
            p.wait()
    s.save(folder / "scale.sh")


import rec  # noqa: E402

_run = Session.run


def run(self, cmd, shown=None, check=True, timeout=60):
    """Session.run, with a longer time limit for load tests."""
    r = subprocess.run(["bash", "-c", cmd], cwd=self.cwd, capture_output=True, text=True, timeout=timeout,
                       env=CLEAN)
    out = (r.stdout + r.stderr).replace("\r", "").rstrip("\n")
    if check and r.returncode:
        raise RuntimeError(f"{cmd} failed ({r.returncode}):\n{out}")
    self.lines.append("$ " + (shown or cmd))
    if out:
        self.lines.extend(out.split("\n"))
    return out


Session.run = run

for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    os.symlink(B4 / "node_modules", folder / "node_modules")
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "latency.ts",
                    "queue.ts", "balancer.ts", "load.ts"], cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    (folder / "data.bin").unlink(missing_ok=True)
    (folder / ".env").rename(folder / ".env.example")
    print("wrote", lang)
