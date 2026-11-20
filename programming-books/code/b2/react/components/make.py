"""Writes the examples of Book 2 (React edition), chapter "Components and Rendering", in English and Arabic.
Run: python3 make.py   (from anywhere; needs `npm ci` in code/b2 and `node vendor/make.mjs` once)

*.tsx are the listings. Files marked NODE are bundled to .mjs and run by the book to show what they print;
the others are bundled for the browser with an .html page, and the book takes screenshots of them.
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        name="Sara", hello="Hello,", welcome="Welcome back to the shop", items="items in your cart",
        book="Code from Zero", mug="Bit mug", sticker="Bit sticker", cap="Bit cap",
        add="Add to cart", sold="Sold out", new="New", currency="EGP", shop="Bit's shop",
        loading="Loading your orders…", empty="You have no orders yet.", error="Could not load your orders:",
        offline="you are offline", orders="orders", retry="Try again", w_likes="likes", w_like="Like", w_liked="Liked",
        visits="Visitors so far:", first_render="First render:", second_render="Second render:",
        c_pure="Bad: changes a variable outside the component while rendering",
        title_profile="Profile", role="Frontend developer", city="Alexandria", w_follow="Follow", w_following="Following",
        bio="I build fast, accessible web apps with React and TypeScript.", w_projects="projects", w_followers="followers",
        all="All", books="Books", gifts="Gifts", showing="Showing", of="of", w_products="products", cat_title="Catalogue",
        tab1="Description", tab2="Reviews", tab3="Shipping",
        tab1_text="A friendly guide that takes you from your first line of code to your first app.",
        tab2_text="“Clear, kind and practical. My son finished it in a month.” ★★★★★",
        tab3_text="Free delivery in Egypt for orders over 50 EGP. Arrives in 2–4 days.",
        tabs_title="Product details",
    ),
    "ar": dict(
        name="سارة", hello="أهلاً يا", welcome="مرحباً بعودتك إلى المتجر", items="عناصر في سلتك",
        book="البرمجة من الصفر", mug="كوب بِت", sticker="ملصق بِت", cap="قبعة بِت",
        add="أضف إلى السلة", sold="نفدت الكمية", new="جديد", currency="جنيهاً", shop="متجر بِت",
        loading="جارٍ تحميل طلباتك…", empty="ليست لديك طلبات بعد.", error="تعذّر تحميل طلباتك:",
        offline="أنت غير متصل", orders="طلبات", retry="حاول مرة أخرى", w_likes="إعجاب", w_like="أعجبني", w_liked="أعجبك",
        visits="الزوار حتى الآن:", first_render="الرسم الأول:", second_render="الرسم الثاني:",
        c_pure="خطأ: يغيّر متغيراً خارج المكوّن أثناء الرسم",
        title_profile="الملف الشخصي", role="مطورة واجهات", city="الإسكندرية", w_follow="تابِع", w_following="تتابعها",
        bio="أبني تطبيقات ويب سريعة وسهلة الوصول بـ React وTypeScript.", w_projects="مشاريع", w_followers="متابعون",
        all="الكل", books="كتب", gifts="هدايا", showing="يظهر", of="من", w_products="منتجات", cat_title="الكتالوج",
        tab1="الوصف", tab2="المراجعات", tab3="الشحن",
        tab1_text="دليل ودود يأخذك من أول سطر كود إلى أول تطبيق لك.",
        tab2_text="«واضح ولطيف وعملي. أنهاه ابني في شهر.» ★★★★★",
        tab3_text="توصيل مجاني داخل مصر للطلبات فوق 50 جنيهاً. يصل خلال 2 إلى 4 أيام.",
        tabs_title="تفاصيل المنتج",
    ),
}

NODE = {}      # name -> source, bundled for Node and run by the book
BROWSER = {}   # name -> (source, css), bundled for the browser and screenshot by the book

# ---------------------------------------------------------------- printed examples
NODE["first.tsx"] = '''import { renderToStaticMarkup } from "react-dom/server";

function Greeting() {
  return <h1>{hello} {name}!</h1>;
}

console.log(renderToStaticMarkup(<Greeting />));
'''

NODE["jsx.tsx"] = '''import { renderToStaticMarkup } from "react-dom/server";

function CartSummary({ count, total }: { count: number; total: number }) {
  const isEmpty = count === 0;
  return (
    <>
      <p className="summary">
        {count} {items}: {total.toFixed(2)} {currency}
      </p>
      <button disabled={isEmpty} style={{ fontWeight: 700 }}>
        {add}
      </button>
    </>
  );
}

console.log(renderToStaticMarkup(<CartSummary count={3} total={41} />));
'''

NODE["impure.tsx"] = '''import { renderToStaticMarkup } from "react-dom/server";

let visitors = 0;

function Counter() {
  visitors = visitors + 1; // {c_pure}
  return <p>{visits} {visitors}</p>;
}

console.log("{first_render}", renderToStaticMarkup(<Counter />));
console.log("{second_render}", renderToStaticMarkup(<Counter />));
'''

# ---------------------------------------------------------------- the shop, in steps
PRODUCTS = '''export type Product = {
  id: number;
  name: string;
  price: number;
  category: "books" | "gifts";
  isNew?: boolean;
  inStock: boolean;
};

export const products: Product[] = [
  { id: 1, name: "{book}", price: 25, category: "books", isNew: true, inStock: true },
  { id: 2, name: "{mug}", price: 8, category: "gifts", inStock: true },
  { id: 3, name: "{sticker}", price: 3, category: "gifts", inStock: false },
  { id: 4, name: "{cap}", price: 12, category: "gifts", isNew: true, inStock: true },
];
'''

CARD_CSS = """.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.card { background: white; border-radius: 14px; padding: 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); display: flex; flex-direction: column; gap: 6px; }
.card h3 { font-size: 1rem; margin: 0; color: #1e1b2e; }
.price { font-weight: 700; color: #4338ca; margin: 0; }
.badge { align-self: flex-start; font-size: 0.75rem; font-weight: 700; padding: 1px 8px; border-radius: 999px; background: #fef3c7; color: #92400e; }
.card button:disabled { background: #e5e7eb; color: #6b7280; cursor: not-allowed; }
"""

BROWSER["cards.tsx"] = ('''import { createRoot } from "react-dom/client";
import type { ReactNode } from "react";
import { products, type Product } from "./products";

type ProductCardProps = {
  product: Product;
  onAdd?: (id: number) => void;
};

function ProductCard({ product, onAdd }: ProductCardProps) {
  return (
    <article className="card">
      {product.isNew && <span className="badge">{new}</span>}
      <h3>{product.name}</h3>
      <p className="price">
        {product.price.toFixed(2)} {currency}
      </p>
      <button disabled={!product.inStock} onClick={() => onAdd?.(product.id)}>
        {product.inStock ? "{add}" : "{sold}"}
      </button>
    </article>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section>
      <h2>{title}</h2>
      {children}
    </section>
  );
}

function App() {
  return (
    <Section title="{shop}">
      <div className="grid">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </Section>
  );
}

createRoot(document.getElementById("root")!).render(<App />);
''', CARD_CSS)

STATUS_CSS = """.panel { background: white; border-radius: 14px; padding: 12px 14px; margin-bottom: 10px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
.panel p { margin: 0; }
.muted { color: #5b5873; }
.error { color: #b91c1c; display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.spinner { display: inline-block; width: 14px; height: 14px; border: 3px solid #c7d2fe; border-top-color: #4338ca; border-radius: 50%; margin-inline-end: 8px; vertical-align: -2px; }
ul { margin: 0; padding-inline-start: 20px; }
"""

BROWSER["status.tsx"] = ('''import { createRoot } from "react-dom/client";

type Orders =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "success"; orders: string[] };

function OrderList({ state }: { state: Orders }) {
  if (state.status === "loading") {
    return (
      <p className="muted">
        <span className="spinner" />
        {loading}
      </p>
    );
  }
  if (state.status === "error") {
    return (
      <p className="error">
        {error} {state.message}
        <button className="secondary">{retry}</button>
      </p>
    );
  }
  if (state.orders.length === 0) {
    return <p className="muted">{empty}</p>;
  }
  return (
    <ul>
      {state.orders.map((order) => (
        <li key={order}>{order}</li>
      ))}
    </ul>
  );
}

const examples: Orders[] = [
  { status: "loading" },
  { status: "error", message: "{offline}" },
  { status: "success", orders: [] },
  { status: "success", orders: ["#1042 · {book}", "#1043 · {mug}"] },
];

createRoot(document.getElementById("root")!).render(
  <>
    {examples.map((state, i) => (
      <div className="panel" key={i}>
        <OrderList state={state} />
      </div>
    ))}
  </>,
);
''', STATUS_CSS)

BROWSER["like.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";

function LikeButton({ initial }: { initial: number }) {
  const [likes, setLikes] = useState(initial);
  const [liked, setLiked] = useState(false);

  function toggle() {
    setLiked(!liked);
    setLikes(liked ? likes - 1 : likes + 1);
  }

  return (
    <button className={liked ? "" : "secondary"} aria-pressed={liked} onClick={toggle}>
      {liked ? "♥ {w_liked}" : "♡ {w_like}"} · {likes} {w_likes}
    </button>
  );
}

createRoot(document.getElementById("root")!).render(
  <p style={{ display: "flex", gap: 8 }}>
    <LikeButton initial={41} />
    <LikeButton initial={7} />
  </p>,
);
''', "")

# ---------------------------------------------------------------- projects
PROFILE_CSS = """.profile { max-width: 340px; background: white; border-radius: 18px; overflow: hidden; box-shadow: 0 4px 18px rgb(67 56 202 / 0.15); }
.cover { height: 70px; background: linear-gradient(135deg, #4338ca, #db2777); }
.body { padding: 0 18px 18px; }
.avatar { width: 72px; height: 72px; border-radius: 50%; border: 4px solid white; margin-top: -36px; background: #fbbf24; display: grid; place-items: center; font-size: 1.8rem; font-weight: 700; color: #1e1b2e; }
.body h2 { margin: 6px 0 0; color: #1e1b2e; }
.meta { color: #5b5873; margin: 0 0 8px; }
.stats { display: flex; gap: 18px; margin: 10px 0 14px; }
.stats b { display: block; font-size: 1.1rem; color: #4338ca; }
"""

BROWSER["projects/profile.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import type { ReactNode } from "react";

type Person = { name: string; role: string; city: string; projects: number; followers: number };

function Avatar({ name }: { name: string }) {
  return (
    <div className="avatar" aria-hidden="true">
      {name[0]}
    </div>
  );
}

function Stat({ value, label }: { value: number; label: string }) {
  return (
    <span>
      <b>{value}</b>
      {label}
    </span>
  );
}

function ProfileCard({ person, children }: { person: Person; children: ReactNode }) {
  const [following, setFollowing] = useState(false);
  const followers = person.followers + (following ? 1 : 0);
  return (
    <article className="profile">
      <div className="cover" />
      <div className="body">
        <Avatar name={person.name} />
        <h2>{person.name}</h2>
        <p className="meta">
          {person.role} · {person.city}
        </p>
        {children}
        <div className="stats">
          <Stat value={person.projects} label="{w_projects}" />
          <Stat value={followers} label="{w_followers}" />
        </div>
        <button className={following ? "secondary" : ""} aria-pressed={following} onClick={() => setFollowing(!following)}>
          {following ? "{w_following}" : "{w_follow}"}
        </button>
      </div>
    </article>
  );
}

const sara: Person = { name: "{name}", role: "{role}", city: "{city}", projects: 12, followers: 340 };

createRoot(document.getElementById("root")!).render(
  <ProfileCard person={sara}>
    <p>{bio}</p>
  </ProfileCard>,
);
''', PROFILE_CSS)

CATALOGUE_CSS = CARD_CSS + """.filters { display: flex; gap: 6px; margin: 4px 0 6px; }
.count { color: #5b5873; margin: 0 0 10px; }
"""

BROWSER["projects/catalogue.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { products, type Product } from "../products";

type Filter = "all" | Product["category"];

const FILTERS: { value: Filter; label: string }[] = [
  { value: "all", label: "{all}" },
  { value: "books", label: "{books}" },
  { value: "gifts", label: "{gifts}" },
];

function ProductCard({ product }: { product: Product }) {
  return (
    <article className="card">
      {product.isNew && <span className="badge">{new}</span>}
      <h3>{product.name}</h3>
      <p className="price">
        {product.price.toFixed(2)} {currency}
      </p>
    </article>
  );
}

function Catalogue() {
  const [filter, setFilter] = useState<Filter>("all");
  const visible = filter === "all" ? products : products.filter((p) => p.category === filter);

  return (
    <section>
      <h2>{cat_title}</h2>
      <div className="filters" role="group" aria-label="{cat_title}">
        {FILTERS.map(({ value, label }) => (
          <button
            key={value}
            className={value === filter ? "" : "secondary"}
            aria-pressed={value === filter}
            onClick={() => setFilter(value)}
          >
            {label}
          </button>
        ))}
      </div>
      <p className="count">
        {showing} {visible.length} {of} {products.length} {w_products}
      </p>
      <div className="grid">
        {visible.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </section>
  );
}

createRoot(document.getElementById("root")!).render(<Catalogue />);
''', CATALOGUE_CSS)

TABS_CSS = """.tabs { max-width: 460px; background: white; border-radius: 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); overflow: hidden; }
[role="tablist"] { display: flex; border-bottom: 2px solid #e0e7ff; }
[role="tab"] { flex: 1; border-radius: 0; background: none; color: #5b5873; padding: 10px; border-bottom: 3px solid transparent; margin-bottom: -2px; }
[role="tab"][aria-selected="true"] { color: #4338ca; font-weight: 700; border-bottom-color: #4338ca; }
[role="tabpanel"] { padding: 14px 16px; }
"""

BROWSER["projects/tabs.tsx"] = ('''import { useId, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import type { KeyboardEvent, ReactNode } from "react";

type Tab = { label: string; content: ReactNode };

function Tabs({ tabs, label }: { tabs: Tab[]; label: string }) {
  const [active, setActive] = useState(0);
  const id = useId();
  const buttons = useRef<(HTMLButtonElement | null)[]>([]);

  function select(index: number) {
    const next = (index + tabs.length) % tabs.length;
    setActive(next);
    buttons.current[next]?.focus();
  }

  function onKeyDown(event: KeyboardEvent) {
    const rtl = document.dir === "rtl";
    if (event.key === "ArrowRight") select(active + (rtl ? -1 : 1));
    if (event.key === "ArrowLeft") select(active + (rtl ? 1 : -1));
    if (event.key === "Home") select(0);
    if (event.key === "End") select(tabs.length - 1);
  }

  return (
    <div className="tabs">
      <div role="tablist" aria-label={label} onKeyDown={onKeyDown}>
        {tabs.map((tab, i) => (
          <button
            key={tab.label}
            ref={(el) => {
              buttons.current[i] = el;
            }}
            role="tab"
            id={`${id}-tab-${i}`}
            aria-selected={i === active}
            aria-controls={`${id}-panel-${i}`}
            tabIndex={i === active ? 0 : -1}
            onClick={() => select(i)}
          >
            {tab.label}
          </button>
        ))}
      </div>
      {tabs.map((tab, i) => (
        <div
          key={tab.label}
          role="tabpanel"
          id={`${id}-panel-${i}`}
          aria-labelledby={`${id}-tab-${i}`}
          hidden={i !== active}
        >
          {tab.content}
        </div>
      ))}
    </div>
  );
}

createRoot(document.getElementById("root")!).render(
  <Tabs
    label="{tabs_title}"
    tabs={[
      { label: "{tab1}", content: <p>{tab1_text}</p> },
      { label: "{tab2}", content: <p>{tab2_text}</p> },
      { label: "{tab3}", content: <p>{tab3_text}</p> },
    ]}
  />,
);
''', TABS_CSS)


def fill(text, t):
    # {key} is replaced by the language's text, but only where the key exists, so JSX like {product.name}
    # and template literals like ${id} are left alone.
    return re.sub(r"(?<![$\w])\{(\w+)\}", lambda m: t[m.group(1)] if m.group(1) in t else m.group(0), text)


for lang, words in T.items():
    t = dict(words)
    out = HERE / lang
    (out / "products.ts").parent.mkdir(parents=True, exist_ok=True)
    (out / "products.ts").write_text(fill(PRODUCTS, t))
    for name, src in NODE.items():
        tsx = out / name
        tsx.write_text(fill(src, t))
        kit.node(tsx, tsx.with_suffix(".mjs"))
    for name, (src, css) in BROWSER.items():
        tsx = out / name
        tsx.parent.mkdir(parents=True, exist_ok=True)
        tsx.write_text(fill(src, t))
        kit.browser(tsx, tsx.with_suffix(".js"))
        kit.page(tsx.parent, tsx.stem, lang, t["shop"], css)
    print("ok", lang)
