"""Writes the examples of Book 2 (Vue edition), chapter "Reactivity and the Composition API", in English and Arabic.
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
        w_title="Reactivity", w_book="Code from Zero", w_mug="Bit mug", w_cap="Bit cap", w_total="Total",
        w_currency="EGP", w_items="Items", w_remove="Remove", w_empty="Your cart is empty.", w_free="Free delivery!",
        w_more="more for free delivery", w_add="Add", w_qty="Quantity",
        w_copy="Copied value:", w_linked="Linked ref:", w_sync="Right after the changes:", w_after="After nextTick",
        w_c_effect="Runs now, and again whenever something it read changes",
        w_c_coupon="Nothing printed: the total never read the coupon",
        w_c_copy="Destructuring copies the number once; toRefs keeps a link to the object",
        w_c_batch="Three changes, one run of the watcher, with the first and last values",
        w_c_min="Only the lines are state; everything else is computed from them",
        w_c_clean="Runs before the next run of the watcher, and when the component is removed",
        w_c_model="defineModel: a prop and an event in one ref, for v-model",
        w_start="Start", w_stop="Stop", w_seconds="seconds",
        w_ordered="You ordered", w_step="Step", w_undo="Undo", w_history="History", w_reset="Reset",
        w_task="New task", w_tasks="Tasks", w_left="left", w_clear="Clear done", w_t1="Read chapter 5",
        w_t2="Write a composable", w_t3="Test it with Vitest",
        w_search="Search products", w_searching="Searching for", w_noresults="No products match", w_results="results",
        w_c_abort="If the user types again, cancel the old request",
    ),
    "ar": dict(
        w_title="التفاعلية", w_book="البرمجة من الصفر", w_mug="كوب بِت", w_cap="قبعة بِت", w_total="المجموع",
        w_currency="جنيهاً", w_items="العناصر", w_remove="احذف", w_empty="سلتك فارغة.", w_free="توصيل مجاني!",
        w_more="أخرى للتوصيل المجاني", w_add="أضف", w_qty="الكمية",
        w_copy="القيمة المنسوخة:", w_linked="المرجع المرتبط:", w_sync="بعد التغييرات مباشرة:", w_after="بعد nextTick",
        w_c_effect="تعمل الآن، ومن جديد كلما تغير شيء قرأته",
        w_c_coupon="لا شيء يُطبع: المجموع لم يقرأ الكوبون أبداً",
        w_c_copy="التفكيك ينسخ العدد مرة واحدة، وtoRefs تحفظ رابطاً بالكائن",
        w_c_batch="ثلاثة تغييرات، ومرة واحدة للمراقب، بالقيمتين الأولى والأخيرة",
        w_c_min="السطور وحدها حالة، وكل ما عداها محسوب منها",
        w_c_clean="تعمل قبل المرة التالية للمراقب، وحين يُزال المكوّن",
        w_c_model="defineModel: خاصية وحدث في مرجع واحد، من أجل v-model",
        w_start="ابدأ", w_stop="أوقف", w_seconds="ثانية",
        w_ordered="طلبت", w_step="الخطوة", w_undo="تراجع", w_history="السجل", w_reset="صفّر",
        w_task="مهمة جديدة", w_tasks="المهام", w_left="متبقية", w_clear="احذف المنجزة", w_t1="اقرأ الفصل 5",
        w_t2="اكتب composable", w_t3="اختبره بـ Vitest",
        w_search="ابحث في المنتجات", w_searching="جارٍ البحث عن", w_noresults="لا منتجات تطابق", w_results="نتائج",
        w_c_abort="إن كتب المستخدم من جديد، فألغِ الطلب القديم",
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

# ---------------------------------------------------------------- how reactivity works
NODE["reactivity.ts"] = '''import { computed, effect, reactive } from "vue";

const cart = reactive({
  lines: [] as { name: string; price: number; quantity: number }[],
  coupon: "",
});
const total = computed(() => cart.lines.reduce((sum, l) => sum + l.price * l.quantity, 0));

// {w_c_effect}
effect(() => console.log(`{w_total}: ${total.value}`));

cart.lines.push({ name: "{w_mug}", price: 8, quantity: 1 });
cart.lines.push({ name: "{w_book}", price: 25, quantity: 1 });
cart.lines[0]!.quantity = 3;
cart.coupon = "BIT10"; // {w_c_coupon}
'''

NODE["lost.ts"] = '''import { reactive, toRefs } from "vue";

const product = reactive({ name: "{w_mug}", stock: 3 });

// {w_c_copy}
const { stock } = product;
const { stock: stockRef } = toRefs(product);

product.stock = 2;
console.log("{w_copy}", stock);
console.log("{w_linked}", stockRef.value);
'''

NODE["batching.ts"] = '''import { nextTick, ref, watch } from "vue";

const count = ref(0);
// {w_c_batch}
watch(count, (now, before) => console.log(`watch: ${before} → ${now}`));

count.value++;
count.value++;
count.value++;
console.log("{w_sync}", count.value);
await nextTick();
console.log("{w_after}");
'''

# ---------------------------------------------------------------- the cart
PLAIN["cart-model.ts"] = '''export type Product = { id: number; name: string; price: number };
export type Line = { product: Product; quantity: number };

export const catalogue: Product[] = [
  { id: 1, name: "{w_book}", price: 25 },
  { id: 2, name: "{w_mug}", price: 8 },
  { id: 3, name: "{w_cap}", price: 12 },
];

export const FREE_DELIVERY = 50;
'''

CART_CSS = """.cart { max-width: 460px; background: white; border-radius: 14px; padding: 14px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
.row { display: flex; gap: 6px; margin-bottom: 10px; flex-wrap: wrap; }
ul { list-style: none; padding: 0; margin: 0 0 10px; }
li { display: flex; justify-content: space-between; align-items: center; gap: 8px; padding: 6px 0; border-bottom: 1px solid #eef2ff; }
.total { font-weight: 700; color: #4338ca; }
.free { color: #047857; font-weight: 700; }
.muted { color: #5b5873; }
.bar { height: 8px; border-radius: 999px; background: #e0e7ff; overflow: hidden; margin: 6px 0; }
.bar span { display: block; height: 100%; background: #4338ca; }
"""
PLAIN["Cart.vue"] = '''<script setup lang="ts">
import { computed, ref } from "vue";
import { catalogue, FREE_DELIVERY, type Line, type Product } from "./cart-model";

// {w_c_min}
const lines = ref<Line[]>([]);

const count = computed(() => lines.value.reduce((n, l) => n + l.quantity, 0));
const total = computed(() => lines.value.reduce((sum, l) => sum + l.product.price * l.quantity, 0));
const missing = computed(() => Math.max(0, FREE_DELIVERY - total.value));

function add(product: Product) {
  const line = lines.value.find((l) => l.product.id === product.id);
  if (line) line.quantity++;
  else lines.value.push({ product, quantity: 1 });
}

function remove(id: number) {
  lines.value = lines.value.filter((l) => l.product.id !== id);
}
</script>

<template>
  <section class="cart">
    <div class="row">
      <button v-for="p in catalogue" :key="p.id" type="button" class="secondary" @click="add(p)">
        {w_add} {{ p.name }}
      </button>
    </div>
    <p v-if="lines.length === 0" class="muted">{w_empty}</p>
    <ul v-else>
      <li v-for="line in lines" :key="line.product.id">
        <span>{{ line.product.name }} × {{ line.quantity }}</span>
        <button type="button" class="secondary" @click="remove(line.product.id)">{w_remove}</button>
      </li>
    </ul>
    <p>{w_items}: {{ count }} · <span class="total">{w_total}: {{ total }} {w_currency}</span></p>
    <div class="bar" aria-hidden="true"><span :style="{ width: `${Math.min(100, (total / 50) * 100)}%` }" /></div>
    <p v-if="missing === 0" class="free">{w_free}</p>
    <p v-else class="muted">{{ missing }} {w_currency} {w_more}</p>
  </section>
</template>
'''
BROWSER["cart.ts"] = ('''import { createApp } from "vue";
import Cart from "./Cart.vue";

createApp(Cart).mount("#app");
''', CART_CSS)

# ---------------------------------------------------------------- watchers and the lifecycle
PLAIN["Timer.vue"] = '''<script setup lang="ts">
import { onWatcherCleanup, ref, watch } from "vue";

const running = ref(false);
const seconds = ref(0);

watch(running, (on) => {
  if (!on) return;
  const id = setInterval(() => seconds.value++, 1000);
  // {w_c_clean}
  onWatcherCleanup(() => clearInterval(id));
});
</script>

<template>
  <p>
    <strong>{{ seconds }}</strong> {w_seconds}
    <button type="button" :aria-pressed="running" @click="running = !running">
      {{ running ? "{w_stop}" : "{w_start}" }}
    </button>
  </p>
</template>
'''
BROWSER["timer.ts"] = ('''import { createApp } from "vue";
import Timer from "./Timer.vue";

createApp(Timer).mount("#app");
''', "strong { font-size: 2rem; color: #4338ca; }\n")

# ---------------------------------------------------------------- v-model on a component
PLAIN["QuantityInput.vue"] = '''<script setup lang="ts">
// {w_c_model}
const quantity = defineModel<number>({ required: true });
const props = defineProps<{ max: number; label: string }>();
</script>

<template>
  <div class="quantity" role="group" :aria-label="label">
    <button type="button" class="secondary" :disabled="quantity <= 1" aria-label="−1" @click="quantity--">−</button>
    <output>{{ quantity }}</output>
    <button type="button" class="secondary" :disabled="quantity >= props.max" aria-label="+1" @click="quantity++">+</button>
  </div>
</template>
'''
PLAIN["Order.vue"] = '''<script setup lang="ts">
import { ref } from "vue";
import QuantityInput from "./QuantityInput.vue";

const mugs = ref(1);
</script>

<template>
  <p>{w_mug}</p>
  <QuantityInput v-model="mugs" :max="5" label="{w_qty}" />
  <p>{w_ordered}: {{ mugs }} · {w_total}: {{ mugs * 8 }} {w_currency}</p>
</template>
'''
BROWSER["order.ts"] = ('''import { createApp } from "vue";
import Order from "./Order.vue";

createApp(Order).mount("#app");
''', ".quantity { display: inline-flex; gap: 10px; align-items: center; } output { min-width: 2ch; text-align: center; font-weight: 700; font-size: 1.2rem; }\n")

# ---------------------------------------------------------------- projects
PLAIN["projects/History.vue"] = '''<script setup lang="ts">
import { computed, ref } from "vue";

const step = ref(1);
const history = ref<number[]>([0]);
const value = computed(() => history.value.at(-1) ?? 0);

function change(by: number) {
  history.value.push(value.value + by);
}

function undo() {
  if (history.value.length > 1) history.value.pop();
}
</script>

<template>
  <p class="value" aria-live="polite">{{ value }}</p>
  <div class="row">
    <button type="button" class="secondary" @click="change(-step)">−{{ step }}</button>
    <button type="button" @click="change(step)">+{{ step }}</button>
    <button type="button" class="secondary" :disabled="history.length === 1" @click="undo">{w_undo}</button>
  </div>
  <label>{w_step} <input id="step" v-model.number="step" type="number" min="1" max="10" /></label>
  <p class="muted">{w_history}: {{ history.join(" → ") }}</p>
</template>
'''
BROWSER["projects/history.ts"] = ('''import { createApp } from "vue";
import History from "./History.vue";

createApp(History).mount("#app");
''', """.value { font-size: 2.4rem; font-weight: 800; color: #4338ca; margin: 0; }
.row { display: flex; gap: 6px; margin: 6px 0 10px; }
input { width: 4em; font: inherit; padding: 2px 6px; }
.muted { color: #5b5873; }
""")

PLAIN["projects/Tasks.vue"] = '''<script setup lang="ts">
import { computed, ref, watch } from "vue";

type Task = { id: number; text: string; done: boolean };

function load(): Task[] {
  try {
    return JSON.parse(localStorage.getItem("tasks") ?? "null") ?? defaults;
  } catch {
    return defaults;
  }
}
const defaults: Task[] = [{ id: 1, text: "{w_t1}", done: true }];

const tasks = ref<Task[]>(load());
const text = ref("");
const left = computed(() => tasks.value.filter((t) => !t.done).length);

watch(tasks, (now) => localStorage.setItem("tasks", JSON.stringify(now)), { deep: true });

function add() {
  if (!text.value.trim()) return;
  tasks.value.push({ id: Date.now(), text: text.value.trim(), done: false });
  text.value = "";
}
</script>

<template>
  <section class="card">
    <h2>{w_tasks} <small>({{ left }} {w_left})</small></h2>
    <form @submit.prevent="add">
      <label for="task" class="sr-only">{w_task}</label>
      <input id="task" v-model="text" placeholder="{w_task}" />
    </form>
    <ul>
      <li v-for="task in tasks" :key="task.id">
        <label :class="{ done: task.done }"><input v-model="task.done" type="checkbox" /> {{ task.text }}</label>
      </li>
    </ul>
    <button type="button" class="secondary" @click="tasks = tasks.filter((t) => !t.done)">{w_clear}</button>
  </section>
</template>
'''
BROWSER["projects/tasks.ts"] = ('''import { createApp } from "vue";
import Tasks from "./Tasks.vue";

createApp(Tasks).mount("#app");
''', """.card { max-width: 420px; background: white; border-radius: 14px; padding: 14px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); }
small { color: #5b5873; font-weight: 400; font-size: 0.9rem; }
form input { width: 100%; font: inherit; padding: 6px 10px; border: 2px solid #c7d2fe; border-radius: 10px; }
ul { list-style: none; padding: 0; } li { padding: 4px 0; }
.done { text-decoration: line-through; color: #5b5873; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); }
""")

PLAIN["fake-api.ts"] = '''import { catalogue, type Product } from "./cart-model";

// A pretend server: answers after a delay, slower for short queries, like a real search.
export function searchProducts(query: string, signal: AbortSignal): Promise<Product[]> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const q = query.trim().toLowerCase();
      resolve(catalogue.filter((p) => p.name.toLowerCase().includes(q)));
    }, 600 - query.length * 100);
    signal.addEventListener("abort", () => {
      clearTimeout(timer);
      reject(signal.reason);
    });
  });
}
'''
PLAIN["projects/Search.vue"] = '''<script setup lang="ts">
import { onWatcherCleanup, ref, watch } from "vue";
import { searchProducts } from "../fake-api";
import type { Product } from "../cart-model";

const query = ref("");
const results = ref<Product[]>([]);
const loading = ref(false);

watch(query, async (q) => {
  if (!q.trim()) {
    results.value = [];
    return;
  }
  // {w_c_abort}
  const controller = new AbortController();
  onWatcherCleanup(() => controller.abort());
  loading.value = true;
  try {
    results.value = await searchProducts(q, controller.signal);
    loading.value = false;
  } catch {
    // aborted: a newer search is already running
  }
});
</script>

<template>
  <label for="q">{w_search}</label>
  <input id="q" v-model="query" type="search" autocomplete="off" />
  <p v-if="loading" class="muted" role="status">{w_searching} “{{ query }}”…</p>
  <template v-else-if="query">
    <p role="status">{{ results.length }} {w_results}</p>
    <ul>
      <li v-for="p in results" :key="p.id">{{ p.name }}</li>
    </ul>
  </template>
</template>
'''
BROWSER["projects/search.ts"] = ('''import { createApp } from "vue";
import Search from "./Search.vue";

createApp(Search).mount("#app");
''', """label { display: block; font-weight: 600; } input { font: inherit; padding: 6px 10px; border: 2px solid #c7d2fe; border-radius: 10px; width: 100%; max-width: 320px; }
.muted { color: #5b5873; }
""")

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)

check = HERE.parents[1] / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("types ok")
