"""Writes the examples of Book 2 (Vue edition), chapter "Global State with Pinia", in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}. Every file is type-checked with vue-tsc.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import vue_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Global state", w_name="Sara", w_shop="Bit's shop", w_hello="Hello,", w_guest="Guest", w_signin="Sign in",
        w_signout="Sign out", w_light="Light", w_dark="Dark", w_theme="Dark theme", w_book="Code from Zero", w_mug="Bit mug",
        w_cap="Bit cap", w_add="Add", w_cart="Cart", w_total="Total", w_currency="EGP", w_clear="Empty the cart",
        w_empty="The cart is empty.", w_profile="Your profile", w_member="Member since 2025",
        w_added="added to the cart", w_removed="Removed", w_undo="Undo", w_close="Close", w_notices="Notifications",
        w_c_key="A typed key: inject() knows the type of what was provided",
        w_c_hook="A composable hides inject(), and fails clearly if the provider is missing",
        w_c_deep="Any component under the provider can read the user, however deep",
        w_c_store="A setup store: refs are state, computed are getters, functions are actions",
        w_c_saved="useLocalStorage keeps the lines in the browser and loads them on the next visit",
        w_c_refs="storeToRefs keeps state and getters reactive after destructuring; actions are plain functions",
        w_c_node="A store works without any component: the same code runs in Node and in tests",
        w_action="action:", w_with="with", w_changed="changed:", w_after="after $dispose:",
    ),
    "ar": dict(
        w_title="الحالة العامة", w_name="سارة", w_shop="متجر بِت", w_hello="أهلاً،", w_guest="زائر", w_signin="سجّل الدخول",
        w_signout="سجّل الخروج", w_light="فاتح", w_dark="داكن", w_theme="المظهر الداكن", w_book="البرمجة من الصفر", w_mug="كوب بِت",
        w_cap="قبعة بِت", w_add="أضف", w_cart="السلة", w_total="المجموع", w_currency="جنيهاً", w_clear="أفرغ السلة",
        w_empty="السلة فارغة.", w_profile="ملفك الشخصي", w_member="عضو منذ 2025",
        w_added="أُضيف إلى السلة", w_removed="حُذف", w_undo="تراجع", w_close="أغلق", w_notices="الإشعارات",
        w_c_key="مفتاح بنوعه: تعرف inject() نوع ما قُدِّم",
        w_c_hook="composable يخفي inject()، ويفشل بوضوح إن غاب المزوِّد",
        w_c_deep="أي مكوّن تحت المزوِّد يقرأ المستخدم، مهما كان عمقه",
        w_c_store="مخزن إعداد: المراجع حالة، والمحسوبة قيم مشتقة، والدوال أفعال",
        w_c_saved="useLocalStorage تحفظ السطور في المتصفح وتحمّلها في الزيارة التالية",
        w_c_refs="storeToRefs تُبقي الحالة والقيم المشتقة تفاعلية بعد التفكيك، والأفعال دوال عادية",
        w_c_node="المخزن يعمل دون أي مكوّن: الكود نفسه يعمل في Node وفي الاختبارات",
        w_action="فعل:", w_with="بـ", w_changed="تغيّر:", w_after="بعد ‎$dispose:",
    ),
}

CSS = """:root { --bg: #f5f5fb; --card: white; --ink: #1e1b2e; --muted: #5b5873; }
html.dark { --bg: #16142a; --card: #24213d; --ink: #eef2ff; --muted: #b8b5d6; }
html.dark h2 { color: #a5b4fc; }
body { background: var(--bg); color: var(--ink); }
header { display: flex; align-items: center; gap: 10px; background: var(--card); padding: 8px 12px; border-radius: 14px; margin-bottom: 12px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.12); }
header .brand { font-weight: 800; color: #818cf8; margin-inline-end: auto; }
.card { background: var(--card); border-radius: 14px; padding: 12px 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.12); margin-bottom: 10px; }
.muted { color: var(--muted); }
.row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.spread { justify-content: space-between; padding: 4px 0; }
.badge { background: #db2777; color: white; border-radius: 999px; padding: 0 8px; font-size: 0.85rem; font-weight: 700; }
ul { list-style: none; padding: 0; margin: 6px 0; }
li { display: flex; justify-content: space-between; padding: 4px 0; }
.toasts { position: fixed; inset-inline-end: 16px; bottom: 16px; display: flex; flex-direction: column; gap: 8px; width: 280px; list-style: none; margin: 0; padding: 0; }
.toast { background: #1e1b2e; color: #eef2ff; border-radius: 12px; padding: 10px 12px; display: flex; gap: 8px; align-items: center; box-shadow: 0 6px 18px rgb(0 0 0 / 0.25); }
.toast span { flex: 1; }
.toast button { padding: 2px 10px; }
"""

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

# ---------------------------------------------------------------- provide and inject
PLAIN["auth.ts"] = '''import { inject, provide, readonly, ref, type InjectionKey, type Ref } from "vue";

type User = { name: string };
type Auth = { user: Readonly<Ref<User | null>>; signIn: (name: string) => void; signOut: () => void };

// {w_c_key}
const AuthKey: InjectionKey<Auth> = Symbol("auth");

export function provideAuth() {
  const user = ref<User | null>(null);
  provide(AuthKey, {
    user: readonly(user),
    signIn: (name) => (user.value = { name }),
    signOut: () => (user.value = null),
  });
}

// {w_c_hook}
export function useAuth(): Auth {
  const auth = inject(AuthKey);
  if (!auth) throw new Error("useAuth() must be used inside a component that called provideAuth()");
  return auth;
}
'''
PLAIN["UserMenu.vue"] = '''<script setup lang="ts">
import { useAuth } from "./auth";

// {w_c_deep}
const { user, signIn, signOut } = useAuth();
</script>

<template>
  <button v-if="!user" type="button" @click="signIn('{w_name}')">{w_signin}</button>
  <span v-else class="row">
    {w_hello} {{ user.name }}
    <button type="button" class="secondary" @click="signOut">{w_signout}</button>
  </span>
</template>
'''
PLAIN["Profile.vue"] = '''<script setup lang="ts">
import { useAuth } from "./auth";

const { user } = useAuth();
</script>

<template>
  <section class="card">
    <h2>{w_profile}</h2>
    <p class="muted">{{ user ? `${user.name} · {w_member}` : "{w_guest}" }}</p>
  </section>
</template>
'''
PLAIN["AuthApp.vue"] = '''<script setup lang="ts">
import { provideAuth } from "./auth";
import Profile from "./Profile.vue";
import UserMenu from "./UserMenu.vue";

provideAuth();
</script>

<template>
  <header>
    <span class="brand">{w_shop}</span>
    <UserMenu />
  </header>
  <main>
    <Profile />
  </main>
</template>
'''
BROWSER["context.ts"] = ('''import { createApp } from "vue";
import AuthApp from "./AuthApp.vue";

createApp(AuthApp).mount("#app");
''', CSS)

# ---------------------------------------------------------------- Pinia
PLAIN["stores/cart.ts"] = '''import { computed } from "vue";
import { defineStore } from "pinia";
import { useLocalStorage } from "@vueuse/core";

export type Product = { id: number; name: string; price: number };
type Line = { product: Product; quantity: number };

// {w_c_store}
export const useCart = defineStore("cart", () => {
  // {w_c_saved}
  const lines = useLocalStorage<Record<number, Line>>("cart", {});

  const count = computed(() => Object.values(lines.value).reduce((n, l) => n + l.quantity, 0));
  const total = computed(() => Object.values(lines.value).reduce((n, l) => n + l.quantity * l.product.price, 0));

  function add(product: Product) {
    const line = lines.value[product.id];
    if (line) line.quantity++;
    else lines.value[product.id] = { product, quantity: 1 };
  }

  function clear() {
    lines.value = {};
  }

  return { lines, count, total, add, clear };
});
'''
PLAIN["CartBadge.vue"] = '''<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useCart } from "./stores/cart";

// {w_c_refs}
const { count } = storeToRefs(useCart());
</script>

<template>
  <span class="row">{w_cart} <span class="badge">{{ count }}</span></span>
</template>
'''
PLAIN["ProductList.vue"] = '''<script setup lang="ts">
import { useCart, type Product } from "./stores/cart";

const products: Product[] = [
  { id: 1, name: "{w_book}", price: 25 },
  { id: 2, name: "{w_mug}", price: 8 },
  { id: 3, name: "{w_cap}", price: 12 },
];
const { add } = useCart();
</script>

<template>
  <section class="card">
    <div v-for="p in products" :key="p.id" class="row spread">
      <span>{{ p.name }}</span>
      <button type="button" @click="add(p)">{w_add}</button>
    </div>
  </section>
</template>
'''
PLAIN["CartSummary.vue"] = '''<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useCart } from "./stores/cart";

const cart = useCart();
const { lines, total } = storeToRefs(cart);
</script>

<template>
  <p v-if="Object.keys(lines).length === 0" class="card muted">{w_empty}</p>
  <section v-else class="card">
    <ul>
      <li v-for="l in lines" :key="l.product.id">
        <span>{{ l.quantity }} × {{ l.product.name }}</span>
        <span>{{ l.quantity * l.product.price }} {w_currency}</span>
      </li>
    </ul>
    <p><b>{w_total}: {{ total }} {w_currency}</b></p>
    <button type="button" class="secondary" @click="cart.clear()">{w_clear}</button>
  </section>
</template>
'''
PLAIN["ShopApp.vue"] = '''<script setup lang="ts">
import CartBadge from "./CartBadge.vue";
import CartSummary from "./CartSummary.vue";
import ProductList from "./ProductList.vue";
</script>

<template>
  <header>
    <span class="brand">{w_shop}</span>
    <CartBadge />
  </header>
  <ProductList />
  <CartSummary />
</template>
'''
PLAIN["main.ts"] = '''import { createApp } from "vue";
import { createPinia } from "pinia";
import ShopApp from "./ShopApp.vue";

createApp(ShopApp).use(createPinia()).mount("#app");
'''
BROWSER["store.ts"] = ('''import { createApp } from "vue";
import { createPinia } from "pinia";
import ShopApp from "./ShopApp.vue";

localStorage.clear(); // for the screenshot: start with an empty cart
createApp(ShopApp).use(createPinia()).mount("#app");
''', CSS)

# ---------------------------------------------------------------- a store without components
NODE["store-node.ts"] = '''import { computed, ref } from "vue";
import { createPinia, defineStore, setActivePinia } from "pinia";

// {w_c_node}
const useCounter = defineStore("counter", () => {
  const count = ref(0);
  const double = computed(() => count.value * 2);
  const increase = (by = 1) => (count.value += by);
  return { count, double, increase };
});

setActivePinia(createPinia());
const counter = useCounter();

counter.$onAction(({ name, args }) => console.log("{w_action}", name, "{w_with}", args));
counter.$subscribe(() => console.log("{w_changed}", counter.count, "→ double", counter.double), { flush: "sync" });

counter.increase();
counter.increase(5);
counter.$dispose();
counter.increase();
console.log("{w_after}", counter.count);
'''

# ---------------------------------------------------------------- projects
PLAIN["projects/theme.ts"] = '''import { computed, inject, provide, watchEffect, type InjectionKey, type Ref } from "vue";
import { useLocalStorage, usePreferredDark } from "@vueuse/core";

type Theme = { dark: Readonly<Ref<boolean>>; toggle: () => void };
const ThemeKey: InjectionKey<Theme> = Symbol("theme");

export function provideTheme() {
  const system = usePreferredDark();
  const saved = useLocalStorage<boolean | null>("dark", null);
  const dark = computed(() => saved.value ?? system.value);
  watchEffect(() => document.documentElement.classList.toggle("dark", dark.value));
  provide(ThemeKey, { dark, toggle: () => (saved.value = !dark.value) });
}

export function useTheme(): Theme {
  const theme = inject(ThemeKey);
  if (!theme) throw new Error("useTheme() must be used inside a component that called provideTheme()");
  return theme;
}
'''
PLAIN["projects/ThemeButton.vue"] = '''<script setup lang="ts">
import { useTheme } from "./theme";

const { dark, toggle } = useTheme();
</script>

<template>
  <button type="button" :aria-pressed="dark" @click="toggle">{w_theme}</button>
</template>
'''
PLAIN["projects/ThemeApp.vue"] = '''<script setup lang="ts">
import Profile from "../Profile.vue";
import { provideAuth } from "../auth";
import ThemeButton from "./ThemeButton.vue";
import { provideTheme } from "./theme";

provideAuth();
provideTheme();
</script>

<template>
  <header>
    <span class="brand">{w_shop}</span>
    <ThemeButton />
  </header>
  <Profile />
</template>
'''
BROWSER["projects/theme-page.ts"] = ('''import { createApp } from "vue";
import ThemeApp from "./ThemeApp.vue";

localStorage.clear();
createApp(ThemeApp).mount("#app");
''', CSS)

PLAIN["projects/toasts.ts"] = '''import { defineStore } from "pinia";
import { ref } from "vue";

type Action = { label: string; run: () => void };
type Toast = { id: number; text: string; action?: Action | undefined };

export const useToasts = defineStore("toasts", () => {
  const toasts = ref<Toast[]>([]);
  let next = 1;

  function dismiss(id: number) {
    toasts.value = toasts.value.filter((t) => t.id !== id);
  }

  function notify(text: string, action?: Action) {
    const id = next++;
    toasts.value = [...toasts.value.slice(-2), { id, text, action }];
    setTimeout(() => dismiss(id), 5000);
  }

  return { toasts, notify, dismiss };
});
'''
PLAIN["projects/ToastList.vue"] = '''<script setup lang="ts">
import { useToasts } from "./toasts";

const store = useToasts();
</script>

<template>
  <Teleport to="body">
    <ul class="toasts" role="status" aria-live="polite" aria-label="{w_notices}">
      <li v-for="t in store.toasts" :key="t.id" class="toast">
        <span>{{ t.text }}</span>
        <button
          v-if="t.action"
          type="button"
          class="secondary"
          @click="t.action.run(), store.dismiss(t.id)"
        >
          {{ t.action.label }}
        </button>
        <button type="button" aria-label="{w_close}" @click="store.dismiss(t.id)">×</button>
      </li>
    </ul>
  </Teleport>
</template>
'''
PLAIN["projects/Shelf.vue"] = '''<script setup lang="ts">
import { ref } from "vue";
import ToastList from "./ToastList.vue";
import { useToasts } from "./toasts";

const { notify } = useToasts();
const items = ref(["{w_book}", "{w_mug}", "{w_cap}"]);

function remove(name: string) {
  items.value = items.value.filter((n) => n !== name);
  notify(`{w_removed}: ${name}`, { label: "{w_undo}", run: () => items.value.push(name) });
}
</script>

<template>
  <section class="card">
    <div v-for="name in items" :key="name" class="row spread">
      <span>{{ name }}</span>
      <span class="row">
        <button type="button" @click="notify(`${name} {w_added}`)">{w_add}</button>
        <button type="button" class="secondary" :aria-label="`{w_removed}: ${name}`" @click="remove(name)">×</button>
      </span>
    </div>
  </section>
  <ToastList />
</template>
'''
BROWSER["projects/toasts-page.ts"] = ('''import { createApp } from "vue";
import { createPinia } from "pinia";
import Shelf from "./Shelf.vue";

createApp(Shelf).use(createPinia()).mount("#app");
''', CSS + "body { min-height: 360px; }\n")

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)

check = HERE.parents[1] / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("types ok")
