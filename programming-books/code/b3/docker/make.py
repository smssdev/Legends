"""Writes the examples of Book 3, the shared chapter "Docker: Shipping the Same Thing Everywhere".
Run: python3 make.py   (Docker with Compose)

Each edition's small shop service packed into an image and run with Compose next to PostgreSQL:
node/ (a Fastify app; a multi-stage Dockerfile installing only production dependencies, running as a non-root
user, with a health check) and php/ (a PDO app on php:8.5-apache with the pdo_pgsql extension). Then the
Compose file for app and database, health checks, a one-off command, the logs, and the clean-up.

One adjustment is invisible in the transcripts: this machine reaches npm and Debian through a proxy that
re-signs HTTPS, so its builds use a copy of each Dockerfile with that proxy's certificate added. The
Dockerfiles in the book are the ones a reader builds, unchanged.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B3 = HERE.parent
sys.path.insert(0, str(B3))
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_kit="Robot kit", w_wheels="Spare wheels",
        w_c_deps="stage 1: the production dependencies only, from the lock file",
        w_c_cache="copied before the code: this layer is rebuilt only when the dependencies change",
        w_c_run="stage 2: the image that runs; nothing from stage 1 except node_modules",
        w_c_user="never run as root inside the container",
        w_c_health="Docker asks the app itself whether it is healthy",
        w_c_ext="the PostgreSQL driver, compiled into PHP",
        w_c_fallback="every address goes to index.php",
        w_c_init="the schema and sample data, loaded the first time the database starts",
        w_c_wait="start the app only when the database answers",
        w_c_secret="for a demo only: real passwords come from a secret store, never from this file",
        w_s_build="Build the image", w_s_size="What was built",
        w_s_up="The whole stack, with one command", w_s_ps="What is running, and is it healthy?",
        w_s_curl="The app, from the host", w_s_once="A one-off command in a new container",
        w_s_logs="The app's logs", w_s_down="Stop and remove everything",
    ),
    "ar": dict(
        w_kit="عدة الروبوت", w_wheels="عجلات احتياطية",
        w_c_deps="المرحلة 1: اعتماديات الإنتاج وحدها، من ملف القفل",
        w_c_cache="تُنسخ قبل الكود: هذه الطبقة لا يُعاد بناؤها إلا حين تتغير الاعتماديات",
        w_c_run="المرحلة 2: الصورة التي تعمل؛ لا شيء من المرحلة 1 إلا node_modules",
        w_c_user="لا تعمل بصلاحيات root داخل الحاوية أبداً",
        w_c_health="يسأل Docker التطبيق نفسه هل هو بخير",
        w_c_ext="مشغّل PostgreSQL، مترجماً داخل PHP",
        w_c_fallback="كل عنوان يذهب إلى index.php",
        w_c_init="المخطط والبيانات النموذجية، تُحمَّل أول مرة تبدأ فيها قاعدة البيانات",
        w_c_wait="لا يبدأ التطبيق إلا حين تجيب قاعدة البيانات",
        w_c_secret="للعرض فقط: كلمات المرور الحقيقية تأتي من مخزن أسرار، لا من هذا الملف أبداً",
        w_s_build="ابنِ الصورة", w_s_size="ما الذي بُني",
        w_s_up="المنظومة كلها، بأمر واحد", w_s_ps="ما الذي يعمل، وهل هو بخير؟",
        w_s_curl="التطبيق، من الجهاز المضيف", w_s_once="أمر لمرة واحدة في حاوية جديدة",
        w_s_logs="سجلات التطبيق", w_s_down="أوقف كل شيء واحذفه",
    ),
}

SCHEMA = '''-- {w_c_init}
CREATE TABLE products (id bigint PRIMARY KEY, name text NOT NULL, price integer NOT NULL);
INSERT INTO products VALUES (1, '{w_kit}', 45000), (2, '{w_wheels}', 6000);
'''

COMPOSE = '''name: shop

services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: shop
      # {w_c_secret}
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: shop
    volumes:
      - db-data:/var/lib/postgresql
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "shop", "-d", "shop"]
      interval: 2s
      retries: 15

  app:
    build: .
    image: {image}
    ports:
      - "{port}"
    environment:
      DATABASE_URL: {url}
    depends_on:
      db:
        # {w_c_wait}
        condition: service_healthy

volumes:
  db-data:
'''

FILES = {
    "node/schema.sql": SCHEMA,
    "php/schema.sql": SCHEMA,
    "node/package.json": '''{
  "name": "shop",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node src/server.ts",
    "count": "node src/count.ts"
  },
  "dependencies": {
    "fastify": "5.12.8",
    "pg": "8.23.1"
  }
}
''',
    "node/src/server.ts": '''import Fastify from "fastify";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));
const db = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const app = Fastify({ logger: true });

app.get("/health", async () => ({ status: "ok" }));
app.get("/products", async () => (await db.query("SELECT * FROM products ORDER BY id")).rows);

await app.listen({ host: "0.0.0.0", port: Number(process.env.PORT ?? 3000) });
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
''',
    "node/src/count.ts": '''import pg from "pg";

const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();
const { rows } = await db.query("SELECT count(*)::int AS products FROM products");
console.log(rows[0]);
await db.end();
''',
    "node/.dockerignore": "node_modules\n.git\n*.log\n.env\n",
    "node/Dockerfile": '''# {w_c_deps}
FROM node:22-slim AS deps
WORKDIR /app
# {w_c_cache}
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# {w_c_run}
FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src
# {w_c_user}
USER node
EXPOSE 3000
# {w_c_health}
HEALTHCHECK --interval=5s --timeout=2s \\
  CMD node -e "fetch('http://localhost:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"
CMD ["node", "src/server.ts"]
''',
    "node/compose.yaml": COMPOSE.replace("{image}", "shop-node").replace("{port}", "3000:3000").replace(
        "{url}", "postgres://shop:secret@db:5432/shop"),
    "php/public/index.php": r'''<?php

declare(strict_types=1);

$db = new PDO(getenv('DATABASE_URL'), getenv('DATABASE_USER'), getenv('DATABASE_PASSWORD'),
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

header('Content-Type: application/json');
echo json_encode(match ($path) {
    '/health' => ['status' => 'ok'],
    '/products' => $db->query('SELECT * FROM products ORDER BY id')->fetchAll(),
    default => ['title' => 'Not found'],
}, JSON_UNESCAPED_UNICODE);
''',
    "php/bin/count.php": r'''<?php

$db = new PDO(getenv('DATABASE_URL'), getenv('DATABASE_USER'), getenv('DATABASE_PASSWORD'));
echo json_encode(['products' => (int) $db->query('SELECT count(*) FROM products')->fetchColumn()]), "\n";
''',
    "php/.dockerignore": "vendor\n.git\n*.log\n.env\n",
    "php/Dockerfile": '''FROM php:8.5-apache
# {w_c_ext}
RUN apt-get update \\
 && apt-get install -y --no-install-recommends libpq-dev \\
 && docker-php-ext-install pdo_pgsql \\
 && rm -rf /var/lib/apt/lists/*
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# {w_c_fallback}
RUN echo "FallbackResource /index.php" > /etc/apache2/conf-enabled/fallback.conf \\
 && sed -i 's#/var/www/html#/var/www/html/public#' /etc/apache2/sites-available/000-default.conf
COPY --chown=www-data:www-data . /var/www/html
# {w_c_health}
HEALTHCHECK --interval=5s --timeout=2s CMD curl -fs http://localhost/health || exit 1
''',
    "php/compose.yaml": COMPOSE.replace("{image}", "shop-php").replace("{port}", "8080:80").replace(
        "      DATABASE_URL: {url}\n",
        "      DATABASE_URL: pgsql:host=db;dbname=shop\n      DATABASE_USER: shop\n      DATABASE_PASSWORD: secret\n"),
}


def build(folder, tag):
    """Builds with the proxy's certificate added to a copy of the Dockerfile (see the docstring)."""
    shutil.copy("/root/.ccr/ca-bundle.crt", folder / ".ccr-ca.crt")
    lines = []
    for line in (folder / "Dockerfile").read_text().split("\n"):
        lines.append(line)
        if line.startswith("FROM node"):
            lines += ["COPY .ccr-ca.crt /tmp/ccr-ca.crt", "ENV NODE_EXTRA_CA_CERTS=/tmp/ccr-ca.crt"]
        elif line.startswith("FROM php"):
            # this proxy serves HTTPS only, so Debian's mirrors are read over HTTPS
            lines += ["COPY .ccr-ca.crt /usr/local/share/ca-certificates/ccr.crt", "RUN update-ca-certificates",
                      "RUN sed -i 's#http://deb.debian.org#https://deb.debian.org#g' "
                      "/etc/apt/sources.list.d/debian.sources"]
    (folder / "Dockerfile.ccr").write_text("\n".join(lines))
    proxy = os.environ.get("HTTPS_PROXY", "")
    return (f"docker build -q -f Dockerfile.ccr --network host --build-arg HTTPS_PROXY={proxy} "
            f"--build-arg https_proxy={proxy} -t {tag} . > /dev/null 2>&1 && echo built")


def record(folder, t, ed):
    app = folder / ed
    tag, port = ("shop-node", 3000) if ed == "node" else ("shop-php", 8080)
    s = Session(app)
    if ed == "node":
        subprocess.run(["npm", "install", "--package-lock-only", "--no-audit", "--no-fund", "-q"], cwd=app,
                       check=True, capture_output=True)
    s.note(t["w_s_build"])
    s.run(build(app, tag), shown=f"docker build -t {tag} .")
    s.lines[-1:] = []
    s.note(t["w_s_size"])
    s.run(f"docker image ls {tag} --format '{{{{.Repository}}}}:{{{{.Tag}}}}  {{{{.Size}}}}'")
    s.save(folder / f"{ed}-build.sh")

    s.note(t["w_s_up"])
    s.run("docker compose up -d --wait 2>&1 | grep -E '(Created|Healthy) *$' | sed -E 's/^ *//; s/ *$//' "
          "| awk '!seen[$0]++'",
          shown="docker compose up -d --wait")
    s.note(t["w_s_ps"])
    s.run("docker compose ps --format 'table {{.Service}}\\t{{.Status}}\\t{{.Ports}}'")
    s.note(t["w_s_curl"])
    s.run(f"curl -s localhost:{port}/products | jq -c")
    s.note(t["w_s_once"])
    once = "npm run --silent count" if ed == "node" else "php bin/count.php"
    s.run(f"docker compose run --rm --no-deps app {once} 2>/dev/null")
    s.note(t["w_s_logs"])
    if ed == "node":
        s.run("docker compose logs app --no-log-prefix | grep products | head -1 | jq -c '{level, msg, url: .req.url}'",
              shown="docker compose logs app")
    else:
        s.run("docker compose logs app --no-log-prefix | grep -E 'GET /products' | head -1 "
              "| sed -E 's/\\[[^]]+\\]/[…]/'", shown="docker compose logs app")
    s.note(t["w_s_down"])
    s.run("docker compose down -v 2>&1 | grep -E 'Removed' | sed -E 's/^ *//'", shown="docker compose down -v")
    s.save(folder / f"{ed}-compose.sh")
    for name in (".ccr-ca.crt", "Dockerfile.ccr"):
        (app / name).unlink(missing_ok=True)


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    for name, text in FILES.items():
        path = folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))
    for ed in ("node", "php"):
        record(folder, t, ed)
    print("wrote", lang)
