"""Writes the examples of Book 2 (React edition), chapter "Routing and Server Data", in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}.

The app is real React Router and TanStack Query code. main.tsx starts it with a browser router, as a real
site does; the pages used for the book's screenshots (page.tsx, projects/*-page.tsx) start the same routes
with a memory router, because the screenshot tool opens a file rather than a site, and then click links.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        title="Bit's shop", w_back_arrow="←", w_shop="Bit's shop", w_home="Home", w_products="Products", w_about="About",
        w_welcome="Welcome! Browse the products, or search for something.", w_book="Code from Zero", w_mug="Bit mug",
        w_cap="Bit cap", w_sticker="Bit sticker", w_d1="The friendly first book of the series.",
        w_d2="A big mug for long coding nights.", w_d3="Keeps the sun out of your eyes.", w_d4="For your laptop.",
        w_all="All", w_books="Books", w_gifts="Gifts", w_search="Search", w_loading="Loading…", w_currency="EGP",
        w_back="Back to products", w_notfound="Page not found", w_noproduct="There is no product with this number.",
        w_error="Something went wrong:", w_retry="Try again", w_count="products", w_fav="Favourite", w_unfav="Remove favourite",
        w_saving="Saving…", w_failed="Could not save. The change was undone.", w_server="The server is busy",
        w_blog="Bit's blog", w_posts="Posts", w_p1="Why I love TypeScript", w_p2="Three rules for state", w_p3="Keys, explained",
        w_b1="Types catch mistakes while I type, so my evenings are free.",
        w_b2="Keep it minimal, derive the rest, and never change it in place.",
        w_b3="A key tells React which item is which between two renders.",
        w_by="by Bit", w_read="min read", w_nopost="This post does not exist.", w_home_link="Go to the home page",
    ),
    "ar": dict(
        title="متجر بِت", w_back_arrow="→", w_shop="متجر بِت", w_home="الرئيسية", w_products="المنتجات", w_about="من نحن",
        w_welcome="أهلاً بك! تصفّح المنتجات، أو ابحث عن شيء.", w_book="البرمجة من الصفر", w_mug="كوب بِت",
        w_cap="قبعة بِت", w_sticker="ملصق بِت", w_d1="الكتاب الأول الودود في السلسلة.",
        w_d2="كوب كبير لليالي البرمجة الطويلة.", w_d3="تحمي عينيك من الشمس.", w_d4="لحاسوبك المحمول.",
        w_all="الكل", w_books="كتب", w_gifts="هدايا", w_search="ابحث", w_loading="جارٍ التحميل…", w_currency="جنيهاً",
        w_back="عودة إلى المنتجات", w_notfound="الصفحة غير موجودة", w_noproduct="لا يوجد منتج بهذا الرقم.",
        w_error="حدث خطأ:", w_retry="حاول مرة أخرى", w_count="منتجات", w_fav="مفضّل", w_unfav="أزل من المفضلة",
        w_saving="جارٍ الحفظ…", w_failed="تعذّر الحفظ، وأُلغي التغيير.", w_server="الخادم مشغول",
        w_blog="مدونة بِت", w_posts="التدوينات", w_p1="لماذا أحب TypeScript", w_p2="ثلاث قواعد للحالة", w_p3="المفاتيح ببساطة",
        w_b1="الأنواع تلتقط الأخطاء وأنا أكتب، فتبقى أمسياتي فارغة.",
        w_b2="احفظ الأقل، واشتق الباقي، ولا تغيّرها في مكانها أبداً.",
        w_b3="المفتاح يخبر React أي عنصر هو أيّه بين رسمين.",
        w_by="بقلم بِت", w_read="دقائق قراءة", w_nopost="هذه التدوينة غير موجودة.", w_home_link="اذهب إلى الرئيسية",
    ),
}

CSS = """.layout { max-width: 560px; }
nav { display: flex; gap: 4px; align-items: center; background: white; padding: 8px 10px; border-radius: 14px; margin-bottom: 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
nav .brand { font-weight: 800; color: #4338ca; margin-inline-end: auto; }
nav a { color: #312e81; text-decoration: none; padding: 4px 10px; border-radius: 999px; }
nav a.active { background: #4338ca; color: white; }
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

PLAIN = {}
BROWSER = {}

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

PLAIN["routes.tsx"] = '''import { Link, NavLink, Outlet, useParams, useRouteError, useSearchParams } from "react-router";
import type { RouteObject } from "react-router";
import { useQuery } from "@tanstack/react-query";
import { getProduct, getProducts, NotFoundError } from "./api";

function Layout() {
  return (
    <div className="layout">
      <nav>
        <span className="brand">{w_shop}</span>
        <NavLink to="/" end>
          {w_home}
        </NavLink>
        <NavLink to="/products">{w_products}</NavLink>
      </nav>
      <Outlet />
    </div>
  );
}

function Home() {
  return <p className="card">{w_welcome}</p>;
}

const CATEGORIES = [
  { value: null, label: "{w_all}" },
  { value: "books", label: "{w_books}" },
  { value: "gifts", label: "{w_gifts}" },
];

function Products() {
  const [params] = useSearchParams();
  const category = params.get("category");
  const query = useQuery({
    queryKey: ["products", category],
    queryFn: () => getProducts(category),
  });

  return (
    <section className="card">
      <div className="filters">
        {CATEGORIES.map((c) => (
          <Link key={c.label} to={c.value ? `?category=${c.value}` : "."} className={c.value === category ? "on" : ""}>
            {c.label}
          </Link>
        ))}
      </div>
      {query.isPending && <Skeleton />}
      {query.isError && <p className="error">{w_error} {query.error.message}</p>}
      {query.isSuccess && (
        <ul className="list">
          {query.data.map((p) => (
            <li key={p.id}>
              <Link to={`/products/${p.id}`}>{p.name}</Link>
              <span className="price">
                {p.price} {w_currency}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function Product() {
  const { id } = useParams();
  const query = useQuery({
    queryKey: ["product", Number(id)],
    queryFn: () => getProduct(Number(id)),
    retry: (count, error) => !(error instanceof NotFoundError) && count < 2,
  });

  if (query.isPending) return <Skeleton />;
  if (query.isError) {
    const missing = query.error instanceof NotFoundError;
    return <p className="card error">{missing ? "{w_noproduct}" : query.error.message}</p>;
  }
  const p = query.data;
  return (
    <article className="card">
      <h2>{p.name}</h2>
      <p>{p.description}</p>
      <p className="price">
        {p.price} {w_currency}
      </p>
      <Link to="/products">{w_back_arrow} {w_back}</Link>
    </article>
  );
}

function Skeleton() {
  return (
    <div aria-busy="true" aria-label="{w_loading}">
      <div className="skeleton" />
      <div className="skeleton" />
    </div>
  );
}

function ErrorPage() {
  const error = useRouteError();
  return (
    <p className="card error">
      {w_error} {String(error)}
    </p>
  );
}

function NotFound() {
  return <p className="card">{w_notfound}</p>;
}

export const routes: RouteObject[] = [
  {
    path: "/",
    element: <Layout />,
    errorElement: <ErrorPage />,
    children: [
      { index: true, element: <Home /> },
      { path: "products", element: <Products /> },
      { path: "products/:id", element: <Product /> },
      { path: "*", element: <NotFound /> },
    ],
  },
];
'''

PLAIN["main.tsx"] = '''import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { routes } from "./routes";

const router = createBrowserRouter(routes);
const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000 } },
});

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </StrictMode>,
);
'''

PAGE = '''// For the book's screenshots only: the same routes, in a memory router.
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { routes } from "{routes}";

const router = createMemoryRouter(routes);
const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 30_000 } } });

createRoot(document.getElementById("root")!).render(
  <QueryClientProvider client={queryClient}>
    <RouterProvider router={router} />
  </QueryClientProvider>,
);
'''
BROWSER["page.tsx"] = (PAGE.replace("{routes}", "./routes"), CSS)

# ---------------------------------------------------------------- projects
PLAIN["projects/blog-routes.tsx"] = '''import { Link, NavLink, Outlet, useParams } from "react-router";
import type { RouteObject } from "react-router";

type Post = { slug: string; title: string; body: string; minutes: number };

const posts: Post[] = [
  { slug: "why-typescript", title: "{w_p1}", body: "{w_b1}", minutes: 4 },
  { slug: "rules-for-state", title: "{w_p2}", body: "{w_b2}", minutes: 6 },
  { slug: "keys-explained", title: "{w_p3}", body: "{w_b3}", minutes: 3 },
];

function Layout() {
  return (
    <div className="layout">
      <nav>
        <span className="brand">{w_blog}</span>
        <NavLink to="/" end>
          {w_posts}
        </NavLink>
      </nav>
      <Outlet />
    </div>
  );
}

function PostList() {
  return (
    <ul className="list card">
      {posts.map((post) => (
        <li key={post.slug}>
          <Link to={`/posts/${post.slug}`}>{post.title}</Link>
          <span className="muted">
            {post.minutes} {w_read}
          </span>
        </li>
      ))}
    </ul>
  );
}

function PostPage() {
  const { slug } = useParams();
  const post = posts.find((p) => p.slug === slug);
  if (!post) {
    return (
      <p className="card">
        {w_nopost} <Link to="/">{w_home_link}</Link>
      </p>
    );
  }
  return (
    <article className="card">
      <h2>{post.title}</h2>
      <p className="muted">
        {w_by} · {post.minutes} {w_read}
      </p>
      <p>{post.body}</p>
    </article>
  );
}

export const routes: RouteObject[] = [
  {
    path: "/",
    element: <Layout />,
    children: [
      { index: true, element: <PostList /> },
      { path: "posts/:slug", element: <PostPage /> },
    ],
  },
];
'''
BROWSER["projects/blog-page.tsx"] = (PAGE.replace("{routes}", "./blog-routes"), CSS)

PLAIN["projects/favourite.tsx"] = '''import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { getProduct, setFavourite, type Product } from "../api";

export function FavouriteButton({ id }: { id: number }) {
  const client = useQueryClient();
  const key = ["product", id];
  const product = useQuery({ queryKey: key, queryFn: () => getProduct(id) });

  const mutation = useMutation({
    mutationFn: (favourite: boolean) => setFavourite(id, favourite),
    // 1. Before the server answers: change the cache, and remember the old value
    onMutate: async (favourite) => {
      await client.cancelQueries({ queryKey: key });
      const previous = client.getQueryData<Product>(key);
      client.setQueryData<Product>(key, (old) => (old ? { ...old, favourite } : old));
      return { previous };
    },
    // 2. If it fails: put the old value back
    onError: (_error, _favourite, context) => {
      client.setQueryData(key, context?.previous);
    },
    // 3. Either way: ask the server for the truth
    onSettled: () => client.invalidateQueries({ queryKey: key }),
  });

  if (!product.data) return <p className="muted">{w_loading}</p>;
  const on = product.data.favourite;
  return (
    <div className="card">
      <h2>{product.data.name}</h2>
      <button aria-pressed={on} className={on ? "" : "secondary"} onClick={() => mutation.mutate(!on)}>
        {on ? "♥ {w_fav}" : "♡ {w_fav}"}
      </button>
      {mutation.isPending && <span className="muted"> {w_saving}</span>}
      {mutation.isError && <p className="error">{w_failed}</p>}
    </div>
  );
}
'''

FAV_PAGE = '''// For the book's screenshots only.
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { FavouriteButton } from "./favourite";
import { server } from "../api";

server.failNextSave = false;

createRoot(document.getElementById("root")!).render(
  <QueryClientProvider client={new QueryClient()}>
    <FavouriteButton id={2} />
  </QueryClientProvider>,
);
'''
BROWSER["projects/fav-page.tsx"] = (FAV_PAGE, CSS)
BROWSER["projects/fav-fail-page.tsx"] = (FAV_PAGE.replace(
    "server.failNextSave = false;", "server.failNextSave = true; // the next save fails, to show the rollback"), CSS)

kit.generate(HERE, T, plain=PLAIN, browser_files=BROWSER)
