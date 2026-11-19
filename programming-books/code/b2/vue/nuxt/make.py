"""Writes the examples of Book 2 (Vue edition), chapter "Server Rendering with Nuxt", in English and Arabic.
Run: python3 make.py   (needs the internet once, and takes a few minutes)

It creates a real Nuxt app with create-nuxt, adds the chapter's files, installs, builds, starts it, and records
what the tools printed, what the server sent, and screenshots of the running app. The app's source is copied
next to this script (en/app, en/server, ar/...) for the book's listings.
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
        w_currency="EGP", w_add="Add to cart", w_added="In your cart", w_back="All products",
        w_notfound="We could not find that page.", w_name="Name", w_message="Message", w_send="Send",
        w_sending="Sending…", w_e_name="Please write your name.", w_e_message="Please write at least 10 characters.",
        w_thanks="Thank you, {name}! We will reply soon.", w_rendered="Rendered on the server at",
        w_c_rules="How each address is made: prerendered at build time, or cached and refreshed in the background",
        w_c_head="Sets <html lang dir> and the title of every page, on the server and in the browser",
        w_c_db="A pretend database: in a real app, a query to PostgreSQL or a call to another service",
        w_c_api="A server route: this code runs only on the server, and answers /api/products",
        w_c_fetch="Runs on the server for the first visit; the browser receives the data with the page, and does not ask again",
        w_c_state="useState carries the server's value to the browser, so both draw the same time",
        w_c_404="A missing product becomes a real 404, shown by error.vue",
        w_c_click="Drawn on the server, then hydrated in the browser, where it reacts to clicks",
        w_c_valid="The server checks every field: the browser's checks can be switched off by anyone",
        w_c_secret="Save the message, send an email… on the server, with secrets that never reach the browser",
        w_c_create="Create the project", w_c_build="Build for production",
        w_c_curl="What does the server send? (no JavaScript involved)", w_c_api_json="The server route returns JSON",
        w_c_cache="The product list is cached for a minute",
    ),
    "ar": dict(
        lang="ar", dir="rtl", w_shop="متجر بِت", w_home="الرئيسية", w_products="المنتجات", w_contact="تواصل معنا",
        w_welcome="أهلاً بك في متجر بِت", w_intro="كتب وأكواب وملصقات لمن يحبون البرمجة.",
        w_browse="تصفّح المنتجات", w_book="البرمجة من الصفر", w_mug="كوب بِت", w_cap="قبعة بِت",
        w_d1="الكتاب الأول الودود في السلسلة.", w_d2="كوب كبير لليالي البرمجة الطويلة.", w_d3="تحمي عينيك من الشمس.",
        w_currency="جنيهاً", w_add="أضف إلى السلة", w_added="في سلتك", w_back="كل المنتجات",
        w_notfound="لم نجد هذه الصفحة.", w_name="الاسم", w_message="الرسالة", w_send="أرسل",
        w_sending="جارٍ الإرسال…", w_e_name="اكتب اسمك.", w_e_message="اكتب 10 أحرف على الأقل.",
        w_thanks="شكراً يا {name}! سنرد قريباً.", w_rendered="رُسمت على الخادم الساعة",
        w_c_rules="كيف يُصنع كل عنوان: يُرسم مسبقاً وقت البناء، أو يُخزَّن ويُحدَّث في الخلفية",
        w_c_head="يضبط <html lang dir> وعنوان كل صفحة، على الخادم وفي المتصفح",
        w_c_db="قاعدة بيانات وهمية: في تطبيق حقيقي، استعلام إلى PostgreSQL أو استدعاء خدمة أخرى",
        w_c_api="مسار خادم: هذا الكود يعمل على الخادم فقط، ويجيب /api/products",
        w_c_fetch="يعمل على الخادم في الزيارة الأولى، ويستلم المتصفح البيانات مع الصفحة فلا يسأل مرة أخرى",
        w_c_state="useState تحمل قيمة الخادم إلى المتصفح، فيرسم الاثنان الوقت نفسه",
        w_c_404="المنتج المفقود يصير 404 حقيقياً، يعرضه error.vue",
        w_c_click="يُرسم على الخادم، ثم يُحيا في المتصفح حيث يتفاعل مع الضغطات",
        w_c_valid="الخادم يتحقق من كل حقل: ففحوص المتصفح يستطيع أي أحد إطفاءها",
        w_c_secret="احفظ الرسالة، وأرسل بريداً… على الخادم، بأسرار لا تصل إلى المتصفح أبداً",
        w_c_create="أنشئ المشروع", w_c_build="ابنِ للإنتاج",
        w_c_curl="ماذا يرسل الخادم؟ (دون أي JavaScript)", w_c_api_json="مسار الخادم يُرجع JSON",
        w_c_cache="قائمة المنتجات مخزنة دقيقة",
    ),
}

FILES = {
    "nuxt.config.ts": '''export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: false },
  css: ["~/assets/main.css"],
  // {w_c_rules}
  routeRules: {
    "/": { prerender: true },
    "/contact": { prerender: true },
    "/products": { swr: 60 },
    "/products/**": { swr: 3600 },
  },
});
''',
    "app/app.vue": '''<script setup lang="ts">
// {w_c_head}
useHead({
  htmlAttrs: { lang: "{lang}", dir: "{dir}" },
  titleTemplate: (title) => (title ? `${title} · {w_shop}` : "{w_shop}"),
});
</script>

<template>
  <NuxtLoadingIndicator />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
''',
    "app/layouts/default.vue": '''<template>
  <nav>
    <NuxtLink to="/" class="brand">{w_shop}</NuxtLink>
    <NuxtLink to="/products">{w_products}</NuxtLink>
    <NuxtLink to="/contact">{w_contact}</NuxtLink>
  </nav>
  <main><slot /></main>
</template>
''',
    "app/assets/main.css": '''* { box-sizing: border-box; }
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
''',
    "server/utils/products.ts": '''// {w_c_db}
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
    "server/api/products.get.ts": '''// {w_c_api}
export default defineEventHandler(() => getProducts());
''',
    "server/api/products/[id].get.ts": '''export default defineEventHandler(async (event) => {
  const product = await getProduct(Number(getRouterParam(event, "id")));
  if (!product) throw createError({ statusCode: 404, statusMessage: "Not found" });
  return product;
});
''',
    "server/api/contact.post.ts": '''import * as z from "zod";

const schema = z.object({
  name: z.string().trim().min(1, "{w_e_name}"),
  message: z.string().trim().min(10, "{w_e_message}"),
});

export default defineEventHandler(async (event) => {
  // {w_c_valid}
  const result = schema.safeParse(await readBody(event));
  if (!result.success) {
    const errors: Record<string, string> = {};
    for (const issue of result.error.issues) errors[String(issue.path[0])] ??= issue.message;
    throw createError({ statusCode: 422, data: { errors } });
  }
  // {w_c_secret}
  return { message: "{w_thanks}".replace("{name}", result.data.name) };
});
''',
    "app/pages/index.vue": '''<template>
  <section class="card">
    <h1>{w_welcome}</h1>
    <p>{w_intro}</p>
    <NuxtLink to="/products">{w_browse}</NuxtLink>
  </section>
</template>
''',
    "app/pages/products/index.vue": '''<script setup lang="ts">
// {w_c_fetch}
const { data: products } = await useFetch("/api/products");
// {w_c_state}
const rendered = useState("rendered", () => new Date().toISOString().slice(11, 19));

useSeoMeta({ title: "{w_products}", description: "{w_intro}" });
</script>

<template>
  <section class="card">
    <h1>{w_products}</h1>
    <ul class="list">
      <li v-for="p in products" :key="p.id">
        <NuxtLink :to="`/products/${p.id}`">{{ p.name }}</NuxtLink>
        <span class="price">{{ p.price }} {w_currency}</span>
      </li>
    </ul>
    <p class="muted">{w_rendered} {{ rendered }} UTC</p>
  </section>
</template>
''',
    "app/pages/products/[id].vue": '''<script setup lang="ts">
const route = useRoute();
const { data: product, error } = await useFetch(`/api/products/${route.params.id}`);

// {w_c_404}
if (error.value) throw createError({ statusCode: 404, statusMessage: "{w_notfound}", fatal: true });

useSeoMeta({ title: () => product.value?.name, description: () => product.value?.description });
</script>

<template>
  <article v-if="product" class="card">
    <h1>{{ product.name }}</h1>
    <p>{{ product.description }}</p>
    <p class="price">{{ product.price }} {w_currency}</p>
    <AddToCart :name="product.name" />
    <p><NuxtLink to="/products">{w_back}</NuxtLink></p>
  </article>
</template>
''',
    "app/components/AddToCart.vue": '''<script setup lang="ts">
// {w_c_click}
defineProps<{ name: string }>();
const added = ref(false);
</script>

<template>
  <button type="button" :class="{ secondary: added }" :aria-pressed="added" :aria-label="`{w_add}: ${name}`" @click="added = !added">
    {{ added ? "✓ {w_added}" : "{w_add}" }}
  </button>
</template>
''',
    "app/error.vue": '''<script setup lang="ts">
import type { NuxtError } from "#app";

defineProps<{ error: NuxtError }>();
</script>

<template>
  <NuxtLayout>
    <section class="card">
      <h1>{{ error.statusCode }}</h1>
      <p>{{ error.statusCode === 404 ? "{w_notfound}" : error.statusMessage }}</p>
      <button type="button" class="secondary" @click="clearError({ redirect: '/' })">{w_home}</button>
    </section>
  </NuxtLayout>
</template>
''',
    "app/pages/contact.vue": '''<script setup lang="ts">
useSeoMeta({ title: "{w_contact}" });

const form = reactive({ name: "", message: "" });
const errors = ref<Record<string, string>>({});
const done = ref("");
const sending = ref(false);

async function send() {
  sending.value = true;
  try {
    const answer = await $fetch("/api/contact", { method: "POST", body: form });
    done.value = answer.message;
  } catch (e) {
    errors.value = (e as { data?: { data?: { errors?: Record<string, string> } } }).data?.data?.errors ?? {};
  } finally {
    sending.value = false;
  }
}
</script>

<template>
  <section class="card">
    <h1>{w_contact}</h1>
    <p v-if="done" class="done" role="status">{{ done }}</p>
    <form v-else novalidate @submit.prevent="send">
      <label for="name">{w_name}</label>
      <input id="name" v-model="form.name" autocomplete="name" :aria-invalid="!!errors.name" aria-describedby="name-error" />
      <p v-if="errors.name" id="name-error" class="error">{{ errors.name }}</p>
      <label for="message">{w_message}</label>
      <textarea id="message" v-model="form.message" rows="3" :aria-invalid="!!errors.message" aria-describedby="message-error" />
      <p v-if="errors.message" id="message-error" class="error">{{ errors.message }}</p>
      <p>
        <button type="submit" :disabled="sending">{{ sending ? "{w_sending}" : "{w_send}" }}</button>
      </p>
    </form>
  </section>
</template>
''',
}


def fill(text, t):
    return re.sub(r"(?<![$\w])\{(\w+)\}", lambda m: t[m.group(1)] if m.group(1) in t else m.group(0), text)


def run(cmd, cwd, keep=None, check=True, timeout=900):
    env = dict(os.environ, NO_COLOR="1", FORCE_COLOR="0", NUXT_TELEMETRY_DISABLED="1", CI="1",
               npm_config_fund="false", npm_config_update_notifier="false")
    r = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, env=env, timeout=timeout)
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


def build_build_lines(lines):
    keep = []
    for l in lines:
        l = re.sub(r"^(\[\w+\] )+(\[nitro\] )?", "", l)
        s = l.strip()
        if s.startswith(("Prerendering", "Prerendered", "├─ /", "└─ /")) or "Build complete" in s:
            keep.append(re.sub(r"\s*\(\d+ms\).*$", "", l).replace("✨ ", ""))
    return keep


def record():
    work = Path(tempfile.mkdtemp())
    try:
        create = run("npx --yes create-nuxt@latest bit-shop --template minimal --packageManager npm "
                     "--gitInit=false --no-install --no-modules", work,
                     keep=lambda ls: [l for l in ls if "Created your project" in l or "Creating project" in l])
        shop = work / "bit-shop"
        run("npm install --no-audit && npm install --no-audit zod", shop)
        for lang, t in T.items():
            out = HERE / lang
            shutil.rmtree(out, ignore_errors=True)
            (out / "shots").mkdir(parents=True)
            for f in ("app/app.vue",):
                (shop / f).unlink(missing_ok=True)
            for name, text in FILES.items():
                path = shop / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(fill(text, t))
            transcript = [f"# {t['w_c_create']}", "$ npm create nuxt@latest bit-shop -- --template minimal"]
            transcript += [re.sub(r"^[^A-Za-z]*(o )?", "", l) for l in create]
            transcript += ["$ cd bit-shop", "$ npm install zod", f"# {t['w_c_build']}", "$ npm run build"]
            shutil.rmtree(shop / ".output", ignore_errors=True)
            transcript += run("npx nuxt build", shop, keep=build_build_lines)
            (out / "build.sh").write_text("\n".join(transcript) + "\n")

            port = 3027 if lang == "en" else 3028
            server = subprocess.Popen(["node", ".output/server/index.mjs"], cwd=shop, stdout=subprocess.DEVNULL,
                                      stderr=subprocess.DEVNULL, env=dict(os.environ, PORT=str(port)))
            try:
                base = f"http://localhost:{port}"
                for _ in range(60):
                    if subprocess.run(f"curl -s -o /dev/null {base}/", shell=True).returncode == 0:
                        break
                    time.sleep(0.5)
                show = "curl -s localhost:3000/products | grep -oE '<a href=\"/products/[0-9]+\"[^>]*>[^<]+'"
                curl = [f"# {t['w_c_curl']}", "$ " + show]
                curl += run(show.replace("localhost:3000", base.removeprefix("http://")), work, check=False)
                curl += [f"# {t['w_c_cache']}", "$ curl -sI localhost:3000/products | grep -i cache-control"]
                curl += run(f"curl -sI {base}/products | grep -i cache-control", work, check=False)
                curl += [f"# {t['w_c_api_json']}", "$ curl -s localhost:3000/api/products"]
                curl += run(f"curl -s {base}/api/products", work)
                (out / "curl.sh").write_text("\n".join(curl) + "\n")
                (work / "shot.cjs").write_text(SHOT)
                run(f"node shot.cjs {base} {out / 'shots'}", work)
            finally:
                server.terminate()
                server.wait()
            for name in FILES:
                target = out / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(shop / name, target)
            print("recorded", lang)
    finally:
        shutil.rmtree(work, ignore_errors=True)


record()
