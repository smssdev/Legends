"""Writes the examples of Book 4, chapter "CI/CD Pipelines", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4; uses the contracts example of Chapter 2)

- ci.sh is the pipeline: the same commands a CI service runs, in order, stopping at the first failure. It
  runs on Chapter 2's contract project: type check, contract tests, and the breaking-change check against the
  contract on the main branch. Recorded once green, and once with a breaking change in the contract.
  .github/workflows/ci.yml runs the same script on every push and pull request (shown, not run here).
- server.ts (a version that takes a second to start, and finishes requests in flight on SIGTERM),
  balancer.ts (round robin over a pool changed through /admin) and load.ts (8 clients, a line per second)
  measure two deployments from v1 to v2 under load: restarting in place, and a rolling deploy.
Transcripts are *.sh.
"""
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_stop="stop at the first failing step, and say which",
        w_c_base="the contract on main: what clients use today",
        w_c_boot="a real server needs time to start: connections, caches, compiled code",
        w_c_ready="ready only when it can serve; the balancer asks before sending traffic",
        w_c_drain="SIGTERM: stop accepting, finish what is in flight, then exit",
        w_c_close="while stopping, tell clients not to reuse the connection, or they keep it alive forever",
        w_c_admin="the deploy tool adds and removes copies; the balancer never restarts",
        w_c_line="one line a second: answered, failed, and which versions answered",
        w_c_push="every push and pull request runs the same pipeline as a developer's machine",
        w_c_image="only main builds the image, tagged with the commit it came from",
        w_c_deploy="production waits for a person to approve, in the environment's settings",
        w_t_second="second", w_t_ok="ok", w_t_failed="failed", w_t_versions="versions",
        w_p_types="type check", w_p_tests="contract tests", w_p_breaking="breaking changes",
        w_p_passed="pipeline passed", w_p_failed="pipeline failed at",
        w_s_green="The pipeline on a clean change", w_s_red="The same pipeline, after someone removes ends_at",
        w_s_naive="Deploy v2 by restarting in place, under load",
        w_s_rolling="Deploy v2 as a rolling update, under load",
    ),
    "ar": dict(
        w_c_stop="توقف عند أول خطوة تفشل، وقل أيها",
        w_c_base="العقد على main: ما يستعمله العملاء اليوم",
        w_c_boot="الخادم الحقيقي يحتاج وقتاً ليبدأ: اتصالات، وذاكرات مؤقتة، وكود يُترجم",
        w_c_ready="جاهز فقط حين يستطيع الخدمة؛ والموزّع يسأل قبل أن يرسل الحركة",
        w_c_drain="SIGTERM: توقف عن القبول، وأنهِ ما يجري، ثم اخرج",
        w_c_close="أثناء التوقف، قل للعملاء ألا يعيدوا استعمال الاتصال، وإلا أبقوه حياً إلى الأبد",
        w_c_admin="أداة النشر تضيف النسخ وتحذفها؛ والموزّع لا يُعاد تشغيله أبداً",
        w_c_line="سطر كل ثانية: ما أُجيب، وما فشل، وأي النسخ أجابت",
        w_c_push="كل دفع وطلب سحب يشغّل الخط نفسه الذي على جهاز المطوّر",
        w_c_image="main وحده يبني الصورة، موسومة بالـ commit الذي جاءت منه",
        w_c_deploy="الإنتاج ينتظر موافقة شخص، في إعدادات البيئة",
        w_t_second="الثانية", w_t_ok="نجح", w_t_failed="فشل", w_t_versions="النسخ",
        w_p_types="فحص الأنواع", w_p_tests="اختبارات العقد", w_p_breaking="التغييرات الكاسرة",
        w_p_passed="نجح الخط", w_p_failed="فشل الخط عند",
        w_s_green="الخط على تغيير سليم", w_s_red="الخط نفسه، بعد أن يحذف أحدهم ends_at",
        w_s_naive="انشر v2 بإعادة التشغيل في المكان، تحت الحمل",
        w_s_rolling="انشر v2 تحديثاً متدرجاً، تحت الحمل",
    ),
}

FILES = {
    "ci.sh": '''#!/bin/sh
# {w_c_stop}
set -e
step() {
  printf '%s: ' "$1"
  shift
  if out=$("$@" 2>&1); then echo "ok"; else echo "FAILED"; echo "$out" | tail -4; echo "{w_p_failed}: $STEP"; exit 1; fi
}
STEP="{w_p_types}";    step "$STEP" npx tsc
STEP="{w_p_tests}";    step "$STEP" node --test
# {w_c_base}
git show main:openapi.yaml > /tmp/openapi.main.yaml
STEP="{w_p_breaking}"; step "$STEP" node breaking.ts /tmp/openapi.main.yaml openapi.yaml
echo "{w_p_passed}"
''',
    ".github/workflows/ci.yml": '''name: ci

# {w_c_push}
on:
  push:
  pull_request:

jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v5
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: sh ci.sh

  image:
    # {w_c_image}
    if: github.ref == 'refs/heads/main'
    needs: check
    runs-on: ubuntu-24.04
    permissions:
      packages: write
    steps:
      - uses: actions/checkout@v5
      - run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
      - run: docker build -t ghcr.io/${{ github.repository }}:${{ github.sha }} .
      - run: docker push ghcr.io/${{ github.repository }}:${{ github.sha }}

  deploy:
    needs: image
    runs-on: ubuntu-24.04
    # {w_c_deploy}
    environment: production
    steps:
      - run: ./deploy.sh ${{ github.sha }}
''',
    "server.ts": '''import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";

const version = process.env.VERSION ?? "v1";
let ready = false;
let stopping = false;

const server = createServer(async (request, response) => {
  // {w_c_ready}
  if (request.url === "/ready") return response.writeHead(ready ? 200 : 503).end();
  // {w_c_close}
  if (stopping) response.setHeader("connection", "close");
  await sleep(20);
  response.end(version);
});
server.listen(Number(process.env.PORT));

// {w_c_boot}
await sleep(1000);
ready = true;

// {w_c_drain}
process.on("SIGTERM", () => {
  ready = false;
  stopping = true;
  server.close(() => process.exit(0));
  server.closeIdleConnections();
});
''',
    "balancer.ts": '''import { Agent, createServer, request } from "node:http";

const agent = new Agent({ keepAlive: true });
let pool = process.argv.slice(2).map(Number);
let next = 0;

createServer((incoming, outgoing) => {
  const url = new URL(incoming.url ?? "/", "http://x");
  // {w_c_admin}
  if (url.pathname === "/admin/pool") {
    pool = (url.searchParams.get("ports") ?? "").split(",").filter(Boolean).map(Number);
    return outgoing.end(pool.join(","));
  }
  const port = pool[next++ % pool.length];
  const upstream = request({ host: "127.0.0.1", port, path: incoming.url, agent }, (answer) => {
    outgoing.writeHead(answer.statusCode ?? 502);
    answer.pipe(outgoing);
  });
  upstream.on("error", () => outgoing.writeHead(502).end());
  upstream.end();
}).listen(3000);
''',
    "load.ts": '''const seconds = Number(process.argv[2] ?? 8);
const stats = Array.from({ length: seconds }, () => ({ ok: 0, failed: 0, versions: new Set<string>() }));
const start = Date.now();

async function client() {
  for (;;) {
    const second = Math.floor((Date.now() - start) / 1000);
    if (second >= seconds) return;
    const row = stats[second]!;
    try {
      const response = await fetch("http://localhost:3000/");
      const body = await response.text();
      if (response.ok) {
        row.ok++;
        row.versions.add(body);
      } else row.failed++;
    } catch {
      row.failed++;
    }
  }
}

await Promise.all(Array.from({ length: 8 }, client));
// {w_c_line}
console.log("{w_t_second}".padEnd(8), "{w_t_ok}".padStart(5), "{w_t_failed}".padStart(7), " {w_t_versions}");
stats.forEach((s, i) =>
  console.log(String(i + 1).padEnd(8), String(s.ok).padStart(5), String(s.failed).padStart(7), "", [...s.versions].sort().join(" ")),
);
''',
}


def start(cmd, folder, env=None):
    return subprocess.Popen(cmd, shell=True, cwd=folder, env=dict(CLEAN, **(env or {})),
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def stop(proc, sig=signal.SIGTERM):
    try:
        os.killpg(proc.pid, sig)
    except ProcessLookupError:
        pass
    proc.wait()


def wait_ready(port):
    for _ in range(100):
        r = subprocess.run(["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", f"localhost:{port}/ready"],
                           capture_output=True, text=True, env=CLEAN)
        if r.stdout == "200":
            return
        time.sleep(0.1)
    raise RuntimeError(f"port {port} never became ready")


def deploy(folder, t, rolling):
    """Runs the load for 8 seconds; at second 2, deploys v2. Returns the transcript lines of the steps."""
    v1 = start("node server.ts", folder, {"VERSION": "v1", "PORT": "3001"})
    wait_ready(3001)
    balancer = start("node balancer.ts 3001", folder)
    time.sleep(0.5)
    load = subprocess.Popen(["node", "load.ts", "8"], cwd=folder, env=CLEAN, stdout=subprocess.PIPE, text=True)
    time.sleep(2)
    steps = []
    if not rolling:
        steps += ["$ kill -TERM $V1", "$ VERSION=v2 PORT=3001 node server.ts &"]
        stop(v1)
        v2 = start("node server.ts", folder, {"VERSION": "v2", "PORT": "3001"})
    else:
        steps += ["$ VERSION=v2 PORT=3002 node server.ts &",
                  "$ until curl -sf localhost:3002/ready; do sleep 0.1; done",
                  "$ curl -s 'localhost:3000/admin/pool?ports=3001,3002'",
                  "$ curl -s 'localhost:3000/admin/pool?ports=3002'",
                  "$ kill -TERM $V1"]
        v2 = start("node server.ts", folder, {"VERSION": "v2", "PORT": "3002"})
        wait_ready(3002)
        subprocess.run(["curl", "-s", "localhost:3000/admin/pool?ports=3001,3002"], capture_output=True, env=CLEAN)
        time.sleep(1.5)
        subprocess.run(["curl", "-s", "localhost:3000/admin/pool?ports=3002"], capture_output=True, env=CLEAN)
        stop(v1)
    out, _ = load.communicate(timeout=60)
    for proc in (v2, balancer):
        stop(proc)
    return steps, out.rstrip("\n").split("\n")


def record(folder, t):
    s = Session(folder)
    subprocess.run("git init -q -b main && git add -A && git -c user.email=bit@example.com -c user.name=Bit "
                   "commit -qm contract", shell=True, cwd=folder, check=True)
    s.note(t["w_s_green"])
    s.run("sh ci.sh")
    s.save(folder / "green.sh")
    yaml = folder / "openapi.yaml"
    original = yaml.read_text()
    yaml.write_text(original.replace("      required: [id, staff_id, starts_at, ends_at, email, status]",
                                     "      required: [id, staff_id, starts_at, email, status]")
                    .replace("        ends_at: { type: string, format: date-time }\n        email: { type: string }",
                             "        email: { type: string }"))
    app = folder / "src/app.ts"
    app_source = app.read_text()
    head, _, tail = app_source.rpartition("        ends_at: new Date(end).toISOString(),\n")  # the booking's, not a slot's
    app.write_text((head + tail).replace("start < Date.parse(b.ends_at)",
                                         "start < Date.parse(b.starts_at) + MINUTES * 60_000"))
    subprocess.run("npm run --silent types > /dev/null 2>&1", shell=True, cwd=folder, env=CLEAN, check=True)
    s.note(t["w_s_red"])
    s.run("sh ci.sh; echo \"exit code: $?\"", check=False)
    s.save(folder / "red.sh")
    yaml.write_text(original)
    app.write_text(app_source)
    subprocess.run("npm run --silent types > /dev/null 2>&1", shell=True, cwd=folder, env=CLEAN, check=True)
    shutil.rmtree(folder / ".git")

    for name, rolling in (("naive", False), ("rolling", True)):
        steps, table = deploy(folder, t, rolling)
        s.note(t["w_s_rolling" if rolling else "w_s_naive"])
        s.add("$ node load.ts 8 &   # 8 clients for 8 seconds; at second 2:")
        s.add("\n".join(steps))
        s.add("$ wait")
        s.add("\n".join(table))
        s.save(folder / f"{name}.sh")


for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    source = B4 / "contracts" / lang
    shutil.copytree(source, folder, ignore=shutil.ignore_patterns("*.sh", "openapi.next.yaml"))
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    os.symlink(B4 / "node_modules", folder / "node_modules")
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "server.ts",
                    "balancer.ts", "load.ts"], cwd=folder, check=True, capture_output=True)
    subprocess.run("npm run --silent types > /dev/null 2>&1", shell=True, cwd=folder, env=CLEAN, check=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
