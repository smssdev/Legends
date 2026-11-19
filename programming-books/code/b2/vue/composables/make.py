"""Writes the examples of Book 2 (Vue edition), chapter "Composables: Reusing Logic", in English and Arabic.
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
        w_title="Composables", w_book="Code from Zero", w_mug="Bit mug", w_cap="Bit cap", w_sticker="Bit sticker",
        w_start="Start", w_stop="Stop", w_reset="Reset", w_seconds="seconds", w_lap="Lap",
        w_first="First call:", w_second="Second call:", w_shared="Shared by every call:",
        w_search="Search products", w_searching="Searching…", w_results="results", w_failed="Could not search:",
        w_online="Online", w_offline="Offline: changes will be saved when you are back", w_width="Window width:",
        w_theme="Dark theme", w_page="Page", w_of="of", w_prev="Previous", w_next="Next",
        w_c_use="A composable: a function that uses the Composition API and returns reactive state",
        w_c_fresh="Each call makes new refs: two components never share a stopwatch by accident",
        w_c_module="Created once, outside the function: everyone who calls it shares the same value",
        w_c_input="Accepts a value, a ref or a getter, so callers can pass whatever they have",
        w_c_abort="A new query cancels the request for the old one",
        w_c_dispose="Removed when the component (or any effect scope) that called it goes away",
        w_c_vueuse="The same idea from VueUse: saved in localStorage, kept in step across tabs",
        w_t_counts="counts seconds only while running", w_t_reset="reset stops and returns to zero",
        w_t_debounce="waits until the value has stopped changing", w_t_pages="splits a list into pages",
        w_t_clamp="never goes past the last page",
    ),
    "ar": dict(
        w_title="الـ composables", w_book="البرمجة من الصفر", w_mug="كوب بِت", w_cap="قبعة بِت", w_sticker="ملصق بِت",
        w_start="ابدأ", w_stop="أوقف", w_reset="صفّر", w_seconds="ثانية", w_lap="لفة",
        w_first="الاستدعاء الأول:", w_second="الاستدعاء الثاني:", w_shared="مشترك بين كل الاستدعاءات:",
        w_search="ابحث في المنتجات", w_searching="جارٍ البحث…", w_results="نتائج", w_failed="تعذّر البحث:",
        w_online="متصل", w_offline="غير متصل: ستُحفظ التغييرات حين تعود", w_width="عرض النافذة:",
        w_theme="المظهر الداكن", w_page="صفحة", w_of="من", w_prev="السابق", w_next="التالي",
        w_c_use="composable: دالة تستخدم واجهة التركيب وتُرجع حالة تفاعلية",
        w_c_fresh="كل استدعاء يصنع مراجع جديدة: فلا يتشارك مكونان مؤقتاً بالصدفة أبداً",
        w_c_module="يُنشأ مرة واحدة خارج الدالة: فكل من يستدعيها يتشارك القيمة نفسها",
        w_c_input="تقبل قيمة أو مرجعاً أو دالة قراءة، فيمرر المستدعي ما لديه",
        w_c_abort="الاستعلام الجديد يلغي طلب القديم",
        w_c_dispose="يُزال حين يذهب المكوّن (أو أي نطاق آثار) الذي استدعاه",
        w_c_vueuse="الفكرة نفسها من VueUse: محفوظ في localStorage ومتوافق بين الألسنة",
        w_t_counts="يعدّ الثواني أثناء العمل فقط", w_t_reset="التصفير يوقف ويعود إلى الصفر",
        w_t_debounce="ينتظر حتى تتوقف القيمة عن التغير", w_t_pages="يقسم القائمة إلى صفحات",
        w_t_clamp="لا يتجاوز الصفحة الأخيرة أبداً",
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
PLAIN["vitest.config.ts"] = '''import { defineConfig } from "vitest/config";
import vue from "@vitejs/plugin-vue";

export default defineConfig({ plugins: [vue()], test: { environment: "jsdom", include: ["**/*.test.ts"] } });
'''

# ---------------------------------------------------------------- a first composable
PLAIN["composables/useStopwatch.ts"] = '''import { onScopeDispose, readonly, ref } from "vue";

// {w_c_use}
export function useStopwatch() {
  // {w_c_fresh}
  const seconds = ref(0);
  const running = ref(false);
  let timer: ReturnType<typeof setInterval> | undefined;

  function start() {
    if (running.value) return;
    running.value = true;
    timer = setInterval(() => seconds.value++, 1000);
  }
  function stop() {
    clearInterval(timer);
    running.value = false;
  }
  function reset() {
    stop();
    seconds.value = 0;
  }

  onScopeDispose(stop);
  return { seconds: readonly(seconds), running: readonly(running), start, stop, reset };
}
'''
PLAIN["Stopwatch.vue"] = '''<script setup lang="ts">
import { useStopwatch } from "./composables/useStopwatch";

const { seconds, running, start, stop, reset } = useStopwatch();
</script>

<template>
  <p>
    <strong>{{ seconds }}</strong> {w_seconds}
    <button v-if="!running" type="button" @click="start">{w_start}</button>
    <button v-else type="button" @click="stop">{w_stop}</button>
    <button type="button" class="secondary" @click="reset">{w_reset}</button>
  </p>
</template>
'''
PLAIN["Two.vue"] = '''<script setup lang="ts">
import Stopwatch from "./Stopwatch.vue";
</script>

<template>
  <Stopwatch />
  <Stopwatch />
</template>
'''
BROWSER["stopwatch.ts"] = ('''import { createApp } from "vue";
import Two from "./Two.vue";

createApp(Two).mount("#app");
''', "p { display: flex; gap: 8px; align-items: center; } strong { font-size: 2rem; color: #4338ca; min-width: 1.5ch; }\n")

# ---------------------------------------------------------------- fresh state against shared state
PLAIN["composables/counters.ts"] = '''import { ref } from "vue";

export function useCounter() {
  const count = ref(0); // {w_c_fresh}
  return { count, add: () => count.value++ };
}

const visitors = ref(0); // {w_c_module}
export function useVisitors() {
  return { visitors, arrive: () => visitors.value++ };
}
'''
NODE["state.ts"] = '''import { useCounter, useVisitors } from "./composables/counters";

const a = useCounter();
const b = useCounter();
a.add();
a.add();
b.add();
console.log("{w_first}", a.count.value, "{w_second}", b.count.value);

useVisitors().arrive();
useVisitors().arrive();
console.log("{w_shared}", useVisitors().visitors.value);
'''

# ---------------------------------------------------------------- inputs: values, refs or getters
PLAIN["composables/useDebounced.ts"] = '''import { ref, toValue, watch, type MaybeRefOrGetter, type Ref } from "vue";

// {w_c_input}
export function useDebounced<T>(source: MaybeRefOrGetter<T>, ms = 300): Readonly<Ref<T>> {
  const value = ref(toValue(source)) as Ref<T>;
  watch(
    () => toValue(source),
    (now, _before, onCleanup) => {
      const id = setTimeout(() => (value.value = now), ms);
      onCleanup(() => clearTimeout(id));
    },
  );
  return value;
}
'''

# ---------------------------------------------------------------- an async composable
PLAIN["products.ts"] = '''export type Product = { id: number; name: string; price: number };

const catalogue: Product[] = [
  { id: 1, name: "{w_book}", price: 25 },
  { id: 2, name: "{w_mug}", price: 8 },
  { id: 3, name: "{w_cap}", price: 12 },
  { id: 4, name: "{w_sticker}", price: 3 },
];

// A pretend server: answers after a delay, and can be cancelled like fetch
export function searchProducts(query: string, signal: AbortSignal): Promise<Product[]> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const q = query.trim().toLowerCase();
      resolve(catalogue.filter((p) => p.name.toLowerCase().includes(q)));
    }, 400);
    signal.addEventListener("abort", () => {
      clearTimeout(timer);
      reject(signal.reason);
    });
  });
}
'''
PLAIN["composables/useSearch.ts"] = '''import { ref, toValue, watch, type MaybeRefOrGetter } from "vue";
import { searchProducts, type Product } from "../products";

export function useSearch(query: MaybeRefOrGetter<string>) {
  const results = ref<Product[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  watch(
    () => toValue(query).trim(),
    async (q, _before, onCleanup) => {
      error.value = null;
      if (!q) {
        results.value = [];
        return;
      }
      // {w_c_abort}
      const controller = new AbortController();
      onCleanup(() => controller.abort());
      loading.value = true;
      try {
        results.value = await searchProducts(q, controller.signal);
      } catch (e) {
        if (controller.signal.aborted) return;
        error.value = (e as Error).message;
      }
      loading.value = false;
    },
    { immediate: true },
  );

  return { results, loading, error };
}
'''
PLAIN["Search.vue"] = '''<script setup lang="ts">
import { ref } from "vue";
import { useDebounced } from "./composables/useDebounced";
import { useSearch } from "./composables/useSearch";

const query = ref("");
const { results, loading, error } = useSearch(useDebounced(query, 250));
</script>

<template>
  <label for="q">{w_search}</label>
  <input id="q" v-model="query" type="search" autocomplete="off" />
  <p v-if="loading" role="status" class="muted">{w_searching}</p>
  <p v-else-if="error" role="alert">{w_failed} {{ error }}</p>
  <template v-else-if="query">
    <p role="status">{{ results.length }} {w_results}</p>
    <ul>
      <li v-for="p in results" :key="p.id">{{ p.name }}</li>
    </ul>
  </template>
</template>
'''
BROWSER["search.ts"] = ('''import { createApp } from "vue";
import Search from "./Search.vue";

createApp(Search).mount("#app");
''', """label { display: block; font-weight: 600; } input { font: inherit; padding: 6px 10px; border: 2px solid #c7d2fe; border-radius: 10px; width: 100%; max-width: 320px; }
.muted { color: #5b5873; }
""")

# ---------------------------------------------------------------- listening to the browser
PLAIN["composables/useEventListener.ts"] = '''import { onScopeDispose } from "vue";

// {w_c_dispose}
export function useEventListener<K extends keyof WindowEventMap>(
  target: Window,
  event: K,
  handler: (e: WindowEventMap[K]) => void,
) {
  target.addEventListener(event, handler);
  onScopeDispose(() => target.removeEventListener(event, handler));
}
'''
PLAIN["composables/useOnline.ts"] = '''import { ref } from "vue";
import { useEventListener } from "./useEventListener";

export function useOnline() {
  const online = ref(navigator.onLine);
  useEventListener(window, "online", () => (online.value = true));
  useEventListener(window, "offline", () => (online.value = false));
  return online;
}
'''
PLAIN["Status.vue"] = '''<script setup lang="ts">
import { ref } from "vue";
import { useEventListener } from "./composables/useEventListener";
import { useOnline } from "./composables/useOnline";

const online = useOnline();
const width = ref(window.innerWidth);
useEventListener(window, "resize", () => (width.value = window.innerWidth));
</script>

<template>
  <p :class="online ? 'ok' : 'warn'" role="status">{{ online ? "{w_online}" : "{w_offline}" }}</p>
  <p>{w_width} {{ width }}px</p>
</template>
'''
BROWSER["status.ts"] = ('''import { createApp } from "vue";
import Status from "./Status.vue";

createApp(Status).mount("#app");
window.dispatchEvent(new Event("offline")); // for the screenshot: pretend the network just dropped
''', ".ok { color: #047857; font-weight: 700; } .warn { color: #b45309; font-weight: 700; }\n")

# ---------------------------------------------------------------- VueUse
PLAIN["Theme.vue"] = '''<script setup lang="ts">
import { useLocalStorage } from "@vueuse/core";
import { watchEffect } from "vue";

// {w_c_vueuse}
const dark = useLocalStorage("dark", false);
watchEffect(() => document.documentElement.classList.toggle("dark", dark.value));
</script>

<template>
  <button type="button" :aria-pressed="dark" @click="dark = !dark">{w_theme}</button>
</template>
'''
BROWSER["theme.ts"] = ('''import { createApp } from "vue";
import Theme from "./Theme.vue";

createApp(Theme).mount("#app");
''', "html.dark body { background: #14121f; color: #ecebf5; } html.dark button { background: #a5b4fc; color: #14121f; }\n")

# ---------------------------------------------------------------- tests
PLAIN["composables/useStopwatch.test.ts"] = '''import { effectScope } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useStopwatch } from "./useStopwatch";

afterEach(() => vi.useRealTimers());

describe("useStopwatch", () => {
  it("{w_t_counts}", () => {
    vi.useFakeTimers();
    const scope = effectScope();
    const watch = scope.run(() => useStopwatch())!;
    watch.start();
    vi.advanceTimersByTime(3000);
    watch.stop();
    vi.advanceTimersByTime(5000);
    expect(watch.seconds.value).toBe(3);
    scope.stop();
  });

  it("{w_t_reset}", () => {
    vi.useFakeTimers();
    const scope = effectScope();
    const watch = scope.run(() => useStopwatch())!;
    watch.start();
    vi.advanceTimersByTime(2000);
    watch.reset();
    expect(watch.seconds.value).toBe(0);
    expect(watch.running.value).toBe(false);
    scope.stop();
  });
});
'''
PLAIN["composables/useDebounced.test.ts"] = '''import { nextTick, ref } from "vue";
import { expect, it, vi } from "vitest";
import { useDebounced } from "./useDebounced";

it("{w_t_debounce}", async () => {
  vi.useFakeTimers();
  const text = ref("b");
  const slow = useDebounced(text, 300);
  for (const next of ["bi", "bit"]) {
    text.value = next;
    await nextTick();
    vi.advanceTimersByTime(100);
  }
  expect(slow.value).toBe("b");
  vi.advanceTimersByTime(300);
  expect(slow.value).toBe("bit");
  vi.useRealTimers();
});
'''

# ---------------------------------------------------------------- projects
PLAIN["projects/usePagination.ts"] = '''import { computed, ref, toValue, type MaybeRefOrGetter } from "vue";

export function usePagination<T>(items: MaybeRefOrGetter<readonly T[]>, size = 3) {
  const page = ref(1);
  const pages = computed(() => Math.max(1, Math.ceil(toValue(items).length / size)));
  const current = computed(() => Math.min(page.value, pages.value));
  const rows = computed(() => toValue(items).slice((current.value - 1) * size, current.value * size));
  return {
    page: current,
    pages,
    rows,
    next: () => (page.value = Math.min(current.value + 1, pages.value)),
    previous: () => (page.value = Math.max(current.value - 1, 1)),
  };
}
'''
PLAIN["projects/usePagination.test.ts"] = '''import { ref } from "vue";
import { expect, it } from "vitest";
import { usePagination } from "./usePagination";

it("{w_t_pages}", () => {
  const p = usePagination([1, 2, 3, 4, 5, 6, 7], 3);
  expect(p.pages.value).toBe(3);
  p.next();
  expect(p.rows.value).toEqual([4, 5, 6]);
});

it("{w_t_clamp}", () => {
  const list = ref([1, 2, 3, 4, 5, 6, 7]);
  const p = usePagination(list, 3);
  p.next();
  p.next();
  p.next();
  expect(p.page.value).toBe(3);
  list.value = [1, 2];
  expect(p.page.value).toBe(1);
  expect(p.rows.value).toEqual([1, 2]);
});
'''

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)

check = HERE.parents[1] / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("types ok")
