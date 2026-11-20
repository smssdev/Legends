"""Writes the examples of Book 4, chapter "Authentication Across the Stack", in English and Arabic.
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start; installs the app's packages)

Bit Booking gets accounts for owners and staff, in two businesses. Sessions are random tokens stored only as
hashes: an httpOnly cookie for the web, the same token as a bearer for the API. One function, requireUser,
guards pages, Server Actions and route handlers; every owner query is scoped to the user's business, so another
business's booking is "not found". The proxy only redirects; it is not the lock. Recorded with curl, psql and
Playwright; the app's sources are copied next to this script.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

os.environ["NEXT_TELEMETRY_DISABLED"] = "1"
HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_lang="en", w_dir="ltr", w_title="Bit Booking", w_salon="Bit Hair Studio", w_clinic="Nour Clinic",
        w_mona="Mona", w_omar="Omar", w_hana="Dr Hana",
        w_signin="Sign in", w_email="Email", w_password="Password", w_signing="Signing in…",
        w_e_login="Email or password is wrong.", w_today="Bookings", w_cancel="Cancel", w_signout="Sign out",
        w_cancelled="cancelled", w_m_unauth="Not signed in", w_m_forbidden="Not allowed", w_m_none="Not found",
        w_c_hash="only the hash of a token is stored: a stolen table opens no account",
        w_c_dummy="an unknown email still costs one hash, so timing reveals nothing",
        w_c_cookie="httpOnly: no script can read it; sameSite lax: other sites cannot send it with a form",
        w_c_who="who is calling: a bearer token (API) or the session cookie (web)",
        w_c_require="the one check every door calls: 401 for nobody, 403 for the wrong role",
        w_c_tenant="scoped to the user's business: the WHERE clause is the permission",
        w_c_cancel="another business's booking matches no row: it is \"not found\", not \"forbidden\"",
        w_c_proxy="a convenience, not the lock: send visitors without a cookie to the login page",
        w_c_page="the page checks too: the proxy can be misconfigured or bypassed",
        w_c_action="the action checks again: it is a public endpoint of its own",
        w_c_api="the same check and the same scoped function, for the mobile app",
        w_s_anon="Nobody signed in", w_s_login="The owner of Bit Hair Studio signs in through the API",
        w_s_list="Only her own business's bookings", w_s_other="A booking of Nour Clinic: not found",
        w_s_staff="Omar is staff: he may see, not cancel", w_s_owner="The owner cancels her own booking",
        w_s_rows="What the database holds", w_s_cookie="The web session's cookie, as the browser stored it",
    ),
    "ar": dict(
        w_lang="ar", w_dir="rtl", w_title="بِت للحجوزات", w_salon="صالون بِت", w_clinic="عيادة نور",
        w_mona="منى", w_omar="عمر", w_hana="د. هناء",
        w_signin="تسجيل الدخول", w_email="البريد الإلكتروني", w_password="كلمة المرور", w_signing="جارٍ الدخول…",
        w_e_login="البريد أو كلمة المرور خطأ.", w_today="الحجوزات", w_cancel="إلغاء", w_signout="خروج",
        w_cancelled="ملغى", w_m_unauth="لم تسجّل الدخول", w_m_forbidden="غير مسموح", w_m_none="غير موجود",
        w_c_hash="لا تُخزَّن إلا بصمة الرمز: جدول مسروق لا يفتح أي حساب",
        w_c_dummy="البريد المجهول يكلّف بصمة واحدة أيضاً، فلا يكشف الوقت شيئاً",
        w_c_cookie="httpOnly: لا يقرؤها أي سكربت؛ وsameSite lax: لا ترسلها المواقع الأخرى مع نموذج",
        w_c_who="من المنادي: رمز bearer (الواجهة البرمجية) أو كوكي الجلسة (الويب)",
        w_c_require="الفحص الواحد الذي يناديه كل باب: 401 لمن لا هوية له، و403 للدور الخطأ",
        w_c_tenant="محصور في عمل المستخدم: شرط WHERE هو الصلاحية",
        w_c_cancel="حجز عمل آخر لا يطابق أي صف: هو «غير موجود» لا «ممنوع»",
        w_c_proxy="راحة لا قفل: أرسل الزوار الذين بلا كوكي إلى صفحة الدخول",
        w_c_page="الصفحة تفحص أيضاً: قد يُضبط الوكيل خطأً أو يُتجاوز",
        w_c_action="الإجراء يفحص من جديد: هو نقطة نهاية عامة بذاته",
        w_c_api="الفحص نفسه والدالة المحصورة نفسها، لتطبيق الجوال",
        w_s_anon="لا أحد سجّل الدخول", w_s_login="صاحبة صالون بِت تسجّل الدخول عبر الواجهة البرمجية",
        w_s_list="حجوزات عملها هي فقط", w_s_other="حجز في عيادة نور: غير موجود",
        w_s_staff="عمر موظف: يرى ولا يلغي", w_s_owner="صاحبة العمل تلغي حجزاً لها",
        w_s_rows="ما تحفظه قاعدة البيانات", w_s_cookie="كوكي جلسة الويب، كما حفظها المتصفح",
    ),
}

NEXT = B4 / "next" / "{lang}"  # chapter 3's files, in the language being recorded

FILES = {
    "package.json": "@next:package.json",
    "next.config.ts": "@next:next.config.ts",
    "tsconfig.json": "@next:tsconfig.json",
    ".env.local": "DATABASE_URL=postgres://bit:secret@localhost:5432/shop\n",
    "schema.sql": '''CREATE EXTENSION btree_gist;
CREATE TABLE businesses (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL);
CREATE TABLE users (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses (id),
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  role text NOT NULL CHECK (role IN ('owner', 'staff'))
);
CREATE TABLE sessions (
  token_hash text PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL
);
CREATE TABLE staff (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses (id),
  name text NOT NULL
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id bigint NOT NULL REFERENCES staff (id),
  email text NOT NULL,
  during tstzrange NOT NULL,
  status text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')),
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (staff_id WITH =, during WITH &&) WHERE (status = 'confirmed')
);
INSERT INTO businesses (name) VALUES ('{w_salon}'), ('{w_clinic}');
INSERT INTO staff (business_id, name) VALUES (1, '{w_mona}'), (1, '{w_omar}'), (2, '{w_hana}');
INSERT INTO bookings (staff_id, email, during) VALUES
  (1, 'sara@example.com', '[2026-12-01 10:00+02, 2026-12-01 10:30+02)'),
  (3, 'ali@example.com', '[2026-12-01 11:00+02, 2026-12-01 11:30+02)'),
  (2, 'nour@example.com', '[2026-12-01 10:30+02, 2026-12-01 11:00+02)');
''',
    "seed.ts": '''import pg from "pg";
import { hashPassword } from "./lib/password.ts";

const db = new pg.Client({ connectionString: process.env.DATABASE_URL });
await db.connect();
const hash = await hashPassword("a long password");
const users = [
  ["owner@bithair.example", "owner", 1],
  ["omar@bithair.example", "staff", 1],
  ["hana@nourclinic.example", "owner", 2],
];
for (const [email, role, business] of users) {
  await db.query(
    "INSERT INTO users (email, password_hash, role, business_id) VALUES ($1, $2, $3, $4)",
    [email, hash, role, business],
  );
}
await db.end();
''',
    "lib/db.ts": "@next:lib/db.ts",
    "lib/time.ts": "@next:lib/time.ts",
    "lib/password.ts": '''import { randomBytes, scrypt, timingSafeEqual } from "node:crypto";

const COST = 2 ** 15;

function derive(password: string, salt: Buffer, cost: number) {
  return new Promise<Buffer>((resolve, reject) => {
    const options = { N: cost, r: 8, p: 1, maxmem: 64 * 1024 * 1024 };
    scrypt(password.normalize("NFKC"), salt, 32, options, (error, key) =>
      error ? reject(error) : resolve(key),
    );
  });
}

export async function hashPassword(password: string) {
  const salt = randomBytes(16);
  const key = await derive(password, salt, COST);
  return ["scrypt", COST, salt.toString("base64url"), key.toString("base64url")].join("$");
}

export async function verifyPassword(password: string, stored: string) {
  const [, cost, salt, key] = stored.split("$");
  const expected = Buffer.from(key ?? "", "base64url");
  const actual = await derive(password, Buffer.from(salt ?? "", "base64url"), Number(cost));
  return timingSafeEqual(actual, expected);
}
''',
    "lib/auth.ts": '''import "server-only";
import { createHash, randomBytes } from "node:crypto";
import { cookies } from "next/headers";
import { pool } from "./db";
import { hashPassword, verifyPassword } from "./password";

export type User = { id: number; email: string; role: "owner" | "staff"; business_id: number };

export class AuthError extends Error {
  status: 401 | 403;
  constructor(status: 401 | 403) {
    super(status === 401 ? "unauthenticated" : "forbidden");
    this.status = status;
  }
}

const COOKIE = "session";
const WEEK = 7 * 24 * 3600;
const digest = (token: string) => createHash("sha256").update(token).digest("hex");
let dummy: Promise<string> | undefined;

export async function signIn(email: string, password: string): Promise<string | null> {
  const { rows } = await pool.query<{ id: number; password_hash: string }>(
    "SELECT id, password_hash FROM users WHERE email = lower($1)",
    [email],
  );
  const user = rows[0];
  // {w_c_dummy}
  const ok = await verifyPassword(password, user?.password_hash ?? (await (dummy ??= hashPassword("x"))));
  if (!user || !ok) return null;
  const token = randomBytes(32).toString("base64url");
  // {w_c_hash}
  await pool.query(
    "INSERT INTO sessions (token_hash, user_id, expires_at) VALUES ($1, $2, now() + $3 * interval '1 second')",
    [digest(token), user.id, WEEK],
  );
  return token;
}

export async function startWebSession(token: string) {
  (await cookies()).set(COOKIE, token, {
    // {w_c_cookie}
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: WEEK,
  });
}

// {w_c_who}
export async function currentUser(request?: Request): Promise<User | null> {
  const bearer = request?.headers.get("authorization")?.match(/^Bearer (\\S+)$/)?.[1];
  const token = bearer ?? (await cookies()).get(COOKIE)?.value;
  if (!token) return null;
  const { rows } = await pool.query<User>(
    `SELECT u.id, u.email, u.role, u.business_id
       FROM sessions s JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = $1 AND s.expires_at > now()`,
    [digest(token)],
  );
  return rows[0] ?? null;
}

// {w_c_require}
export async function requireUser(roles: User["role"][], request?: Request): Promise<User> {
  const user = await currentUser(request);
  if (!user) throw new AuthError(401);
  if (!roles.includes(user.role)) throw new AuthError(403);
  return user;
}
''',
    "lib/owner.ts": '''import "server-only";
import { pool } from "./db";
import type { User } from "./auth";

export type OwnerBooking = { id: number; staff: string; starts_at: string; email: string; status: string };

// {w_c_tenant}
export async function bookingsFor(user: User): Promise<OwnerBooking[]> {
  const { rows } = await pool.query<OwnerBooking & { starts_at: Date }>(
    `SELECT b.id, st.name AS staff, lower(b.during) AS starts_at, b.email, b.status
       FROM bookings b JOIN staff st ON st.id = b.staff_id
      WHERE st.business_id = $1
      ORDER BY lower(b.during)`,
    [user.business_id],
  );
  return rows.map((r) => ({ ...r, starts_at: r.starts_at.toISOString() }));
}

// {w_c_cancel}
export async function cancelBooking(user: User, id: number): Promise<boolean> {
  const { rowCount } = await pool.query(
    `UPDATE bookings b SET status = 'cancelled'
       FROM staff st
      WHERE b.id = $2 AND st.id = b.staff_id AND st.business_id = $1 AND b.status = 'confirmed'`,
    [user.business_id, id],
  );
  return rowCount === 1;
}
''',
    "lib/http.ts": '''import { AuthError } from "./auth";

export function problem(status: number, title: string) {
  return Response.json(
    { title, status },
    { status, headers: { "content-type": "application/problem+json" } },
  );
}

export function authProblem(error: unknown) {
  if (!(error instanceof AuthError)) throw error;
  return problem(error.status, error.status === 401 ? "{w_m_unauth}" : "{w_m_forbidden}");
}
''',
    "proxy.ts": '''import { NextResponse, type NextRequest } from "next/server";

// {w_c_proxy}
export function proxy(request: NextRequest) {
  if (!request.cookies.has("session")) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
}

export const config = { matcher: ["/owner/:path*"] };
''',
    "app/globals.css": "@next:app/globals.css" + '''
li { display: flex; gap: 0.5rem; align-items: center; justify-content: space-between; padding: 0.4rem 0; }
li form button { margin: 0; padding: 0.3rem 0.8rem; background: #b91c1c; }
label { display: block; margin-bottom: 0.75rem; }
input[type="password"] { display: block; width: 100%; padding: 0.5rem; margin-top: 0.25rem; font: inherit; box-sizing: border-box; }
.muted { color: #6b7280; }
''',
    "app/layout.tsx": "@next:app/layout.tsx",
    "app/login/page.tsx": '''import { LoginForm } from "./LoginForm";

export default function LoginPage() {
  return (
    <main>
      <h1>{w_signin}</h1>
      <LoginForm />
    </main>
  );
}
''',
    "app/login/LoginForm.tsx": '''"use client";

import { useActionState } from "react";
import { loginAction } from "./actions";

export function LoginForm() {
  const [state, action, pending] = useActionState(loginAction, {});
  return (
    <form action={action}>
      <label>
        {w_email}
        <input name="email" type="email" required defaultValue={state.email} />
      </label>
      <label>
        {w_password}
        <input name="password" type="password" required />
      </label>
      {state.error && <p role="alert">{state.error}</p>}
      <button disabled={pending}>{pending ? "{w_signing}" : "{w_signin}"}</button>
    </form>
  );
}
''',
    "app/login/actions.ts": '''"use server";

import { redirect } from "next/navigation";
import { signIn, startWebSession } from "@/lib/auth";

type State = { error?: string; email?: string };

export async function loginAction(_previous: State, form: FormData): Promise<State> {
  const email = String(form.get("email") ?? "").slice(0, 254);
  const token = await signIn(email, String(form.get("password") ?? "").slice(0, 128));
  if (!token) return { error: "{w_e_login}", email };
  await startWebSession(token);
  redirect("/owner");
}
''',
    "app/owner/page.tsx": '''import { redirect } from "next/navigation";
import { AuthError, requireUser } from "@/lib/auth";
import { bookingsFor } from "@/lib/owner";
import { time } from "@/lib/time";
import { cancelAction } from "./actions";

async function signedIn() {
  try {
    return await requireUser(["owner", "staff"]);
  } catch (error) {
    if (error instanceof AuthError && error.status === 401) redirect("/login");
    throw error;
  }
}

// {w_c_page}
export default async function OwnerPage() {
  const user = await signedIn();
  const bookings = await bookingsFor(user);
  return (
    <main>
      <h1>{w_today}</h1>
      <p className="muted">{user.email}</p>
      <ul>
        {bookings.map((b) => (
          <li key={b.id}>
            <span>
              {time.format(new Date(b.starts_at))} · {b.staff} · {b.email}
            </span>
            {b.status === "confirmed" && user.role === "owner" ? (
              <form action={cancelAction}>
                <input type="hidden" name="id" value={b.id} />
                <button>{w_cancel}</button>
              </form>
            ) : (
              b.status !== "confirmed" && <span className="muted">{w_cancelled}</span>
            )}
          </li>
        ))}
      </ul>
    </main>
  );
}
''',
    "app/owner/actions.ts": '''"use server";

import { revalidatePath } from "next/cache";
import { requireUser } from "@/lib/auth";
import { cancelBooking } from "@/lib/owner";

// {w_c_action}
export async function cancelAction(form: FormData) {
  const user = await requireUser(["owner"]);
  await cancelBooking(user, Number(form.get("id")));
  revalidatePath("/owner");
}
''',
    "app/api/login/route.ts": '''import { signIn } from "@/lib/auth";
import { problem } from "@/lib/http";

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}));
  const token = await signIn(String(body.email ?? "").slice(0, 254), String(body.password ?? "").slice(0, 128));
  if (!token) return problem(401, "{w_e_login}");
  return Response.json({ token });
}
''',
    "app/api/owner/bookings/route.ts": '''import { requireUser } from "@/lib/auth";
import { authProblem } from "@/lib/http";
import { bookingsFor } from "@/lib/owner";

// {w_c_api}
export async function GET(request: Request) {
  try {
    const user = await requireUser(["owner", "staff"], request);
    return Response.json({ data: await bookingsFor(user) });
  } catch (error) {
    return authProblem(error);
  }
}
''',
    "app/api/owner/bookings/[id]/cancel/route.ts": '''import { requireUser } from "@/lib/auth";
import { authProblem, problem } from "@/lib/http";
import { cancelBooking } from "@/lib/owner";

type Context = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Context) {
  try {
    const user = await requireUser(["owner"], request);
    const done = await cancelBooking(user, Number((await params).id));
    return done ? Response.json({ cancelled: true }) : problem(404, "{w_m_none}");
  } catch (error) {
    return authProblem(error);
  }
}
''',
}

SHOT = r'''
const { chromium } = require("playwright");
(async () => {
  const [base, out] = process.argv.slice(2);
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 520, height: 300 }, deviceScaleFactor: 2 });
  const page = await context.newPage();
  await page.goto(base + "/owner", { waitUntil: "networkidle" });   // the proxy sends us to /login
  await page.fill("input[name=email]", "owner@bithair.example");
  await page.fill("input[name=password]", "a wrong password");
  await page.click("button");
  await page.waitForSelector("[role=alert]");
  await page.screenshot({ path: `${out}/login.png`, fullPage: true });
  await page.waitForTimeout(500);   // React resets the form after the action: let it finish first
  await page.fill("input[name=email]", "owner@bithair.example");
  await page.fill("input[name=password]", "a long password");
  await page.click("button");
  await page.waitForURL(/owner/, { timeout: 8000 }).catch(async (e) => {
    console.error(await page.url(), await page.innerText("body"));
    throw e;
  });
  await page.screenshot({ path: `${out}/owner.png`, fullPage: true });
  const [cookie] = await context.cookies();
  console.log(JSON.stringify({ name: cookie.name, value: cookie.value.slice(0, 8) + "…",
    httpOnly: cookie.httpOnly, sameSite: cookie.sameSite, secure: cookie.secure,
    days: Math.round((cookie.expires - Date.now() / 1000) / 86400) }));
  await browser.close();
})();
'''


def record(folder, t):
    work = HERE / f".work-{folder.name}"
    shutil.rmtree(work, ignore_errors=True)
    app = work / "bit-booking"
    try:
        for name, text in FILES.items():
            if text.startswith("@next:"):
                source, _, extra = text[6:].partition("\n")
                text = (Path(str(NEXT).format(lang=folder.name)) / source).read_text() + (extra and "\n" + extra)
            if name == "tsconfig.json":
                text = text.replace('"noEmit": true,', '"noEmit": true,\n    "allowImportingTsExtensions": true,')
            path = app / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(fill(text, t))
        subprocess.run("npm install --no-audit --no-fund -q", shell=True, cwd=app, check=True, capture_output=True,
                       timeout=900)
        subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "app", "lib",
                        "proxy.ts", "seed.ts"], cwd=app, check=True, capture_output=True)
        subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
        s = Session(app)
        s.run("psql shop -q -f schema.sql")
        s.run("node --env-file=.env.local seed.ts")
        s.run("npm run build")
        s.lines.clear()

        api = "localhost:3000/api"
        j = "-H 'content-type: application/json'"
        bearer = "-H \"authorization: Bearer $TOKEN\""
        with Server("npx next start -p 3000", app, "http://localhost:3000/login"):
            s.note(t["w_s_anon"])
            s.run("curl -s -o /dev/null -w '%{http_code} → %{redirect_url}\\n' localhost:3000/owner")
            s.run(f"curl -s {api}/owner/bookings | jq -c")
            s.note(t["w_s_login"])
            login = (f"curl -s {api}/login {j} -d '{{\"email\":\"{{email}}\",\"password\":\"a long password\"}}' "
                     "| jq -r .token")
            for who, email in (("owner", "owner@bithair.example"), ("staff", "omar@bithair.example")):
                s.run(login.replace("{email}", email) + f" > .{who}", check=True)
            s.lines[-2:] = [f"$ TOKEN=$({login.replace('{email}', 'owner@bithair.example')})",
                            f"$ OMAR=$({login.replace('{email}', 'omar@bithair.example')})"]
            owner = '-H "authorization: Bearer $(cat .owner)"'
            staff = '-H "authorization: Bearer $(cat .staff)"'
            s.note(t["w_s_list"])
            s.run(f"curl -s {api}/owner/bookings {owner} | jq -c '.data[] | [.id, .staff, .email, .status]'",
                  shown=f"curl -s {api}/owner/bookings {bearer} | jq -c '.data[] | [.id, .staff, .email, .status]'")
            cancel = f"curl -s -X POST {api}/owner/bookings/{{id}}/cancel {{auth}} | jq -c"
            s.note(t["w_s_other"])
            s.run(cancel.format(id=2, auth=owner), shown=cancel.format(id=2, auth=bearer))
            s.note(t["w_s_staff"])
            s.run(cancel.format(id=1, auth=staff), shown=cancel.format(id=1, auth=bearer.replace("TOKEN", "OMAR")))
            s.note(t["w_s_owner"])
            s.run(cancel.format(id=1, auth=owner), shown=cancel.format(id=1, auth=bearer))
            s.note(t["w_s_rows"])
            s.run("psql shop -c 'SELECT id, staff_id, email, status FROM bookings ORDER BY id'")
            s.run("psql shop -c \"SELECT left(token_hash, 12) || '…' AS token_hash, user_id, "
                  "expires_at > now() AS valid FROM sessions\"")
            s.save(folder / "api.sh")

            (work / "shot.cjs").write_text(SHOT)
            (folder / "shots").mkdir(parents=True, exist_ok=True)
            node_path = subprocess.run(["npm", "root", "-g"], capture_output=True, text=True).stdout.strip()
            out = subprocess.run(["node", str(work / "shot.cjs"), "http://localhost:3000", str(folder / "shots")],
                                 cwd=work, capture_output=True, text=True,
                                 env=dict(os.environ, NODE_PATH=node_path))
            if out.returncode:
                raise RuntimeError(out.stderr)
            out = out.stdout.strip()
            (folder / "cookie.sh").write_text(f"# {t['w_s_cookie']}\n{out}\n")

        for name in FILES:
            if name == ".env.local":
                continue
            target = folder / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(app / name, target)
    finally:
        shutil.rmtree(work, ignore_errors=True)


for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    record(folder, t)
    print("wrote", lang)
