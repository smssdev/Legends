"""Writes the examples of Book 4, chapter "Full Stack with Next.js", in English and Arabic.
Run: python3 make.py   (PostgreSQL through code/b3/bin/pg-start; installs the app's packages, so it needs the
network the first time, and takes a few minutes)

Bit Booking's web app in one Next.js project: server-only data access on PostgreSQL (the schema of Chapter 1),
Server Components that read it, a booking form whose Server Action calls the same function as the public route
handler, the database's "slot taken" refusal shown in the form, and the build refusing a client component that
imports the database. The app is built in a temporary folder; its sources are copied next to this script.
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
        w_lang="en", w_dir="ltr", w_title="Bit Booking", w_tagline="Book a haircut at Bit Hair Studio",
        w_pick="Choose who cuts your hair", w_choose="Choose a time", w_time="Free times on 1 December",
        w_email="Your email", w_book="Book", w_booking="Booking…", w_none="No free times on this day.",
        w_done="You are booked", w_with="with", w_at="at", w_sent="We sent the details to",
        w_e_invalid="Please choose a time and write a valid email.",
        w_e_taken="Sorry, that time was just taken. Please choose another.",
        w_m_bad="Invalid request", w_salon="Bit Hair Studio", w_mona="Mona", w_omar="Omar", w_cut="Haircut",
        w_c_only="server-only: importing this file from a Client Component fails the build",
        w_c_pool="one pool per process, kept on globalThis: Next reloads modules in development",
        w_c_slots="the free slots, computed by the database in the business's own time zone",
        w_c_taken="23P01: an exclusion violation, the constraint of Chapter 1",
        w_c_server="a Server Component: it runs on the server and reads the database directly",
        w_c_client="a Client Component: it runs in the browser too, and only receives plain data",
        w_c_action="a Server Action: called by the form, on the server, with the checks of any API",
        w_c_fresh="the free times changed either way: render the page again with the answer", w_c_door="the same function behind a second door: Chapter 2's public API",
        w_s_build="Build for production", w_s_api="The same slots through the API",
        w_s_after="After the bookings in the browser", w_s_rows="What the database holds",
        w_s_leak="A Client Component imports the database",
    ),
    "ar": dict(
        w_lang="ar", w_dir="rtl", w_title="بِت للحجوزات", w_tagline="احجز قصة شعر في صالون بِت",
        w_pick="اختر من يقص شعرك", w_choose="اختر وقتاً", w_time="الأوقات المتاحة يوم 1 ديسمبر",
        w_email="بريدك الإلكتروني", w_book="احجز", w_booking="جارٍ الحجز…", w_none="لا أوقات متاحة في هذا اليوم.",
        w_done="تم حجزك", w_with="مع", w_at="الساعة", w_sent="أرسلنا التفاصيل إلى",
        w_e_invalid="اختر وقتاً واكتب بريداً صحيحاً من فضلك.",
        w_e_taken="عذراً، حُجز هذا الوقت للتو. اختر وقتاً آخر من فضلك.",
        w_m_bad="طلب غير صالح", w_salon="صالون بِت", w_mona="منى", w_omar="عمر", w_cut="قص شعر",
        w_c_only="server-only: استيراد هذا الملف من مكوّن عميل يُفشل البناء",
        w_c_pool="مجمع واحد لكل عملية، محفوظ على globalThis: Next يعيد تحميل الوحدات أثناء التطوير",
        w_c_slots="الأوقات المتاحة، تحسبها قاعدة البيانات بالمنطقة الزمنية للعمل نفسه",
        w_c_taken="23P01: خرق قيد استبعاد، قيد الفصل 1",
        w_c_server="مكوّن خادم: يعمل على الخادم ويقرأ قاعدة البيانات مباشرة",
        w_c_client="مكوّن عميل: يعمل في المتصفح أيضاً، ولا يستقبل إلا بيانات عادية",
        w_c_action="إجراء خادم: يناديه النموذج، على الخادم، بفحوص أي واجهة برمجية",
        w_c_fresh="تغيرت الأوقات المتاحة في الحالين: ارسم الصفحة من جديد مع الإجابة", w_c_door="الدالة نفسها خلف باب ثانٍ: الواجهة البرمجية العامة من الفصل 2",
        w_s_build="ابنِ للإنتاج", w_s_api="الأوقات نفسها عبر الواجهة البرمجية",
        w_s_after="بعد الحجوزات في المتصفح", w_s_rows="ما تحفظه قاعدة البيانات",
        w_s_leak="مكوّن عميل يستورد قاعدة البيانات",
    ),
}

FILES = {
    "package.json": '''{
  "name": "bit-booking",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "16.4.5",
    "pg": "8.23.1",
    "react": "19.3.1",
    "react-dom": "19.3.1",
    "server-only": "0.0.1",
    "zod": "4.6.7"
  },
  "devDependencies": {
    "@types/node": "22.20.5",
    "@types/pg": "8.23.1",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "typescript": "5.9.3"
  }
}
''',
    "tsconfig.json": '''{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "noEmit": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "skipLibCheck": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
''',
    "next.config.ts": '''import type { NextConfig } from "next";

const config: NextConfig = { output: "standalone" };

export default config;
''',
    ".env.local": "DATABASE_URL=postgres://bit:secret@localhost:5432/shop\n",
    "schema.sql": '''CREATE EXTENSION btree_gist;
CREATE TABLE staff (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL);
CREATE TABLE services (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text NOT NULL,
  minutes integer NOT NULL CHECK (minutes BETWEEN 5 AND 480), price integer NOT NULL CHECK (price >= 0)
);
CREATE TABLE bookings (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_id bigint NOT NULL REFERENCES staff (id),
  service_id bigint NOT NULL REFERENCES services (id),
  email text NOT NULL,
  during tstzrange NOT NULL,
  status text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')),
  CONSTRAINT no_double_booking
    EXCLUDE USING gist (staff_id WITH =, during WITH &&) WHERE (status = 'confirmed')
);
INSERT INTO staff (name) VALUES ('{w_mona}'), ('{w_omar}');
INSERT INTO services (name, minutes, price) VALUES ('{w_cut}', 30, 25000);
''',
    "lib/db.ts": '''// {w_c_only}
import "server-only";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// {w_c_pool}
const saved = globalThis as unknown as { pool?: pg.Pool };
export const pool = (saved.pool ??= new pg.Pool({ connectionString: process.env.DATABASE_URL }));
''',
    "lib/bookings.ts": '''import "server-only";
import { pool } from "./db";

export type Slot = { starts_at: string; ends_at: string };
export type BookResult = { ok: true; id: number } | { ok: false; reason: "taken" };

// {w_c_slots}
export async function freeSlots(staffId: number, date: string): Promise<Slot[]> {
  const { rows } = await pool.query<{ starts_at: Date; ends_at: Date }>(
    `SELECT lower(slot) AS starts_at, upper(slot) AS ends_at
       FROM generate_series(($2::date + time '10:00') AT TIME ZONE 'Africa/Cairo',
                            ($2::date + time '13:30') AT TIME ZONE 'Africa/Cairo',
                            interval '30 minutes') AS t (start),
            tstzrange(start, start + interval '30 minutes') AS slot
      WHERE NOT EXISTS (SELECT 1 FROM bookings b
                         WHERE b.staff_id = $1 AND b.status = 'confirmed'
                           AND b.during && slot)
      ORDER BY 1`,
    [staffId, date],
  );
  return rows.map((r) => ({ starts_at: r.starts_at.toISOString(), ends_at: r.ends_at.toISOString() }));
}

export async function book(input: { staffId: number; startsAt: string; email: string }): Promise<BookResult> {
  try {
    const { rows } = await pool.query<{ id: number }>(
      `INSERT INTO bookings (staff_id, service_id, email, during)
       VALUES ($1, 1, $3,
               tstzrange($2::timestamptz, $2::timestamptz + interval '30 minutes'))
       RETURNING id`,
      [input.staffId, input.startsAt, input.email],
    );
    return { ok: true, id: rows[0]!.id };
  } catch (error) {
    // {w_c_taken}
    if ((error as { code?: string }).code === "23P01") return { ok: false, reason: "taken" };
    throw error;
  }
}

export async function staffList() {
  const { rows } = await pool.query<{ id: number; name: string }>("SELECT id, name FROM staff ORDER BY id");
  return rows;
}

export async function findBooking(id: number) {
  const { rows } = await pool.query<{ id: number; staff: string; starts_at: Date; email: string }>(
    `SELECT b.id, s.name AS staff, lower(b.during) AS starts_at, b.email
       FROM bookings b JOIN staff s ON s.id = b.staff_id WHERE b.id = $1`,
    [id],
  );
  return rows[0];
}
''',
    "lib/time.ts": '''export const time = new Intl.DateTimeFormat("{w_lang}", {
  hour: "2-digit",
  minute: "2-digit",
  timeZone: "Africa/Cairo",
});
''',
    "app/globals.css": '''body { font-family: system-ui, sans-serif; margin: 0; background: #f6f5ff; color: #1e1b4b; }
main { max-width: 30rem; margin: 0 auto; padding: 1rem 1.25rem 2rem; }
header { background: #4338ca; color: #fff; padding: 0.75rem 1.25rem; font-weight: 700; }
h1 { font-size: 1.35rem; margin: 0.5rem 0 1rem; }
a { color: #4338ca; }
fieldset { border: 0; padding: 0; margin: 0 0 1rem; display: flex; flex-wrap: wrap; gap: 0.5rem; }
legend { font-weight: 600; margin-bottom: 0.5rem; }
fieldset label { border: 1px solid #c7c4f5; border-radius: 0.5rem; padding: 0.4rem 0.7rem; background: #fff; }
fieldset label:has(input:checked) { background: #4338ca; color: #fff; }
fieldset input { position: absolute; opacity: 0; }
input[type="email"] { display: block; width: 100%; padding: 0.5rem; margin-top: 0.25rem; font: inherit; box-sizing: border-box; }
button { margin-top: 1rem; padding: 0.6rem 1.4rem; font: inherit; font-weight: 600; background: #4338ca; color: #fff; border: 0; border-radius: 0.5rem; }
[role="alert"] { background: #fee2e2; color: #991b1b; padding: 0.6rem 0.8rem; border-radius: 0.5rem; }
.done { background: #dcfce7; color: #14532d; padding: 1rem; border-radius: 0.75rem; }
''',
    "app/layout.tsx": '''import "./globals.css";

export const metadata = { title: "{w_title}" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="{w_lang}" dir="{w_dir}">
      <body>
        <header>{w_title}</header>
        {children}
      </body>
    </html>
  );
}
''',
    "app/page.tsx": '''import Link from "next/link";
import { staffList } from "@/lib/bookings";

export const dynamic = "force-dynamic";

export default async function Home() {
  const staff = await staffList();
  return (
    <main>
      <h1>{w_pick}</h1>
      <ul>
        {staff.map((s) => (
          <li key={s.id}>
            <Link href={`/book/${s.id}`}>{s.name}</Link>
          </li>
        ))}
      </ul>
    </main>
  );
}
''',
    "app/book/[staff]/page.tsx": '''import { freeSlots } from "@/lib/bookings";
import { BookForm } from "./BookForm";

type Props = { params: Promise<{ staff: string }>; searchParams: Promise<{ date?: string }> };

// {w_c_server}
export default async function BookPage({ params, searchParams }: Props) {
  const staffId = Number((await params).staff);
  const { date = "2026-12-01" } = await searchParams;
  const slots = await freeSlots(staffId, date);
  return (
    <main>
      <h1>{w_choose}</h1>
      {slots.length ? <BookForm staffId={staffId} slots={slots} /> : <p>{w_none}</p>}
    </main>
  );
}
''',
    "app/book/[staff]/BookForm.tsx": '''"use client";

import { useActionState } from "react";
import type { Slot } from "@/lib/bookings";
import { time } from "@/lib/time";
import { bookAction, type BookState } from "../actions";

// {w_c_client}
export function BookForm({ staffId, slots }: { staffId: number; slots: Slot[] }) {
  const [state, action, pending] = useActionState(bookAction, {} as BookState);
  return (
    <form action={action}>
      <input type="hidden" name="staffId" value={staffId} />
      <fieldset>
        <legend>{w_time}</legend>
        {slots.map((slot) => (
          <label key={slot.starts_at}>
            <input type="radio" name="startsAt" value={slot.starts_at} required />
            {time.format(new Date(slot.starts_at))}
          </label>
        ))}
      </fieldset>
      <label>
        {w_email}
        <input name="email" type="email" required defaultValue={state.email} />
      </label>
      {state.error && <p role="alert">{state.error}</p>}
      <button disabled={pending}>{pending ? "{w_booking}" : "{w_book}"}</button>
    </form>
  );
}
''',
    "app/book/actions.ts": '''"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { book } from "@/lib/bookings";

const Input = z.object({
  staffId: z.coerce.number().int().positive(),
  startsAt: z.iso.datetime(),
  email: z.email().max(254),
});

export type BookState = { error?: string; email?: string };

// {w_c_action}
export async function bookAction(_previous: BookState, form: FormData): Promise<BookState> {
  const parsed = Input.safeParse(Object.fromEntries(form));
  const email = String(form.get("email") ?? "");
  if (!parsed.success) return { error: "{w_e_invalid}", email };
  const result = await book(parsed.data);
  // {w_c_fresh}
  revalidatePath(`/book/${parsed.data.staffId}`);
  if (!result.ok) return { error: "{w_e_taken}", email };
  redirect(`/booking/${result.id}`);
}
''',
    "app/booking/[id]/page.tsx": '''import { notFound } from "next/navigation";
import { findBooking } from "@/lib/bookings";
import { time } from "@/lib/time";

export default async function BookingPage({ params }: { params: Promise<{ id: string }> }) {
  const booking = await findBooking(Number((await params).id));
  if (!booking) notFound();
  return (
    <main>
      <h1>{w_done}</h1>
      <p className="done">
        <strong>
          {booking.staff} · {time.format(booking.starts_at)}
        </strong>
        <br />
        {w_sent} {booking.email}.
      </p>
    </main>
  );
}
''',
    "app/api/slots/route.ts": '''import { freeSlots } from "@/lib/bookings";

// {w_c_door}
export async function GET(request: Request) {
  const query = new URL(request.url).searchParams;
  const staffId = Number(query.get("staff_id"));
  const date = query.get("date") ?? "";
  if (!Number.isInteger(staffId) || staffId < 1 || !/^\\d{4}-\\d{2}-\\d{2}$/.test(date)) {
    const problem = { title: "{w_m_bad}", status: 422 };
    return Response.json(problem, { status: 422, headers: { "content-type": "application/problem+json" } });
  }
  return Response.json({ data: await freeSlots(staffId, date) });
}
''',
}

LEAK = '''"use client";

import { pool } from "@/lib/db";

export function Leak() {
  return <p>{String(pool.totalCount)}</p>;
}
'''

SHOT = r'''
const { chromium } = require("playwright");
(async () => {
  const [base, out] = process.argv.slice(2);
  const browser = await chromium.launch();
  const open = async () => {
    const page = await browser.newPage({ viewport: { width: 520, height: 300 }, deviceScaleFactor: 2 });
    await page.goto(base + "/book/1", { waitUntil: "networkidle" });
    return page;
  };
  const late = await open();               // Karim opens the page first, and waits
  const sara = await open();
  await sara.screenshot({ path: `${out}/book.png`, fullPage: true });
  await sara.click("fieldset label >> nth=0");
  await sara.fill("input[type=email]", "sara@example.com");
  await sara.click("button");
  await sara.waitForURL(/booking/);
  await sara.screenshot({ path: `${out}/done.png`, fullPage: true });
  await late.click("fieldset label >> nth=0");  // the same time, on a page loaded before Sara booked it
  await late.fill("input[type=email]", "karim@example.com");
  await late.click("button");
  await late.waitForSelector("[role=alert]");
  await late.screenshot({ path: `${out}/taken.png`, fullPage: true });
  await browser.close();
})();
'''


def record(folder, t):
    # inside code/, which the PostgreSQL container can see (bin/psql runs there)
    work = HERE / f".work-{folder.name}"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir()
    app = work / "bit-booking"
    try:
        for name, text in FILES.items():
            path = app / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(fill(text, t))
        subprocess.run("npm install --no-audit --no-fund -q", shell=True, cwd=app, check=True, capture_output=True,
                       timeout=900)
        subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "app", "lib"],
                       cwd=app, check=True, capture_output=True)
        subprocess.run(["pg-start", "--fresh"], env=CLEAN, check=True)
        s = Session(app)
        s.run("psql shop -q -f schema.sql")
        s.lines.clear()

        (app / "app/leak").mkdir()
        (app / "app/leak/Leak.tsx").write_text(LEAK)
        (app / "app/leak/page.tsx").write_text('import { Leak } from "./Leak";\n\n'
                                               "export default function Page() {\n  return <Leak />;\n}\n")
        s.note(t["w_s_leak"])
        s.run("npm run build 2>&1 | grep -E 'server-only|Invalid import|Client Component|app/leak' "
              "| sed -E 's/^ +//; s#\\./next/\\.work-[a-z]+/bit-booking/#./#' | awk '!seen[$0]++' | head -6",
              shown="npm run build", check=False)
        s.save(folder / "leak.sh")
        shutil.rmtree(app / "app/leak")

        s.note(t["w_s_build"])
        s.run("npm run build 2>&1 | sed -n '/^Route/,$p' | grep -v '^$'", shown="npm run build")
        s.save(folder / "build.sh")

        slots = "curl -s 'localhost:3000/api/slots?staff_id=1&date=2026-12-01' | jq -c '.data[:2]'"
        with Server("npx next start -p 3000", app, "http://localhost:3000/api/slots?staff_id=1&date=2026-12-01"):
            s.note(t["w_s_api"])
            s.run(slots)
            (work / "shot.cjs").write_text(SHOT)
            (folder / "shots").mkdir(parents=True, exist_ok=True)
            subprocess.run(["node", str(work / "shot.cjs"), "http://localhost:3000", str(folder / "shots")],
                           check=True, cwd=work, env=dict(os.environ, NODE_PATH=subprocess.run(
                               ["npm", "root", "-g"], capture_output=True, text=True).stdout.strip()))
            s.note(t["w_s_after"])
            s.run(slots)
            s.note(t["w_s_rows"])
            s.run("psql shop -c 'SELECT id, staff_id, email, lower(during) AS starts_at FROM bookings'")
            s.save(folder / "api.sh")

        for name in FILES:
            if name == ".env.local":
                continue
            target = folder / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(app / name, target)
    finally:
        shutil.rmtree(work, ignore_errors=True)


for lang, t in T.items():
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    record(folder, t)
    print("wrote", lang)
