"""Writes the examples of Book 2 (Vue edition), chapter "Components and Templates", in English and Arabic.
Run: python3 make.py   (needs `npm ci` in code/b2 and in code/b2/vue-check)

The .vue and .ts files are the listings. NODE entries are bundled for Node and run by the book to show what
they print (with Vue's renderToString); BROWSER entries are bundled with an .html page for screenshots.
Every file is type-checked with vue-tsc before the book uses it. Text placeholders are {w_…}.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import vue_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Bit's shop", w_name="Sara", w_hello="Hello,", w_items="items in your cart", w_currency="EGP",
        w_book="Code from Zero", w_mug="Bit mug", w_sticker="Bit sticker", w_cap="Bit cap",
        w_add="Add to cart", w_sold="Sold out", w_new="New", w_shop="Bit's shop",
        w_loading="Loading your orders…", w_empty="You have no orders yet.", w_error="Could not load your orders:",
        w_offline="you are offline", w_retry="Try again", w_likes="likes", w_like="Like", w_liked="Liked",
        w_method="Calls to the method:", w_computed="Calls to the computed value:",
        w_c_method="Runs again every time the template is drawn, for every place it is used",
        w_c_computed="Runs once, and again only when the cart changes",
        w_role="Frontend developer", w_city="Alexandria", w_follow="Follow", w_following="Following",
        w_bio="I build fast, accessible web apps with Vue and TypeScript.", w_projects="projects", w_followers="followers",
        w_all="All", w_books="Books", w_gifts="Gifts", w_showing="Showing", w_of="of", w_products="products",
        w_cat_title="Catalogue",
        w_tab1="Description", w_tab2="Reviews", w_tab3="Shipping",
        w_tab1_text="A friendly guide that takes you from your first line of code to your first app.",
        w_tab2_text="“Clear, kind and practical. My son finished it in a month.” ★★★★★",
        w_tab3_text="Free delivery in Egypt for orders over 50 EGP. Arrives in 2–4 days.",
        w_tabs_title="Product details",
    ),
    "ar": dict(
        w_title="متجر بِت", w_name="سارة", w_hello="أهلاً يا", w_items="عناصر في سلتك", w_currency="جنيهاً",
        w_book="البرمجة من الصفر", w_mug="كوب بِت", w_sticker="ملصق بِت", w_cap="قبعة بِت",
        w_add="أضف إلى السلة", w_sold="نفدت الكمية", w_new="جديد", w_shop="متجر بِت",
        w_loading="جارٍ تحميل طلباتك…", w_empty="ليست لديك طلبات بعد.", w_error="تعذّر تحميل طلباتك:",
        w_offline="أنت غير متصل", w_retry="حاول مرة أخرى", w_likes="إعجاب", w_like="أعجبني", w_liked="أعجبك",
        w_method="مرات استدعاء الدالة:", w_computed="مرات حساب القيمة المحسوبة:",
        w_c_method="تعمل من جديد في كل مرة يُرسم فيها القالب، ولكل مكان تُستخدم فيه",
        w_c_computed="تعمل مرة واحدة، ثم فقط حين تتغير السلة",
        w_role="مطورة واجهات", w_city="الإسكندرية", w_follow="تابِع", w_following="تتابعها",
        w_bio="أبني تطبيقات ويب سريعة وسهلة الوصول بـ Vue وTypeScript.", w_projects="مشاريع", w_followers="متابعون",
        w_all="الكل", w_books="كتب", w_gifts="هدايا", w_showing="يظهر", w_of="من", w_products="منتجات",
        w_cat_title="الكتالوج",
        w_tab1="الوصف", w_tab2="المراجعات", w_tab3="الشحن",
        w_tab1_text="دليل ودود يأخذك من أول سطر كود إلى أول تطبيق لك.",
        w_tab2_text="«واضح ولطيف وعملي. أنهاه ابني في شهر.» ★★★★★",
        w_tab3_text="توصيل مجاني داخل مصر للطلبات فوق 50 جنيهاً. يصل خلال 2 إلى 4 أيام.",
        w_tabs_title="تفاصيل المنتج",
    ),
}

PLAIN, NODE, BROWSER = {}, {}, {}

PLAIN["tsconfig.json"] = '''{
  "compilerOptions": {
    "strict": true, "noUncheckedIndexedAccess": true, "target": "es2024", "module": "esnext",
    "moduleResolution": "bundler", "lib": ["es2024", "dom", "dom.iterable"], "types": ["node"], "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["**/*.ts", "**/*.vue"]
}
'''

# ---------------------------------------------------------------- printed examples
PLAIN["Greeting.vue"] = '''<script setup lang="ts">
const name = "{w_name}";
</script>

<template>
  <h1>{w_hello} {{ name }}!</h1>
</template>
'''
NODE["first.ts"] = '''import { createSSRApp } from "vue";
import { renderToString } from "vue/server-renderer";
import Greeting from "./Greeting.vue";

console.log(await renderToString(createSSRApp(Greeting)));
'''

PLAIN["CartSummary.vue"] = '''<script setup lang="ts">
const props = defineProps<{ count: number; total: number }>();
const isEmpty = props.count === 0;
</script>

<template>
  <p class="summary" :class="{ empty: isEmpty }">
    {{ count }} {w_items}: {{ total.toFixed(2) }} {w_currency}
  </p>
  <button type="button" :disabled="isEmpty" :style="{ fontWeight: 700 }">{w_add}</button>
</template>
'''
NODE["template.ts"] = '''import { createSSRApp, h } from "vue";
import { renderToString } from "vue/server-renderer";
import CartSummary from "./CartSummary.vue";

console.log(await renderToString(createSSRApp({ render: () => h(CartSummary, { count: 3, total: 41 }) })));
console.log(await renderToString(createSSRApp({ render: () => h(CartSummary, { count: 0, total: 0 }) })));
'''

PLAIN["CartTotal.vue"] = '''<script setup lang="ts">
import { computed } from "vue";
import { counts } from "./counts";

const props = defineProps<{ prices: number[] }>();

// {w_c_method}
function totalMethod() {
  counts.method++;
  return props.prices.reduce((sum, p) => sum + p, 0);
}

// {w_c_computed}
const total = computed(() => {
  counts.computed++;
  return props.prices.reduce((sum, p) => sum + p, 0);
});
</script>

<template>
  <p>{{ totalMethod() }} = {{ totalMethod() }} = {{ totalMethod() }}</p>
  <p>{{ total }} = {{ total }} = {{ total }}</p>
</template>
'''
PLAIN["counts.ts"] = '''export const counts = { method: 0, computed: 0 };
'''
NODE["computed.ts"] = '''import { createSSRApp, h } from "vue";
import { renderToString } from "vue/server-renderer";
import CartTotal from "./CartTotal.vue";
import { counts } from "./counts";

console.log(await renderToString(createSSRApp({ render: () => h(CartTotal, { prices: [25, 8, 12] }) })));
console.log("{w_method}", counts.method);
console.log("{w_computed}", counts.computed);
'''

# ---------------------------------------------------------------- the shop, in steps
PLAIN["products.ts"] = '''export type Product = {
  id: number;
  name: string;
  price: number;
  category: "books" | "gifts";
  isNew?: boolean;
  inStock: boolean;
};

export const products: Product[] = [
  { id: 1, name: "{w_book}", price: 25, category: "books", isNew: true, inStock: true },
  { id: 2, name: "{w_mug}", price: 8, category: "gifts", inStock: true },
  { id: 3, name: "{w_sticker}", price: 3, category: "gifts", inStock: false },
  { id: 4, name: "{w_cap}", price: 12, category: "gifts", isNew: true, inStock: true },
];
'''

CARD_CSS = """.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.card { background: white; border-radius: 14px; padding: 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); display: flex; flex-direction: column; gap: 6px; }
.card h3 { font-size: 1rem; margin: 0; color: #1e1b2e; }
.price { font-weight: 700; color: #4338ca; margin: 0; }
.badge { align-self: flex-start; font-size: 0.75rem; font-weight: 700; padding: 1px 8px; border-radius: 999px; background: #fef3c7; color: #92400e; }
.card button:disabled { background: #e5e7eb; color: #6b7280; cursor: not-allowed; }
"""

PLAIN["ProductCard.vue"] = '''<script setup lang="ts">
import type { Product } from "./products";

defineProps<{ product: Product }>();
const emit = defineEmits<{ add: [id: number] }>();
</script>

<template>
  <article class="card">
    <span v-if="product.isNew" class="badge">{w_new}</span>
    <h3>{{ product.name }}</h3>
    <p class="price">{{ product.price.toFixed(2) }} {w_currency}</p>
    <button type="button" :disabled="!product.inStock" @click="emit('add', product.id)">
      {{ product.inStock ? "{w_add}" : "{w_sold}" }}
    </button>
  </article>
</template>
'''
PLAIN["ShopSection.vue"] = '''<script setup lang="ts">
defineProps<{ title: string }>();
</script>

<template>
  <section>
    <h2>{{ title }}</h2>
    <slot />
  </section>
</template>
'''
PLAIN["Shop.vue"] = '''<script setup lang="ts">
import ProductCard from "./ProductCard.vue";
import ShopSection from "./ShopSection.vue";
import { products } from "./products";
</script>

<template>
  <ShopSection title="{w_shop}">
    <div class="grid">
      <ProductCard v-for="product in products" :key="product.id" :product="product" />
    </div>
  </ShopSection>
</template>
'''
BROWSER["cards.ts"] = ('''import { createApp } from "vue";
import Shop from "./Shop.vue";

createApp(Shop).mount("#app");
''', CARD_CSS)

STATUS_CSS = """.panel { background: white; border-radius: 14px; padding: 12px 14px; margin-bottom: 10px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
.panel p { margin: 0; }
.muted { color: #5b5873; }
.error { color: #b91c1c; display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
.spinner { display: inline-block; width: 14px; height: 14px; border: 3px solid #c7d2fe; border-top-color: #4338ca; border-radius: 50%; margin-inline-end: 8px; vertical-align: -2px; }
ul { margin: 0; padding-inline-start: 20px; }
"""

PLAIN["orders.ts"] = '''export type Orders =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "success"; orders: string[] };
'''
PLAIN["OrderList.vue"] = '''<script setup lang="ts">
import type { Orders } from "./orders";

defineProps<{ state: Orders }>();
</script>

<template>
  <p v-if="state.status === 'loading'" class="muted"><span class="spinner" />{w_loading}</p>
  <p v-else-if="state.status === 'error'" class="error">
    {w_error} {{ state.message }}
    <button type="button" class="secondary">{w_retry}</button>
  </p>
  <p v-else-if="state.orders.length === 0" class="muted">{w_empty}</p>
  <ul v-else>
    <li v-for="order in state.orders" :key="order">{{ order }}</li>
  </ul>
</template>
'''
PLAIN["StatusDemo.vue"] = '''<script setup lang="ts">
import OrderList from "./OrderList.vue";
import type { Orders } from "./orders";

const examples: Orders[] = [
  { status: "loading" },
  { status: "error", message: "{w_offline}" },
  { status: "success", orders: [] },
  { status: "success", orders: ["#1042 · {w_book}", "#1043 · {w_mug}"] },
];
</script>

<template>
  <div v-for="(state, i) in examples" :key="i" class="panel">
    <OrderList :state="state" />
  </div>
</template>
'''
BROWSER["status.ts"] = ('''import { createApp } from "vue";
import StatusDemo from "./StatusDemo.vue";

createApp(StatusDemo).mount("#app");
''', STATUS_CSS)

PLAIN["LikeButton.vue"] = '''<script setup lang="ts">
import { ref } from "vue";

const props = defineProps<{ initial: number }>();
const likes = ref(props.initial);
const liked = ref(false);

function toggle() {
  liked.value = !liked.value;
  likes.value += liked.value ? 1 : -1;
}
</script>

<template>
  <button type="button" :class="{ secondary: !liked }" :aria-pressed="liked" @click="toggle">
    {{ liked ? "♥ {w_liked}" : "♡ {w_like}" }} · {{ likes }} {w_likes}
  </button>
</template>
'''
PLAIN["Likes.vue"] = '''<script setup lang="ts">
import LikeButton from "./LikeButton.vue";
</script>

<template>
  <p style="display: flex; gap: 8px">
    <LikeButton :initial="41" />
    <LikeButton :initial="7" />
  </p>
</template>
'''
BROWSER["like.ts"] = ('''import { createApp } from "vue";
import Likes from "./Likes.vue";

createApp(Likes).mount("#app");
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
PLAIN["projects/ProfileCard.vue"] = '''<script setup lang="ts">
import { computed, ref } from "vue";

export type Person = { name: string; role: string; city: string; projects: number; followers: number };

const props = defineProps<{ person: Person }>();
const following = ref(false);
const followers = computed(() => props.person.followers + (following.value ? 1 : 0));
</script>

<template>
  <article class="profile">
    <div class="cover" />
    <div class="body">
      <div class="avatar" aria-hidden="true">{{ person.name[0] }}</div>
      <h2>{{ person.name }}</h2>
      <p class="meta">{{ person.role }} · {{ person.city }}</p>
      <slot />
      <div class="stats">
        <span><b>{{ person.projects }}</b>{w_projects}</span>
        <span><b>{{ followers }}</b>{w_followers}</span>
      </div>
      <button type="button" :class="{ secondary: following }" :aria-pressed="following" @click="following = !following">
        {{ following ? "{w_following}" : "{w_follow}" }}
      </button>
    </div>
  </article>
</template>
'''
PLAIN["projects/Profile.vue"] = '''<script setup lang="ts">
import ProfileCard, { type Person } from "./ProfileCard.vue";

const sara: Person = { name: "{w_name}", role: "{w_role}", city: "{w_city}", projects: 12, followers: 340 };
</script>

<template>
  <ProfileCard :person="sara">
    <p>{w_bio}</p>
  </ProfileCard>
</template>
'''
BROWSER["projects/profile.ts"] = ('''import { createApp } from "vue";
import Profile from "./Profile.vue";

createApp(Profile).mount("#app");
''', PROFILE_CSS)

PLAIN["projects/Catalogue.vue"] = '''<script setup lang="ts">
import { computed, ref } from "vue";
import { products, type Product } from "../products";

type Filter = "all" | Product["category"];

const FILTERS: { value: Filter; label: string }[] = [
  { value: "all", label: "{w_all}" },
  { value: "books", label: "{w_books}" },
  { value: "gifts", label: "{w_gifts}" },
];

const filter = ref<Filter>("all");
const visible = computed(() => (filter.value === "all" ? products : products.filter((p) => p.category === filter.value)));
</script>

<template>
  <section>
    <h2>{w_cat_title}</h2>
    <div class="filters" role="group" aria-label="{w_cat_title}">
      <button
        v-for="f in FILTERS"
        :key="f.value"
        type="button"
        :class="{ secondary: f.value !== filter }"
        :aria-pressed="f.value === filter"
        @click="filter = f.value"
      >
        {{ f.label }}
      </button>
    </div>
    <p class="count">{w_showing} {{ visible.length }} {w_of} {{ products.length }} {w_products}</p>
    <div class="grid">
      <article v-for="product in visible" :key="product.id" class="card">
        <span v-if="product.isNew" class="badge">{w_new}</span>
        <h3>{{ product.name }}</h3>
        <p class="price">{{ product.price.toFixed(2) }} {w_currency}</p>
      </article>
    </div>
  </section>
</template>
'''
BROWSER["projects/catalogue.ts"] = ('''import { createApp } from "vue";
import Catalogue from "./Catalogue.vue";

createApp(Catalogue).mount("#app");
''', CARD_CSS + """.filters { display: flex; gap: 6px; margin: 4px 0 6px; }
.count { color: #5b5873; margin: 0 0 10px; }
""")

TABS_CSS = """.tabs { max-width: 460px; background: white; border-radius: 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); overflow: hidden; }
[role="tablist"] { display: flex; border-bottom: 2px solid #e0e7ff; }
[role="tab"] { flex: 1; border-radius: 0; background: none; color: #5b5873; padding: 10px; border-bottom: 3px solid transparent; margin-bottom: -2px; }
[role="tab"][aria-selected="true"] { color: #4338ca; font-weight: 700; border-bottom-color: #4338ca; }
[role="tabpanel"] { padding: 14px 16px; }
"""
PLAIN["projects/TabList.vue"] = '''<script setup lang="ts">
import { ref, useId, useTemplateRef } from "vue";

const props = defineProps<{ labels: string[]; label: string }>();
const active = ref(0);
const id = useId();
const buttons = useTemplateRef<HTMLButtonElement[]>("tab");

function select(index: number) {
  const next = (index + props.labels.length) % props.labels.length;
  active.value = next;
  buttons.value?.[next]?.focus();
}

function onKeydown(event: KeyboardEvent) {
  const rtl = document.dir === "rtl";
  if (event.key === "ArrowRight") select(active.value + (rtl ? -1 : 1));
  if (event.key === "ArrowLeft") select(active.value + (rtl ? 1 : -1));
  if (event.key === "Home") select(0);
  if (event.key === "End") select(props.labels.length - 1);
}
</script>

<template>
  <div class="tabs">
    <div role="tablist" :aria-label="label" @keydown="onKeydown">
      <button
        v-for="(text, i) in labels"
        :id="`${id}-tab-${i}`"
        ref="tab"
        :key="text"
        type="button"
        role="tab"
        :aria-selected="i === active"
        :aria-controls="`${id}-panel-${i}`"
        :tabindex="i === active ? 0 : -1"
        @click="select(i)"
      >
        {{ text }}
      </button>
    </div>
    <div
      v-for="(text, i) in labels"
      :id="`${id}-panel-${i}`"
      :key="text"
      role="tabpanel"
      :aria-labelledby="`${id}-tab-${i}`"
      :hidden="i !== active"
    >
      <slot :name="`tab-${i}`" />
    </div>
  </div>
</template>
'''
PLAIN["projects/Details.vue"] = '''<script setup lang="ts">
import TabList from "./TabList.vue";
</script>

<template>
  <TabList label="{w_tabs_title}" :labels="['{w_tab1}', '{w_tab2}', '{w_tab3}']">
    <template #tab-0><p>{w_tab1_text}</p></template>
    <template #tab-1><p>{w_tab2_text}</p></template>
    <template #tab-2><p>{w_tab3_text}</p></template>
  </TabList>
</template>
'''
BROWSER["projects/tabs.ts"] = ('''import { createApp } from "vue";
import Details from "./Details.vue";

createApp(Details).mount("#app");
''', TABS_CSS)

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)

# Every listing must pass the type checker before the book shows it
check = HERE.parents[1] / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("types ok")
