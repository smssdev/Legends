"""Writes the examples of Book 2, chapter "Frontend Architecture at Scale", in English and Arabic.
Run: python3 make.py   A small sample codebase (sample/src) is written, with two rule-breaking imports on purpose,
and the scripts that check it. Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Architecture", w_rules="Rules", w_ok="No boundary violations.", w_violations="violations",
        w_r1="shared code must not import a feature", w_r2="import another feature only through its index.ts",
        w_r3="nothing imports from app/", w_c1="The layers, from the bottom up: each may import only from layers below it",
        w_c2="One place that talks to the server: typed, validated, and with errors the screens can understand",
        w_c3="A fake server for the example, with one product, a slow answer and a broken one",
        w_ok_list="Products:", w_notfound="Not found:", w_invalid="Invalid data:", w_network="Network:",
        w_book="Code from Zero",
    ),
    "ar": dict(
        w_title="المعمارية", w_rules="القواعد", w_ok="لا مخالفات للحدود.", w_violations="مخالفات",
        w_r1="الكود المشترك لا يستورد ميزة", w_r2="استورد ميزة أخرى عبر index.ts الخاص بها فقط",
        w_r3="لا شيء يستورد من app/", w_c1="الطبقات من الأسفل إلى الأعلى: كل طبقة تستورد مما تحتها فقط",
        w_c2="مكان واحد يتحدث إلى الخادم: بالأنواع، ومع التحقق، وبأخطاء تفهمها الشاشات",
        w_c3="خادم وهمي للمثال، فيه منتج واحد، ورد بطيء، وآخر مكسور",
        w_ok_list="المنتجات:", w_notfound="غير موجود:", w_invalid="بيانات غير صالحة:", w_network="الشبكة:",
        w_book="البرمجة من الصفر",
    ),
}

PLAIN, NODE = {}, {}

SAMPLE = {
    "sample/src/app/App.tsx": 'import { CatalogPage } from "../features/catalog";\nimport { CartBadge } from "../features/cart";\nimport { Layout } from "../shared/ui/Layout";\n\nexport function App() {\n  return (\n    <Layout header={<CartBadge />}>\n      <CatalogPage />\n    </Layout>\n  );\n}\n',
    "sample/src/app/routes.tsx": 'import { CatalogPage } from "../features/catalog";\nimport { AccountPage } from "../features/account";\n\nexport const routes = [\n  { path: "/", element: <CatalogPage /> },\n  { path: "/account", element: <AccountPage /> },\n];\n',
    "sample/src/shared/ui/Layout.tsx": 'import type { ReactNode } from "react";\n\nexport function Layout({ header, children }: { header: ReactNode; children: ReactNode }) {\n  return (\n    <>\n      <header>{header}</header>\n      <main>{children}</main>\n    </>\n  );\n}\n',
    "sample/src/shared/ui/Button.tsx": 'import type { ComponentProps } from "react";\n\nexport function Button(props: ComponentProps<"button">) {\n  return <button type="button" className="btn" {...props} />;\n}\n',
    "sample/src/shared/api/client.ts": 'export async function getJson(path: string): Promise<unknown> {\n  const response = await fetch(path);\n  if (!response.ok) throw new Error(`HTTP ${response.status}`);\n  return response.json();\n}\n',
    "sample/src/shared/lib/money.ts": 'export const formatMoney = (value: number) => `${value.toFixed(2)} EGP`;\n',
    # A violation: shared code reaching into a feature
    "sample/src/shared/ui/Header.tsx": 'import { useCart } from "../../features/cart/store";\n\nexport function Header() {\n  const count = useCart((s) => s.count);\n  return <p>{count}</p>;\n}\n',
    "sample/src/features/catalog/index.ts": 'export { CatalogPage } from "./CatalogPage";\n',
    "sample/src/features/catalog/CatalogPage.tsx": 'import { Button } from "../../shared/ui/Button";\nimport { formatMoney } from "../../shared/lib/money";\nimport { addToCart } from "../cart";\nimport { useProducts } from "./useProducts";\n\nexport function CatalogPage() {\n  const products = useProducts();\n  return (\n    <ul>\n      {products.map((p) => (\n        <li key={p.id}>\n          {p.name} {formatMoney(p.price)} <Button onClick={() => addToCart(p)}>+</Button>\n        </li>\n      ))}\n    </ul>\n  );\n}\n',
    "sample/src/features/catalog/useProducts.ts": 'import { getJson } from "../../shared/api/client";\n\nexport type Product = { id: number; name: string; price: number };\nexport function useProducts(): Product[] {\n  void getJson("/api/products");\n  return [];\n}\n',
    "sample/src/features/cart/index.ts": 'export { CartBadge } from "./CartBadge";\nexport { addToCart } from "./store";\n',
    "sample/src/features/cart/store.ts": 'type Item = { id: number; price: number };\nlet items: Item[] = [];\nexport function addToCart(item: Item) {\n  items = [...items, item];\n}\nexport function useCart<T>(select: (s: { count: number }) => T): T {\n  return select({ count: items.length });\n}\n',
    "sample/src/features/cart/CartBadge.tsx": 'import { useCart } from "./store";\n\nexport function CartBadge() {\n  return <span>{useCart((s) => s.count)}</span>;\n}\n',
    "sample/src/features/account/index.ts": 'export { AccountPage } from "./AccountPage";\n',
    # A violation: one feature reaching into another feature's internals
    "sample/src/features/account/AccountPage.tsx": 'import { CartBadge } from "../cart/CartBadge";\nimport { Button } from "../../shared/ui/Button";\n\nexport function AccountPage() {\n  return (\n    <section>\n      <CartBadge />\n      <Button>Sign out</Button>\n    </section>\n  );\n}\n',
}
PLAIN.update(SAMPLE)

NODE["boundaries.ts"] = '''import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";

// {w_c1}: shared → features → app
const root = resolve(process.argv[2] ?? "sample/src");

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? files(path) : /\\.(ts|tsx)$/.test(name) ? [path] : [];
  });
}

// "features/cart/store.ts" -> { layer: "features", feature: "cart", rest: "store.ts" }
function where(path: string) {
  const [layer = "", feature = "", ...rest] = relative(root, path).split("/");
  return { layer, feature: layer === "features" ? feature : "", rest: rest.join("/") };
}

const problems: string[] = [];
for (const file of files(root)) {
  const from = where(file);
  for (const [, target] of readFileSync(file, "utf8").matchAll(/from\\s+"(\\.[^"]+)"/g)) {
    const to = where(resolve(dirname(file), target!));
    const at = `${relative(root, file)} → ${target}`;
    if (from.layer === "shared" && to.layer === "features") problems.push(`${at}\\n    {w_r1}`);
    if (to.layer === "app" && from.layer !== "app") problems.push(`${at}\\n    {w_r3}`);
    if (from.layer === "features" && to.layer === "features" && from.feature !== to.feature && to.rest !== "") {
      problems.push(`${at}\\n    {w_r2}`);
    }
  }
}

for (const p of problems) console.log("✗ " + p);
console.log(problems.length === 0 ? "{w_ok}" : `${problems.length} {w_violations}`);
process.exitCode = problems.length ? 1 : 0;
'''

NODE["tree.ts"] = '''import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";

// Prints the sample's folders as a tree
function print(dir: string, prefix = ""): void {
  const names = readdirSync(dir).sort((a, b) => Number(statSync(join(dir, b)).isDirectory()) - Number(statSync(join(dir, a)).isDirectory()) || a.localeCompare(b));
  names.forEach((name, i) => {
    const last = i === names.length - 1;
    const path = join(dir, name);
    console.log(`${prefix}${last ? "└── " : "├── "}${name}${statSync(path).isDirectory() ? "/" : ""}`);
    if (statSync(path).isDirectory()) print(path, prefix + (last ? "    " : "│   "));
  });
}
console.log("src/");
print("sample/src");
'''

# ---------------------------------------------------------------- the API layer (project 2)
PLAIN["projects/api.ts"] = '''import { z } from "zod";

// {w_c2}
export const Product = z.object({ id: z.number(), name: z.string(), price: z.number().nonnegative() });
export type Product = z.infer<typeof Product>;

export type ApiError =
  | { kind: "network"; message: string }
  | { kind: "not-found"; path: string }
  | { kind: "invalid"; issues: string[] }
  | { kind: "server"; status: number };

export type Result<T> = { ok: true; data: T } | { ok: false; error: ApiError };

export function createApi(base: string, fetcher: typeof fetch = fetch) {
  async function get<T>(path: string, schema: z.ZodType<T>): Promise<Result<T>> {
    let response: Response;
    try {
      response = await fetcher(base + path, { signal: AbortSignal.timeout(2000) });
    } catch (e) {
      return { ok: false, error: { kind: "network", message: (e as Error).name } };
    }
    if (response.status === 404) return { ok: false, error: { kind: "not-found", path } };
    if (!response.ok) return { ok: false, error: { kind: "server", status: response.status } };
    const parsed = schema.safeParse(await response.json());
    if (!parsed.success) {
      return { ok: false, error: { kind: "invalid", issues: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`) } };
    }
    return { ok: true, data: parsed.data };
  }

  return {
    products: () => get("/products", z.array(Product)),
    product: (id: number) => get(`/products/${id}`, Product),
  };
}
'''

NODE["projects/use-api.ts"] = '''import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { createApi } from "./api";

// {w_c3}
const server = createServer((req, res) => {
  res.setHeader("Content-Type", "application/json");
  if (req.url === "/products") return res.end(JSON.stringify([{ id: 1, name: "{w_book}", price: 25 }]));
  if (req.url === "/products/2") return res.end(JSON.stringify({ id: 2, name: "Bit mug", price: "8" }));
  if (req.url === "/products/3") return void setTimeout(() => res.end("{}"), 3000);
  res.writeHead(404).end();
});
await new Promise<void>((ready) => server.listen(0, ready));
const api = createApi(`http://localhost:${(server.address() as AddressInfo).port}`);

for (const call of [() => api.products(), () => api.product(9), () => api.product(2), () => api.product(3)]) {
  const result = await call();
  if (result.ok) console.log("✓ {w_ok_list}", JSON.stringify(result.data));
  else console.log("✗", JSON.stringify(result.error));
}
server.closeAllConnections();
server.close();
'''

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, title_key="w_title")


# ---------------------------------------------------------------- the same codebase in Vue (Vue edition), under vue/
import vue_kit  # noqa: E402

VPLAIN, VNODE = {}, {}
VSAMPLE = {
    "vue/sample/src/app/App.vue": '<script setup lang="ts">\nimport { CatalogPage } from "../features/catalog";\nimport { CartBadge } from "../features/cart";\nimport AppLayout from "../shared/ui/AppLayout.vue";\n</script>\n\n<template>\n  <AppLayout>\n    <template #header><CartBadge /></template>\n    <CatalogPage />\n  </AppLayout>\n</template>\n',
    "vue/sample/src/app/routes.ts": 'import { CatalogPage } from "../features/catalog";\nimport { AccountPage } from "../features/account";\n\nexport const routes = [\n  { path: "/", component: CatalogPage },\n  { path: "/account", component: AccountPage },\n];\n',
    "vue/sample/src/shared/ui/AppLayout.vue": '<template>\n  <header><slot name="header" /></header>\n  <main><slot /></main>\n</template>\n',
    "vue/sample/src/shared/ui/BaseButton.vue": '<template>\n  <button type="button" class="btn"><slot /></button>\n</template>\n',
    "vue/sample/src/shared/api/client.ts": SAMPLE["sample/src/shared/api/client.ts"],
    "vue/sample/src/shared/lib/money.ts": SAMPLE["sample/src/shared/lib/money.ts"],
    # A violation: shared code reaching into a feature
    "vue/sample/src/shared/ui/AppHeader.vue": '<script setup lang="ts">\nimport { useCart } from "../../features/cart/store";\n\nconst cart = useCart();\n</script>\n\n<template>\n  <p>{{ cart.count }}</p>\n</template>\n',
    "vue/sample/src/features/catalog/index.ts": 'export { default as CatalogPage } from "./CatalogPage.vue";\n',
    "vue/sample/src/features/catalog/CatalogPage.vue": '<script setup lang="ts">\nimport BaseButton from "../../shared/ui/BaseButton.vue";\nimport { formatMoney } from "../../shared/lib/money";\nimport { useCart } from "../cart";\nimport { useProducts } from "./useProducts";\n\nconst products = useProducts();\nconst cart = useCart();\n</script>\n\n<template>\n  <ul>\n    <li v-for="p in products" :key="p.id">\n      {{ p.name }} {{ formatMoney(p.price) }} <BaseButton @click="cart.add(p)">+</BaseButton>\n    </li>\n  </ul>\n</template>\n',
    "vue/sample/src/features/catalog/useProducts.ts": SAMPLE["sample/src/features/catalog/useProducts.ts"],
    "vue/sample/src/features/cart/index.ts": 'export { default as CartBadge } from "./CartBadge.vue";\nexport { useCart } from "./store";\n',
    "vue/sample/src/features/cart/store.ts": 'import { defineStore } from "pinia";\nimport { computed, ref } from "vue";\n\ntype Item = { id: number; price: number };\nexport const useCart = defineStore("cart", () => {\n  const items = ref<Item[]>([]);\n  const count = computed(() => items.value.length);\n  const add = (item: Item) => items.value.push(item);\n  return { items, count, add };\n});\n',
    "vue/sample/src/features/cart/CartBadge.vue": '<script setup lang="ts">\nimport { useCart } from "./store";\n\nconst cart = useCart();\n</script>\n\n<template>\n  <span>{{ cart.count }}</span>\n</template>\n',
    "vue/sample/src/features/account/index.ts": 'export { default as AccountPage } from "./AccountPage.vue";\n',
    # A violation: one feature reaching into another feature's internals
    "vue/sample/src/features/account/AccountPage.vue": '<script setup lang="ts">\nimport CartBadge from "../cart/CartBadge.vue";\nimport BaseButton from "../../shared/ui/BaseButton.vue";\n</script>\n\n<template>\n  <section>\n    <CartBadge />\n    <BaseButton>Sign out</BaseButton>\n  </section>\n</template>\n',
}
VPLAIN.update(VSAMPLE)
VNODE["vue/boundaries.ts"] = NODE["boundaries.ts"].replace("/\\.(ts|tsx)$/", "/\\.(ts|vue)$/")
VNODE["vue/tree.ts"] = NODE["tree.ts"]

vue_kit.generate(HERE, T, plain=VPLAIN, node_files=VNODE)
