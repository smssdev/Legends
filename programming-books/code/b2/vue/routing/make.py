"""Writes the examples of Book 2 (Vue edition), chapter "Vue Router and Server Data", in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}. Every file is type-checked with vue-tsc.

The app is real Vue Router and TanStack Vue Query code. main.ts starts it with the browser's history, as a real
site does; the pages used for the book's screenshots (page.ts, projects/*-page.ts) start the same routes with a
memory history, because the screenshot tool opens a file rather than a site, and then click links.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import vue_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Bit's shop", w_back_arrow="←", w_shop="Bit's shop", w_home="Home", w_products="Products",
        w_welcome="Welcome! Browse the products, or search for something.", w_book="Code from Zero", w_mug="Bit mug",
        w_cap="Bit cap", w_sticker="Bit sticker", w_d1="The friendly first book of the series.",
        w_d2="A big mug for long coding nights.", w_d3="Keeps the sun out of your eyes.", w_d4="For your laptop.",
        w_all="All", w_books="Books", w_gifts="Gifts", w_loading="Loading…", w_currency="EGP",
        w_back="Back to products", w_notfound="Page not found", w_noproduct="There is no product with this number.",
        w_error="Something went wrong:", w_retry="Try again", w_fav="Favourite",
        w_saving="Saving…", w_failed="Could not save. The change was undone.", w_server="The server is busy",
        w_blog="Bit's blog", w_posts="Posts", w_p1="Why I love TypeScript", w_p2="Three rules for state", w_p3="Keys, explained",
        w_b1="Types catch mistakes while I type, so my evenings are free.",
        w_b2="Keep it minimal, compute the rest, and give each piece one owner.",
        w_b3="A key tells Vue which item is which between two updates.",
        w_by="by Bit", w_read="min read", w_nopost="This post does not exist.", w_home_link="Go to the home page",
        w_c_routes="Each route maps an address to a component; children are drawn inside their parent's RouterView",
        w_c_props="Pass the id as a typed prop, so the component does not need to know about the router",
        w_c_key="The key names the data: a computed category in it refetches when the address changes",
        w_c_retry="Retry network errors twice, but never a product that does not exist",
        w_c_lazy="Loaded only when the route is first visited",
        w_c_opt1="1. Before the server answers: change the cache, and remember the old value",
        w_c_opt2="2. If it fails: put the old value back",
        w_c_opt3="3. Either way: ask the server for the truth",
        w_c_page="For the book's screenshots only: the same routes, with a memory history",
    ),
    "ar": dict(
        w_title="متجر بِت", w_back_arrow="→", w_shop="متجر بِت", w_home="الرئيسية", w_products="المنتجات",
        w_welcome="أهلاً بك! تصفّح المنتجات، أو ابحث عن شيء.", w_book="البرمجة من الصفر", w_mug="كوب بِت",
        w_cap="قبعة بِت", w_sticker="ملصق بِت", w_d1="الكتاب الأول الودود في السلسلة.",
        w_d2="كوب كبير لليالي البرمجة الطويلة.", w_d3="تحمي عينيك من الشمس.", w_d4="لحاسوبك المحمول.",
        w_all="الكل", w_books="كتب", w_gifts="هدايا", w_loading="جارٍ التحميل…", w_currency="جنيهاً",
        w_back="عودة إلى المنتجات", w_notfound="الصفحة غير موجودة", w_noproduct="لا يوجد منتج بهذا الرقم.",
        w_error="حدث خطأ:", w_retry="حاول مرة أخرى", w_fav="مفضّل",
        w_saving="جارٍ الحفظ…", w_failed="تعذّر الحفظ، وأُلغي التغيير.", w_server="الخادم مشغول",
        w_blog="مدونة بِت", w_posts="التدوينات", w_p1="لماذا أحب TypeScript", w_p2="ثلاث قواعد للحالة", w_p3="المفاتيح ببساطة",
        w_b1="الأنواع تلتقط الأخطاء وأنا أكتب، فتبقى أمسياتي فارغة.",
        w_b2="احفظ الأقل، واحسب الباقي، واجعل لكل قطعة مالكاً واحداً.",
        w_b3="المفتاح يخبر Vue أي عنصر هو أيّه بين تحديثين.",
        w_by="بقلم بِت", w_read="دقائق قراءة", w_nopost="هذه التدوينة غير موجودة.", w_home_link="اذهب إلى الرئيسية",
        w_c_routes="كل مسار يربط عنواناً بمكوّن، والأبناء يُرسمون داخل RouterView الخاص بأبيهم",
        w_c_props="مرّر المعرّف خاصيةً بنوعها، فلا يحتاج المكوّن أن يعرف شيئاً عن الموجّه",
        w_c_key="المفتاح يسمّي البيانات: والفئة المحسوبة فيه تعيد الجلب حين يتغير العنوان",
        w_c_retry="أعد المحاولة مرتين لأخطاء الشبكة، لكن لا تعدها أبداً لمنتج غير موجود",
        w_c_lazy="يُحمَّل فقط عند زيارة المسار أول مرة",
        w_c_opt1="1. قبل رد الخادم: غيّر الذاكرة، وتذكّر القيمة القديمة",
        w_c_opt2="2. إن فشل: أعد القيمة القديمة",
        w_c_opt3="3. في الحالتين: اسأل الخادم عن الحقيقة",
        w_c_page="لصور الكتاب فقط: المسارات نفسها، بسجل في الذاكرة",
    ),
}

CSS = """.layout { max-width: 560px; }
nav { display: flex; gap: 4px; align-items: center; background: white; padding: 8px 10px; border-radius: 14px; margin-bottom: 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
nav .brand { font-weight: 800; color: #4338ca; margin-inline-end: auto; }
nav a { color: #312e81; text-decoration: none; padding: 4px 10px; border-radius: 999px; }
nav a.router-link-active { background: #4338ca; color: white; }
.card { background: white; border-radius: 14px; padding: 14px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
.filters { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 10px; }
.filters a { padding: 4px 12px; border-radius: 999px; background: #e0e7ff; color: #312e81; text-decoration: none; }
.filters a.on { background: #4338ca; color: white; }
ul.list { list-style: none; padding: 0; margin: 0; }
ul.list li { display: flex; justify-content: space-between; gap: 8px; padding: 8px 0; border-bottom: 1px solid #eef2ff; }
ul.list a { color: #4338ca; font-weight: 600; }
.muted { color: #5b5873; }
.price { font-weight: 700; color: #4338ca; }
.error { color: #b91c1c; }
.skeleton { height: 18px; border-radius: 6px; background: linear-gradient(90deg, #eef2ff, #e0e7ff, #eef2ff); margin: 10px 0; }
"""

PLAIN, BROWSER = {}, {}

PLAIN["tsconfig.json"] = '''{
  "compilerOptions": {
    "strict": true, "noUncheckedIndexedAccess": true, "target": "es2024", "module": "esnext",
    "moduleResolution": "bundler", "lib": ["es2024", "dom", "dom.iterable"], "types": ["node"], "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["**/*.ts", "**/*.vue"]
}
'''

PLAIN["api.ts"] = '''// A pretend server for this chapter. A real app would call fetch("/api/…") here.
export type Product = {
  id: number;
  name: string;
  description: string;
  price: number;
  category: "books" | "gifts";
  favourite: boolean;
};

const products: Product[] = [
  { id: 1, name: "{w_book}", description: "{w_d1}", price: 25, category: "books", favourite: false },
  { id: 2, name: "{w_mug}", description: "{w_d2}", price: 8, category: "gifts", favourite: false },
  { id: 3, name: "{w_cap}", description: "{w_d3}", price: 12, category: "gifts", favourite: true },
  { id: 4, name: "{w_sticker}", description: "{w_d4}", price: 3, category: "gifts", favourite: false },
];

export class NotFoundError extends Error {}

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export async function getProducts(category: string | null): Promise<Product[]> {
  await wait(300);
  const list = category ? products.filter((p) => p.category === category) : products;
  return structuredClone(list);
}

export async function getProduct(id: number): Promise<Product> {
  await wait(300);
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  return structuredClone(product);
}

export const server = { failNextSave: false };

export async function setFavourite(id: number, favourite: boolean): Promise<Product> {
  await wait(400);
  if (server.failNextSave) {
    server.failNextSave = false;
    throw new Error("{w_server}");
  }
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  product.favourite = favourite;
  return structuredClone(product);
}
'''

PLAIN["routes.ts"] = '''import type { RouteRecordRaw } from "vue-router";
import Layout from "./views/Layout.vue";
import Home from "./views/Home.vue";
import Products from "./views/Products.vue";
import Product from "./views/Product.vue";
import NotFound from "./views/NotFound.vue";

// {w_c_routes}
export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    component: Layout,
    children: [
      { path: "", component: Home },
      {
        path: "products",
        children: [
          { path: "", component: Products },
          // {w_c_props}
          { path: ":id(\\\\d+)", component: Product, props: (route) => ({ id: Number(route.params.id) }) },
        ],
      },
      { path: ":path(.*)*", component: NotFound },
    ],
  },
];
'''

PLAIN["views/Layout.vue"] = '''<template>
  <div class="layout">
    <nav>
      <span class="brand">{w_shop}</span>
      <RouterLink to="/" exact-active-class="router-link-active" active-class="">{w_home}</RouterLink>
      <RouterLink to="/products">{w_products}</RouterLink>
    </nav>
    <RouterView />
  </div>
</template>
'''
PLAIN["views/Home.vue"] = '''<template>
  <p class="card">{w_welcome}</p>
</template>
'''
PLAIN["views/NotFound.vue"] = '''<template>
  <p class="card">{w_notfound} <RouterLink to="/">{w_home}</RouterLink></p>
</template>
'''
PLAIN["views/Skeleton.vue"] = '''<template>
  <div aria-busy="true" aria-label="{w_loading}">
    <div class="skeleton" />
    <div class="skeleton" />
  </div>
</template>
'''
PLAIN["views/Products.vue"] = '''<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@tanstack/vue-query";
import { getProducts } from "../api";
import Skeleton from "./Skeleton.vue";

const CATEGORIES = [
  { value: null, label: "{w_all}" },
  { value: "books", label: "{w_books}" },
  { value: "gifts", label: "{w_gifts}" },
];

const route = useRoute();
const category = computed(() => (typeof route.query.category === "string" ? route.query.category : null));

// {w_c_key}
const query = useQuery({
  queryKey: ["products", category],
  queryFn: () => getProducts(category.value),
});
</script>

<template>
  <section class="card">
    <div class="filters">
      <RouterLink
        v-for="c in CATEGORIES"
        :key="c.label"
        :to="{ query: c.value ? { category: c.value } : {} }"
        :class="{ on: c.value === category }"
      >
        {{ c.label }}
      </RouterLink>
    </div>
    <Skeleton v-if="query.isPending.value" />
    <p v-else-if="query.isError.value" class="error">{w_error} {{ query.error.value?.message }}</p>
    <ul v-else class="list">
      <li v-for="p in query.data.value" :key="p.id">
        <RouterLink :to="`/products/${p.id}`">{{ p.name }}</RouterLink>
        <span class="price">{{ p.price }} {w_currency}</span>
      </li>
    </ul>
  </section>
</template>
'''
PLAIN["views/Product.vue"] = '''<script setup lang="ts">
import { useQuery } from "@tanstack/vue-query";
import { getProduct, NotFoundError } from "../api";
import Skeleton from "./Skeleton.vue";

const props = defineProps<{ id: number }>();

const { data, error, isPending } = useQuery({
  queryKey: ["product", () => props.id],
  queryFn: () => getProduct(props.id),
  // {w_c_retry}
  retry: (count, e) => !(e instanceof NotFoundError) && count < 2,
});
</script>

<template>
  <Skeleton v-if="isPending" />
  <p v-else-if="error" class="card error">
    {{ error instanceof NotFoundError ? "{w_noproduct}" : error.message }}
  </p>
  <article v-else-if="data" class="card">
    <h2>{{ data.name }}</h2>
    <p>{{ data.description }}</p>
    <p class="price">{{ data.price }} {w_currency}</p>
    <RouterLink to="/products">{w_back_arrow} {w_back}</RouterLink>
  </article>
</template>
'''

PLAIN["main.ts"] = '''import { createApp } from "vue";
import { createRouter, createWebHistory } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import App from "./App.vue";
import { routes } from "./routes";

const router = createRouter({ history: createWebHistory(), routes });

createApp(App)
  .use(router)
  .use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 30_000 } } } })
  .mount("#app");
'''
PLAIN["App.vue"] = '''<template>
  <RouterView />
</template>
'''

PAGE = '''// {w_c_page}
import { createApp } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import App from "{app}";
import { routes } from "{routes}";

const router = createRouter({ history: createMemoryHistory(), routes });
await router.push("/");
createApp(App)
  .use(router)
  .use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 30_000 } } } })
  .mount("#app");
'''
BROWSER["page.ts"] = (PAGE.replace("{app}", "./App.vue").replace("{routes}", "./routes"), CSS)

# ---------------------------------------------------------------- projects
PLAIN["projects/posts.ts"] = '''export type Post = { slug: string; title: string; body: string; minutes: number };

export const posts: Post[] = [
  { slug: "why-typescript", title: "{w_p1}", body: "{w_b1}", minutes: 4 },
  { slug: "rules-for-state", title: "{w_p2}", body: "{w_b2}", minutes: 6 },
  { slug: "keys-explained", title: "{w_p3}", body: "{w_b3}", minutes: 3 },
];
'''
PLAIN["projects/BlogLayout.vue"] = '''<template>
  <div class="layout">
    <nav>
      <span class="brand">{w_blog}</span>
      <RouterLink to="/">{w_posts}</RouterLink>
    </nav>
    <RouterView />
  </div>
</template>
'''
PLAIN["projects/PostList.vue"] = '''<script setup lang="ts">
import { posts } from "./posts";
</script>

<template>
  <ul class="list card">
    <li v-for="post in posts" :key="post.slug">
      <RouterLink :to="{ name: 'post', params: { slug: post.slug } }">{{ post.title }}</RouterLink>
      <span class="muted">{{ post.minutes }} {w_read}</span>
    </li>
  </ul>
</template>
'''
PLAIN["projects/PostPage.vue"] = '''<script setup lang="ts">
import { computed } from "vue";
import { posts } from "./posts";

const props = defineProps<{ slug: string }>();
const post = computed(() => posts.find((p) => p.slug === props.slug));
</script>

<template>
  <article v-if="post" class="card">
    <h2>{{ post.title }}</h2>
    <p class="muted">{w_by} · {{ post.minutes }} {w_read}</p>
    <p>{{ post.body }}</p>
  </article>
  <p v-else class="card">{w_nopost} <RouterLink to="/">{w_home_link}</RouterLink></p>
</template>
'''
PLAIN["projects/blog-routes.ts"] = '''import type { RouteRecordRaw } from "vue-router";
import BlogLayout from "./BlogLayout.vue";
import PostList from "./PostList.vue";
import PostPage from "./PostPage.vue";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    component: BlogLayout,
    children: [
      { path: "", name: "posts", component: PostList },
      { path: "posts/:slug", name: "post", component: PostPage, props: true },
    ],
  },
];
'''
PLAIN["projects/BlogApp.vue"] = '''<template>
  <RouterView />
</template>
'''
BROWSER["projects/blog-page.ts"] = (PAGE.replace("{app}", "./BlogApp.vue").replace("{routes}", "./blog-routes"), CSS)

PLAIN["projects/FavouriteButton.vue"] = '''<script setup lang="ts">
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";
import { getProduct, setFavourite, type Product } from "../api";

const props = defineProps<{ id: number }>();
const client = useQueryClient();
const key = ["product", props.id];
const product = useQuery({ queryKey: key, queryFn: () => getProduct(props.id) });

const mutation = useMutation({
  mutationFn: (favourite: boolean) => setFavourite(props.id, favourite),
  // {w_c_opt1}
  onMutate: async (favourite) => {
    await client.cancelQueries({ queryKey: key });
    const previous = client.getQueryData<Product>(key);
    client.setQueryData<Product>(key, (old) => (old ? { ...old, favourite } : old));
    return { previous };
  },
  // {w_c_opt2}
  onError: (_error, _favourite, context) => client.setQueryData(key, context?.previous),
  // {w_c_opt3}
  onSettled: () => client.invalidateQueries({ queryKey: key }),
});
</script>

<template>
  <p v-if="!product.data.value" class="muted">{w_loading}</p>
  <div v-else class="card">
    <h2>{{ product.data.value.name }}</h2>
    <button
      type="button"
      :aria-pressed="product.data.value.favourite"
      :class="{ secondary: !product.data.value.favourite }"
      @click="mutation.mutate(!product.data.value.favourite)"
    >
      {{ product.data.value.favourite ? "♥" : "♡" }} {w_fav}
    </button>
    <span v-if="mutation.isPending.value" class="muted"> {w_saving}</span>
    <p v-if="mutation.isError.value" class="error" role="alert">{w_failed}</p>
  </div>
</template>
'''
FAV_PAGE = '''// {w_c_page}
import { createApp, h } from "vue";
import { VueQueryPlugin } from "@tanstack/vue-query";
import FavouriteButton from "./FavouriteButton.vue";
import { server } from "../api";

server.failNextSave = {fail};
createApp({ render: () => h(FavouriteButton, { id: 2 }) })
  .use(VueQueryPlugin)
  .mount("#app");
'''
BROWSER["projects/fav-page.ts"] = (FAV_PAGE.replace("{fail}", "false"), CSS)
BROWSER["projects/fav-fail-page.ts"] = (FAV_PAGE.replace("{fail}", "true"), CSS)

kit.generate(HERE, T, plain=PLAIN, browser_files=BROWSER)

check = HERE.parents[1] / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("types ok")
