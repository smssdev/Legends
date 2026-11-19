"""Writes the examples of Book 2 (React edition), chapter "Server Rendering with Next.js", in English and Arabic.
Run: python3 make.py   (needs the internet once, and takes a few minutes)

It creates a real Next.js app with create-next-app, adds the chapter's files, installs, builds, starts it,
and records what the tools printed, what the server sent, and screenshots of the running app.
The app's source is copied next to this script (en/app, ar/app...) for the book's listings.
"""
import os
import re
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(
        lang="en", dir="ltr", w_shop="Bit's shop", w_home="Home", w_products="Products", w_contact="Contact",
        w_welcome="Welcome to Bit's shop", w_intro="Books, mugs and stickers for people who love to code.",
        w_browse="Browse the products", w_book="Code from Zero", w_mug="Bit mug", w_cap="Bit cap",
        w_d1="The friendly first book of the series.", w_d2="A big mug for long coding nights.", w_d3="Keeps the sun out of your eyes.",
        w_currency="EGP", w_add="Add to cart", w_added="In your cart", w_back="All products", w_loading="Loading products…",
        w_notfound="We could not find that page.", w_name="Name", w_message="Message", w_send="Send",
        w_sending="Sending…", w_e_name="Please write your name.", w_e_message="Please write at least 10 characters.",
        w_thanks="Thank you, {name}! We will reply soon.", w_rendered="Rendered on the server at",
        w_c1="This component runs only on the server: it can read the database directly",
        w_c2="Cache the page and rebuild it at most about once a minute",
        w_c3="Runs in the browser: it has state and reacts to clicks",
        w_c4="A Server Action: a function that runs on the server, called by a form",
        w_c5="A pretend database: in a real app, a query to PostgreSQL or a call to another service",
        w_c6="Build one page per product at build time", w_c7="Save the message, send an email… on the server, with secrets that never reach the browser",
        w_c_create="Create the project", w_c_build="Build for production", w_c_curl="What does the server send? (no JavaScript involved)",
        w_c_api="The route handler returns JSON",
    ),
    "ar": dict(
        lang="ar", dir="rtl", w_shop="متجر بِت", w_home="الرئيسية", w_products="المنتجات", w_contact="تواصل معنا",
        w_welcome="أهلاً بك في متجر بِت", w_intro="كتب وأكواب وملصقات لمن يحبون البرمجة.",
        w_browse="تصفّح المنتجات", w_book="البرمجة من الصفر", w_mug="كوب بِت", w_cap="قبعة بِت",
        w_d1="الكتاب الأول الودود في السلسلة.", w_d2="كوب كبير لليالي البرمجة الطويلة.", w_d3="تحمي عينيك من الشمس.",
        w_currency="جنيهاً", w_add="أضف إلى السلة", w_added="في سلتك", w_back="كل المنتجات", w_loading="جارٍ تحميل المنتجات…",
        w_notfound="لم نجد هذه الصفحة.", w_name="الاسم", w_message="الرسالة", w_send="أرسل",
        w_sending="جارٍ الإرسال…", w_e_name="اكتب اسمك.", w_e_message="اكتب 10 أحرف على الأقل.",
        w_thanks="شكراً يا {name}! سنرد قريباً.", w_rendered="رُسمت على الخادم الساعة",
        w_c1="هذا المكوّن يعمل على الخادم فقط: يستطيع قراءة قاعدة البيانات مباشرة",
        w_c2="خزّن الصفحة وأعد بناءها مرة في الدقيقة على الأكثر",
        w_c3="يعمل في المتصفح: له حالة ويتفاعل مع الضغطات",
        w_c4="إجراء خادم: دالة تعمل على الخادم ويستدعيها نموذج",
        w_c5="قاعدة بيانات وهمية: في تطبيق حقيقي، استعلام إلى PostgreSQL أو استدعاء خدمة أخرى",
        w_c6="ابنِ صفحة لكل منتج وقت البناء", w_c7="احفظ الرسالة، وأرسل بريداً… على الخادم، بأسرار لا تصل إلى المتصفح أبداً",
        w_c_create="أنشئ المشروع", w_c_build="ابنِ للإنتاج", w_c_curl="ماذا يرسل الخادم؟ (دون أي JavaScript)",
        w_c_api="معالج المسار يُرجع JSON",
    ),
}

FILES = {
    "app/layout.tsx": '''import type { Metadata } from "next";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "{w_shop}", template: "%s · {w_shop}" },
  description: "{w_intro}",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="{lang}" dir="{dir}">
      <body>
        <nav>
          <Link href="/" className="brand">{w_shop}</Link>
          <Link href="/products">{w_products}</Link>
          <Link href="/contact">{w_contact}</Link>
        </nav>
        <main>{children}</main>
      </body>
    </html>
  );
}
''',
    "app/globals.css": '''* { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, "Segoe UI", Tahoma, sans-serif; background: #f5f5fb; color: #1e1b2e; }
nav { display: flex; gap: 14px; align-items: center; background: white; padding: 10px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
nav a { color: #312e81; text-decoration: none; }
nav .brand { font-weight: 800; color: #4338ca; margin-inline-end: auto; }
main { max-width: 560px; margin: 16px auto; padding: 0 16px; }
h1 { color: #4338ca; }
.card { background: white; border-radius: 14px; padding: 14px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
ul.list { list-style: none; padding: 0; margin: 0; }
ul.list li { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eef2ff; }
ul.list a { color: #4338ca; font-weight: 600; }
.price { font-weight: 700; color: #4338ca; }
.muted { color: #5b5873; font-size: 0.9rem; }
button { font: inherit; border: 0; border-radius: 999px; padding: 8px 18px; background: #4338ca; color: white; cursor: pointer; }
button.secondary { background: #e0e7ff; color: #312e81; }
label { display: block; font-weight: 600; margin-top: 10px; }
input, textarea { font: inherit; width: 100%; padding: 8px 10px; border: 2px solid #c7d2fe; border-radius: 10px; }
.error { color: #b91c1c; margin: 4px 0 0; }
.done { color: #047857; font-weight: 700; }
.skeleton { height: 18px; border-radius: 6px; background: #e0e7ff; margin: 12px 0; }
''',
    "lib/products.ts": '''// {w_c5}
export type Product = { id: number; name: string; description: string; price: number };

const products: Product[] = [
  { id: 1, name: "{w_book}", description: "{w_d1}", price: 250 },
  { id: 2, name: "{w_mug}", description: "{w_d2}", price: 85 },
  { id: 3, name: "{w_cap}", description: "{w_d3}", price: 120 },
];

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export async function getProducts(): Promise<Product[]> {
  await wait(300);
  return products;
}

export async function getProduct(id: number): Promise<Product | undefined> {
  await wait(300);
  return products.find((p) => p.id === id);
}
''',
    "app/page.tsx": '''import Link from "next/link";

export default function Home() {
  return (
    <section className="card">
      <h1>{w_welcome}</h1>
      <p>{w_intro}</p>
      <Link href="/products">{w_browse}</Link>
    </section>
  );
}
''',
    "app/products/page.tsx": '''import Link from "next/link";
import type { Metadata } from "next";
import { cacheLife } from "next/cache";
import { getProducts } from "@/lib/products";

export const metadata: Metadata = { title: "{w_products}" };

// {w_c1}
export default async function ProductsPage() {
  "use cache";
  cacheLife("minutes"); // {w_c2}
  const products = await getProducts();
  return (
    <section className="card">
      <h1>{w_products}</h1>
      <ul className="list">
        {products.map((p) => (
          <li key={p.id}>
            <Link href={`/products/${p.id}`}>{p.name}</Link>
            <span className="price">
              {p.price} {w_currency}
            </span>
          </li>
        ))}
      </ul>
      <p className="muted">
        {w_rendered} {new Date().toISOString().slice(11, 19)} UTC
      </p>
    </section>
  );
}
''',
    "app/products/loading.tsx": '''export default function Loading() {
  return (
    <section className="card" aria-busy="true" aria-label="{w_loading}">
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton" />
    </section>
  );
}
''',
    "app/products/[id]/page.tsx": '''import Link from "next/link";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getProduct, getProducts } from "@/lib/products";
import { AddToCart } from "./AddToCart";

type Props = { params: Promise<{ id: string }> };

// {w_c6}
export async function generateStaticParams() {
  const products = await getProducts();
  return products.map((p) => ({ id: String(p.id) }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const product = await getProduct(Number((await params).id));
  return { title: product?.name, description: product?.description };
}

export default async function ProductPage({ params }: Props) {
  const product = await getProduct(Number((await params).id));
  if (!product) notFound();
  return (
    <article className="card">
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <p className="price">
        {product.price} {w_currency}
      </p>
      <AddToCart name={product.name} />
      <p>
        <Link href="/products">{w_back}</Link>
      </p>
    </article>
  );
}
''',
    "app/products/[id]/AddToCart.tsx": '''"use client"; // {w_c3}

import { useState } from "react";

export function AddToCart({ name }: { name: string }) {
  const [added, setAdded] = useState(false);
  return (
    <button className={added ? "secondary" : undefined} aria-pressed={added} onClick={() => setAdded(!added)} aria-label={`{w_add}: ${name}`}>
      {added ? "✓ {w_added}" : "{w_add}"}
    </button>
  );
}
''',
    "app/api/products/route.ts": '''import { getProducts } from "@/lib/products";

export async function GET() {
  return Response.json(await getProducts());
}
''',
    "app/contact/actions.ts": '''"use server"; // {w_c4}

import { z } from "zod";

const schema = z.object({
  name: z.string().trim().min(1, "{w_e_name}"),
  message: z.string().trim().min(10, "{w_e_message}"),
});

export type ContactState = { errors?: Partial<Record<"name" | "message", string>>; done?: string };

export async function sendMessage(_previous: ContactState, form: FormData): Promise<ContactState> {
  const parsed = schema.safeParse(Object.fromEntries(form));
  if (!parsed.success) {
    const errors: ContactState["errors"] = {};
    for (const issue of parsed.error.issues) errors[issue.path[0] as "name" | "message"] ??= issue.message;
    return { errors };
  }
  // {w_c7}
  return { done: `{w_thanks}`.replace("{name}", parsed.data.name) };
}
''',
    "app/contact/page.tsx": '''import type { Metadata } from "next";
import { ContactForm } from "./ContactForm";

export const metadata: Metadata = { title: "{w_contact}" };

export default function ContactPage() {
  return (
    <section className="card">
      <h1>{w_contact}</h1>
      <ContactForm />
    </section>
  );
}
''',
    "app/contact/ContactForm.tsx": '''"use client";

import { useActionState } from "react";
import { sendMessage, type ContactState } from "./actions";

export function ContactForm() {
  const [state, action, pending] = useActionState<ContactState, FormData>(sendMessage, {});
  if (state.done) return <p className="done" role="status">{state.done}</p>;
  return (
    <form action={action} noValidate>
      <label htmlFor="name">{w_name}</label>
      <input id="name" name="name" autoComplete="name" aria-describedby="name-error" />
      {state.errors?.name && <p className="error" id="name-error">{state.errors.name}</p>}
      <label htmlFor="message">{w_message}</label>
      <textarea id="message" name="message" rows={3} aria-describedby="message-error" />
      {state.errors?.message && <p className="error" id="message-error">{state.errors.message}</p>}
      <p>
        <button type="submit" disabled={pending}>{pending ? "{w_sending}" : "{w_send}"}</button>
      </p>
    </form>
  );
}
''',
    "app/not-found.tsx": '''import Link from "next/link";

export default function NotFound() {
  return (
    <section className="card">
      <h1>404</h1>
      <p>{w_notfound}</p>
      <Link href="/">{w_home}</Link>
    </section>
  );
}
''',
}


def fill(text, t):
    return re.sub(r"(?<![$\w])\{(\w+)\}", lambda m: t[m.group(1)] if m.group(1) in t else m.group(0), text)


def run(cmd, cwd, keep=None, env=None, check=True, timeout=600):
    e = dict(os.environ, NO_COLOR="1", FORCE_COLOR="0", NEXT_TELEMETRY_DISABLED="1", npm_config_fund="false",
             npm_config_update_notifier="false", **(env or {}))
    r = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, env=e, timeout=timeout)
    if check and r.returncode:
        raise SystemExit(f"{cmd} failed:\n{r.stdout}\n{r.stderr}")
    out = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", r.stdout + r.stderr)
    lines = [l.rstrip() for l in out.splitlines() if l.strip()]
    return keep(lines) if keep else lines


SHOT = r'''
const { chromium } = require("playwright");
(async () => {
  const [base, out] = process.argv.slice(2);
  const browser = await chromium.launch();
  const shots = [
    ["products", "/products", []],
    ["product", "/products/2", [["click", "article button"]]],
    ["contact", "/contact", [["fill", "#message", "Hi"], ["click", "form button"], ["wait", "#name-error"]]],
    ["missing", "/products/99", []],
  ];
  for (const [name, path, steps] of shots) {
    const page = await browser.newPage({ viewport: { width: 560, height: 200 }, deviceScaleFactor: 2 });
    await page.goto(base + path, { waitUntil: "networkidle" });
    for (const [kind, selector, text] of steps) {
      if (kind === "click") await page.click(selector);
      if (kind === "fill") await page.fill(selector, text);
      if (kind === "wait") await page.waitForSelector(selector);
    }
    await page.waitForTimeout(300);
    await page.screenshot({ path: `${out}/${name}.png`, fullPage: true });
    await page.close();
  }
  await browser.close();
})();
'''


def record(lang):
    t = T[lang]
    out = HERE / lang
    shutil.rmtree(out, ignore_errors=True)
    (out / "shots").mkdir(parents=True)
    work = Path(tempfile.mkdtemp())
    try:
        transcript = [f"# {t['w_c_create']}",
                      "$ npx create-next-app@latest bit-shop --ts --app --eslint --no-tailwind --no-src-dir --use-npm"]
        transcript += run("npx --yes create-next-app@latest bit-shop --ts --app --eslint --no-tailwind --no-src-dir "
                          '--import-alias "@/*" --use-npm --yes --skip-install', work,
                          keep=lambda ls: [l for l in ls if l.startswith("Success")])
        shop = work / "bit-shop"
        for f in ("app/page.module.css", "public/next.svg", "public/vercel.svg", "public/file.svg", "public/globe.svg",
                  "public/window.svg"):
            (shop / f).unlink(missing_ok=True)
        for name, text in FILES.items():
            path = shop / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(fill(text, t))
        run("npm install && npm install zod", shop, timeout=900)
        transcript += [f"# {t['w_c_build']}", "$ npm run build"]
        transcript += run("npx next build", shop, keep=lambda ls: ls[ls.index(next(l for l in ls if l.startswith("Route"))):])
        (out / "build.sh").write_text(re.sub(str(work), "~/code", "\n".join(transcript)) + "\n")

        port = 3017 if lang == "en" else 3018
        server = subprocess.Popen(f"npx next start -p {port}", shell=True, cwd=shop, stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL, env=dict(os.environ, NEXT_TELEMETRY_DISABLED="1"),
                                  preexec_fn=os.setsid)
        try:
            base = f"http://localhost:{port}"
            for _ in range(60):
                if subprocess.run(f"curl -s -o /dev/null {base}/", shell=True).returncode == 0:
                    break
                time.sleep(0.5)
            show = "curl -s localhost:3000/products | grep -oE '<li><a href=\"[^\"]+\">[^<]+'"
            curl = [f"# {t['w_c_curl']}", "$ " + show]
            curl += run(show.replace("localhost:3000", base.removeprefix("http://")), work, check=False)
            curl += [f"# {t['w_c_api']}", "$ curl -s localhost:3000/api/products"]
            curl += run(f"curl -s {base}/api/products", work)
            (out / "curl.sh").write_text("\n".join(curl) + "\n")
            (work / "shot.cjs").write_text(SHOT)
            run(f"node shot.cjs {base} {out / 'shots'}", work)
        finally:
            os.killpg(server.pid, 15)

        for name in FILES:
            target = out / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(shop / name, target)
    finally:
        shutil.rmtree(work, ignore_errors=True)


for lang in T:
    record(lang)
    print("recorded", lang)
