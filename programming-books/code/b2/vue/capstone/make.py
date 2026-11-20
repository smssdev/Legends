"""Writes the capstone of Book 2 (Vue edition): the admin dashboard for Bit's shop, in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}. Every file is type-checked with vue-tsc.

The parts that do not depend on the framework (zod schemas, the client, the pretend server, the pure logic and
its tests, both languages, the CSS and the end-to-end test) are taken unchanged from the React edition's
capstone, so the two editions build exactly the same product. Everything else is written here, the Vue way.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B2 = HERE.parents[1]
sys.path.insert(0, str(B2))
import vue_kit as kit  # noqa: E402

# ---------------------------------------------------------------- shared with the React edition
react_src = (B2 / "react" / "capstone" / "make.py").read_text()
react_src = react_src[: react_src.rindex("for lang, words in T.items():")]
shared: dict = {"__file__": str(B2 / "react" / "capstone" / "make.py")}
exec(compile(react_src, "react-capstone", "exec"), shared)
T, CSS, R = shared["T"], shared["CSS"], shared["PLAIN"]

for lang, words in T.items():
    words["lang"] = lang
    words.update({
        "en": dict(w_c_store="App-wide settings in a Pinia store; useLocalStorage remembers them",
                   w_c_lazy="Loaded only when opened: the form code is not part of the first download"),
        "ar": dict(w_c_store="إعدادات التطبيق في مخزن Pinia، وuseLocalStorage تتذكرها",
                   w_c_lazy="يُحمَّل حين يُفتح فقط: كود النموذج ليس في التنزيل الأول"),
    }[lang])
    words.update({
        "en": dict(w_s_ours="our code", w_s_later="loaded later", w_s_first="first load",
                   w_s_under="under the budget of", w_s_over="over the budget of"),
        "ar": dict(w_s_ours="كودنا", w_s_later="يُحمَّل لاحقاً", w_s_first="التحميل الأول",
                   w_s_under="ضمن ميزانية", w_s_over="فوق ميزانية"),
    }[lang])

PLAIN, NODE, BROWSER = {}, {}, {}
for name in ["src/api/schemas.ts", "src/api/client.ts", "src/api/fake-server.ts", "src/lib/orders.ts",
             "src/lib/orders.test.ts", "src/i18n/messages.ts", "src/i18n/format.ts", "e2e/admin.spec.ts"]:
    PLAIN[name] = R[name]

PLAIN["tsconfig.json"] = '''{
  "compilerOptions": {
    "strict": true, "noUncheckedIndexedAccess": true, "target": "es2024", "module": "esnext",
    "moduleResolution": "bundler", "lib": ["es2024", "dom", "dom.iterable"], "types": ["node"], "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts", "src/**/*.vue", "page.ts", "size.ts", "vitest.setup.ts"]
}
'''

# ================================================================== src/api: the Vue Query hooks
PLAIN["src/api/queries.ts"] = r'''import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";
import { toValue, type MaybeRefOrGetter } from "vue";
import { api } from "./client";
import type { Order, OrderStatus, Product } from "./schemas";

// {w_c_keys}
export const keys = {
  orders: ["orders"] as const,
  order: (id: number) => ["orders", id] as const,
  products: ["products"] as const,
  product: (id: number) => ["products", id] as const,
};

export const useOrders = () => useQuery({ queryKey: keys.orders, queryFn: api.orders });
export const useProducts = () => useQuery({ queryKey: keys.products, queryFn: api.products });

export function useOrder(id: MaybeRefOrGetter<number>) {
  return useQuery({ queryKey: ["orders", id], queryFn: () => api.order(toValue(id)) });
}

export function useProduct(id: MaybeRefOrGetter<number>) {
  return useQuery({ queryKey: ["products", id], queryFn: () => api.product(toValue(id)) });
}

export function useSetStatus(id: MaybeRefOrGetter<number>) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (status: OrderStatus) => api.setStatus(toValue(id), status),
    // {w_c_opt}
    onMutate: async (status) => {
      const key = keys.order(toValue(id));
      await client.cancelQueries({ queryKey: key });
      const before = client.getQueryData<Order>(key);
      if (before) client.setQueryData<Order>(key, { ...before, status });
      return { before };
    },
    onError: (_error, _status, context) => {
      if (context?.before) client.setQueryData(keys.order(toValue(id)), context.before);
    },
    onSettled: () => client.invalidateQueries({ queryKey: keys.orders }),
  });
}

export function useSaveProduct() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (product: Product) => api.saveProduct(product),
    onSuccess: (saved) => {
      client.setQueryData(keys.product(saved.id), saved);
      void client.invalidateQueries({ queryKey: keys.products, exact: true });
    },
  });
}
'''

# ================================================================== settings: a Pinia store
PLAIN["src/settings.ts"] = r'''import { computed } from "vue";
import { defineStore } from "pinia";
import { useLocalStorage } from "@vueuse/core";
import { makeT } from "./i18n/format";
import type { Lang } from "./i18n/messages";

// {w_c_store}
export const useSettings = defineStore("settings", () => {
  const lang = useLocalStorage<Lang>("admin-lang", globalThis.document?.documentElement.lang === "ar" ? "ar" : "en");
  const dark = useLocalStorage("admin-dark", false);
  const t = computed(() => makeT(lang.value));

  return {
    lang,
    dark,
    t,
    toggleLanguage: () => (lang.value = lang.value === "en" ? "ar" : "en"),
    toggleDark: () => (dark.value = !dark.value),
  };
});
'''

# ================================================================== the form composable, from the forms chapter
# (copied after generation, from the forms chapter, in each language)

# ================================================================== src/ui
PLAIN["src/ui/BaseCard.vue"] = r'''<script setup lang="ts">
defineProps<{ title?: string }>();
</script>

<template>
  <section class="card">
    <h2 v-if="title">{{ title }}</h2>
    <slot />
  </section>
</template>
'''
PLAIN["src/ui/StatusBadge.vue"] = r'''<script setup lang="ts">
import { storeToRefs } from "pinia";
import type { OrderStatus } from "../api/schemas";
import { useSettings } from "../settings";

defineProps<{ status: OrderStatus }>();
const { t } = storeToRefs(useSettings());
</script>

<template>
  <span :class="['badge', status]">{{ t(status) }}</span>
</template>
'''
PLAIN["src/ui/LoadingSkeleton.vue"] = r'''<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useSettings } from "../settings";

const { t } = storeToRefs(useSettings());
</script>

<template>
  <div aria-busy="true" :aria-label="t('loading')">
    <div class="skeleton" />
    <div class="skeleton" />
    <div class="skeleton" />
  </div>
</template>
'''
PLAIN["src/ui/LoadError.vue"] = r'''<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useSettings } from "../settings";

const emit = defineEmits<{ retry: [] }>();
const { t } = storeToRefs(useSettings());
</script>

<template>
  <div role="alert" class="card">
    <p>{{ t("loadError") }}</p>
    <button type="button" @click="emit('retry')">{{ t("retry") }}</button>
  </div>
</template>
'''

# ================================================================== src/features
PLAIN["src/features/overview/OverviewPage.vue"] = r'''<script setup lang="ts">
import { computed } from "vue";
import { storeToRefs } from "pinia";
import { useOrders } from "../../api/queries";
import { overview } from "../../lib/orders";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";

const { t } = storeToRefs(useSettings());
const { data, isPending, isError, refetch } = useOrders();

const o = computed(() => (data.value ? overview(data.value, new Date()) : null));
const highest = computed(() => Math.max(1, ...(o.value?.days.map((d) => d.total) ?? [])));
const kpis = computed(() =>
  o.value
    ? [
        [t.value("revenue"), t.value.money(o.value.revenue)],
        [t.value("ordersCount"), String(o.value.orders)],
        [t.value("average"), t.value.money(o.value.average)],
        [t.value("toShip"), String(o.value.toShip)],
      ]
    : [],
);
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else-if="o">
    <h1>{{ t("overview") }}</h1>
    <div class="kpis">
      <figure v-for="[label, value] in kpis" :key="label" class="card kpi">
        <p>{{ label }}</p>
        <strong>{{ value }}</strong>
      </figure>
    </div>
    <BaseCard :title="t('lastWeek')">
      <ol class="bars">
        <li v-for="d in o.days" :key="d.day">
          <span class="bar" :style="{ blockSize: `${(d.total / highest) * 100}%` }" />
          <span aria-hidden="true">{{ t.weekday(d.day) }}</span>
          <span class="sr-only">{{ `${t.weekday(d.day)}: ${t.money(d.total)}` }}</span>
        </li>
      </ol>
    </BaseCard>
  </template>
</template>
'''

PLAIN["src/features/orders/OrdersPage.vue"] = r'''<script setup lang="ts">
import { computed } from "vue";
import { useRoute, useRouter, type LocationQueryRaw } from "vue-router";
import { storeToRefs } from "pinia";
import { useOrders } from "../../api/queries";
import { filterOrders, readFilters, STATUSES } from "../../lib/orders";
import { useSettings } from "../../settings";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";
import StatusBadge from "../../ui/StatusBadge.vue";

const { t } = storeToRefs(useSettings());
const route = useRoute();
const router = useRouter();
const { data, isPending, isError, refetch } = useOrders();

// {w_c_url}
const filters = computed(() => {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(route.query)) if (typeof value === "string") params.set(key, value);
  return readFilters(params);
});
const result = computed(() => (data.value ? filterOrders(data.value, filters.value) : null));

const link = (changes: LocationQueryRaw) => ({ query: { ...route.query, ...changes } });
const search = computed({
  get: () => filters.value.q,
  set: (q: string) => router.replace(link({ q: q || undefined, page: undefined })),
});
</script>

<template>
  <h1>{{ t("orders") }}</h1>
  <nav class="filters" :aria-label="t('status')">
    <RouterLink
      v-for="s in ['all', ...STATUSES] as const"
      :key="s"
      :to="link({ status: s === 'all' ? undefined : s, page: undefined })"
      :aria-current="filters.status === s ? 'page' : undefined"
    >
      {{ t(s) }}
    </RouterLink>
  </nav>
  <label for="q" class="sr-only">{{ t("search") }}</label>
  <input id="q" v-model="search" type="search" :placeholder="t('search')" />
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <p v-else-if="result && result.count === 0" role="status">{{ t("none") }}</p>
  <section v-else-if="result" class="card">
    <table>
      <caption class="sr-only">{{ t("found", { count: result.count }) }}</caption>
      <thead>
        <tr>
          <th scope="col">{{ t("order") }}</th>
          <th scope="col">{{ t("customer") }}</th>
          <th scope="col">{{ t("total") }}</th>
          <th scope="col">{{ t("status") }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="o in result.rows" :key="o.id">
          <td><RouterLink :to="`/orders/${o.id}`">#{{ o.id }}</RouterLink></td>
          <td>{{ o.customer }}</td>
          <td>{{ t.money(o.total) }}</td>
          <td><StatusBadge :status="o.status" /></td>
        </tr>
      </tbody>
    </table>
    <div class="pager">
      <RouterLink v-if="result.page > 1" :to="link({ page: String(result.page - 1) })">{{ t("previous") }}</RouterLink>
      <span v-else />
      <span>{{ t("page", { page: result.page, pages: result.pages }) }}</span>
      <RouterLink v-if="result.page < result.pages" :to="link({ page: String(result.page + 1) })">{{ t("next") }}</RouterLink>
      <span v-else />
    </div>
  </section>
</template>
'''

PLAIN["src/features/orders/OrderPage.vue"] = r'''<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useOrder, useSetStatus } from "../../api/queries";
import { STATUSES } from "../../lib/orders";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";
import StatusBadge from "../../ui/StatusBadge.vue";

const props = defineProps<{ id: number }>();
const { t } = storeToRefs(useSettings());
const { data: order, isPending, isError, refetch } = useOrder(() => props.id);
const setStatus = useSetStatus(() => props.id);
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else-if="order">
    <h1>{{ t("orderTitle", { id: String(order.id) }) }}</h1>
    <BaseCard>
      <dl>
        <dt>{{ t("customer") }}</dt>
        <dd>{{ order.customer }}</dd>
        <dt>{{ t("city") }}</dt>
        <dd>{{ order.city }}</dd>
        <dt>{{ t("date") }}</dt>
        <dd>{{ t.date(order.createdAt) }}</dd>
        <dt>{{ t("total") }}</dt>
        <dd>{{ t.money(order.total) }}</dd>
        <dt>{{ t("status") }}</dt>
        <dd aria-live="polite"><StatusBadge :status="order.status" /></dd>
      </dl>
      <p>{{ t("markAs") }}</p>
      <div class="actions">
        <button
          v-for="s in STATUSES.filter((s) => s !== order!.status)"
          :key="s"
          type="button"
          class="secondary"
          :disabled="setStatus.isPending.value"
          @click="setStatus.mutate(s)"
        >
          {{ t(s) }}
        </button>
      </div>
      <p v-if="setStatus.isError.value" role="alert" class="error">{{ t("failed") }}</p>
    </BaseCard>
    <RouterLink to="/orders">{{ t("allOrders") }}</RouterLink>
  </template>
</template>
'''

PLAIN["src/features/products/ProductForm.vue"] = r'''<script setup lang="ts">
import { computed, ref } from "vue";
import { storeToRefs } from "pinia";
import * as z from "zod";
import type { Product } from "../../api/schemas";
import { useForm } from "../../lib/useForm";
import { useSettings } from "../../settings";

type Fields = "name" | "price" | "stock";
const props = defineProps<{
  product: Product;
  onSave: (product: Product) => Promise<Partial<Record<Fields, string>> | void>;
}>();
const { t } = storeToRefs(useSettings());

// The schema is built with the current language, so its messages are translated
const schema = computed(() =>
  z.object({
    name: z.string().trim().min(2, t.value("nameError")).max(40, t.value("nameError")),
    price: z.coerce.number<string>().int(t.value("priceError")).positive(t.value("priceError")),
    stock: z.coerce.number<string>().int(t.value("stockError")).min(0, t.value("stockError")),
  }),
);
const { values, errors, submitting, blur, handleSubmit } = useForm(schema.value, {
  name: props.product.name,
  price: String(props.product.price),
  stock: String(props.product.stock),
});
const saved = ref(false);

const submit = handleSubmit(async (data) => {
  saved.value = false;
  const fromServer = await props.onSave({ ...props.product, ...data });
  if (!fromServer) saved.value = true;
  return fromServer;
});
</script>

<template>
  <form novalidate @submit.prevent="submit">
    <template v-for="field in (['name', 'price', 'stock'] as const)" :key="field">
      <label :for="field">{{ t(field) }}</label>
      <input
        :id="field"
        v-model="values[field]"
        :inputmode="field === 'name' ? undefined : 'numeric'"
        :aria-invalid="!!errors[field]"
        :aria-describedby="`${field}-error`"
        @blur="blur(field)"
      />
      <p v-if="errors[field]" :id="`${field}-error`" class="error">{{ errors[field] }}</p>
    </template>
    <p>
      <button type="submit" :disabled="submitting">{{ submitting ? t("saving") : t("save") }}</button>
    </p>
    <p v-if="saved" role="status" class="done">{{ t("saved") }}</p>
  </form>
</template>
'''

PLAIN["src/features/products/ProductsPage.vue"] = r'''<script setup lang="ts">
import { storeToRefs } from "pinia";
import { useProducts } from "../../api/queries";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";

const { t } = storeToRefs(useSettings());
const { data: products, isPending, isError, refetch } = useProducts();
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else>
    <h1>{{ t("products") }}</h1>
    <BaseCard>
      <table>
        <thead>
          <tr>
            <th scope="col">{{ t("name") }}</th>
            <th scope="col">{{ t("price") }}</th>
            <th scope="col">{{ t("stock") }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in products" :key="p.id">
            <td>
              <RouterLink :to="`/products/${p.id}`" :aria-label="`${t('edit')}: ${p.name}`">{{ p.name }}</RouterLink>
            </td>
            <td>{{ t.money(p.price) }}</td>
            <td>{{ p.stock }}</td>
          </tr>
        </tbody>
      </table>
    </BaseCard>
  </template>
</template>
'''
PLAIN["src/features/products/ProductPage.vue"] = r'''<script setup lang="ts">
import { storeToRefs } from "pinia";
import { ApiError } from "../../api/client";
import { useProduct, useSaveProduct } from "../../api/queries";
import type { Product } from "../../api/schemas";
import { useSettings } from "../../settings";
import BaseCard from "../../ui/BaseCard.vue";
import LoadError from "../../ui/LoadError.vue";
import LoadingSkeleton from "../../ui/LoadingSkeleton.vue";
import ProductForm from "./ProductForm.vue";

const props = defineProps<{ id: number }>();
const { t } = storeToRefs(useSettings());
const { data: product, isPending, isError, refetch } = useProduct(() => props.id);
const save = useSaveProduct();

async function onSave(changed: Product) {
  try {
    await save.mutateAsync(changed);
  } catch (error) {
    if (error instanceof ApiError && error.status === 422) return error.errors;
    throw error;
  }
}
</script>

<template>
  <LoadingSkeleton v-if="isPending" />
  <LoadError v-else-if="isError" @retry="refetch()" />
  <template v-else-if="product">
    <h1>{{ product.name }}</h1>
    <BaseCard>
      <ProductForm :key="product.id" :product="product" :on-save="onSave" />
    </BaseCard>
    <RouterLink to="/products">{{ t("products") }}</RouterLink>
  </template>
</template>
'''

# ================================================================== src/app
PLAIN["src/app/App.vue"] = r'''<script setup lang="ts">
import { watchEffect } from "vue";
import { storeToRefs } from "pinia";
import { useSettings } from "../settings";

const settings = useSettings();
const { t, lang, dark } = storeToRefs(settings);

watchEffect(() => {
  const html = document.documentElement;
  html.lang = lang.value;
  html.dir = lang.value === "ar" ? "rtl" : "ltr";
  html.classList.toggle("dark", dark.value);
});
</script>

<template>
  <div class="app">
    <a class="skip" href="#main">{{ t("skip") }}</a>
    <nav class="side" :aria-label="t('brand')">
      <span class="brand">{{ t("brand") }}</span>
      <RouterLink to="/" exact-active-class="active" active-class="">{{ t("overview") }}</RouterLink>
      <RouterLink to="/orders" active-class="active">{{ t("orders") }}</RouterLink>
      <RouterLink to="/products" active-class="active">{{ t("products") }}</RouterLink>
    </nav>
    <div>
      <header class="top">
        <button type="button" class="secondary" :lang="lang === 'en' ? 'ar' : 'en'" @click="settings.toggleLanguage()">
          {{ t("switchLanguage") }}
        </button>
        <button type="button" class="secondary" :aria-pressed="dark" @click="settings.toggleDark()">{{ t("dark") }}</button>
      </header>
      <main id="main"><RouterView /></main>
    </div>
  </div>
</template>
'''
PLAIN["src/app/routes.ts"] = r'''import { h } from "vue";
import type { RouteRecordRaw } from "vue-router";
import OverviewPage from "../features/overview/OverviewPage.vue";
import OrdersPage from "../features/orders/OrdersPage.vue";
import OrderPage from "../features/orders/OrderPage.vue";

const id = (route: { params: Record<string, unknown> }) => ({ id: Number(route.params.id) });

export const routes: RouteRecordRaw[] = [
  { path: "/", component: OverviewPage },
  {
    path: "/orders",
    children: [
      { path: "", component: OrdersPage },
      { path: ":id(\\d+)", component: OrderPage, props: id },
    ],
  },
  {
    path: "/products",
    // {w_c_lazy}
    children: [
      { path: "", component: () => import("../features/products/ProductsPage.vue") },
      { path: ":id(\\d+)", component: () => import("../features/products/ProductPage.vue"), props: id },
    ],
  },
  { path: "/:path(.*)*", component: { render: () => h("p", { role: "alert" }, "404") } },
];
'''
PLAIN["src/main.ts"] = r'''import { createApp } from "vue";
import { createPinia } from "pinia";
import { createRouter, createWebHistory } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import App from "./app/App.vue";
import { routes } from "./app/routes";

createApp(App)
  .use(createPinia())
  .use(createRouter({ history: createWebHistory(), routes }))
  .use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 30_000, retry: 1 } } } })
  .mount("#app");
'''

BROWSER["page.ts"] = (r'''// {w_c_page}
import { createApp } from "vue";
import { createPinia } from "pinia";
import { createMemoryHistory, createRouter } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { fakeFetch, server } from "./src/api/fake-server";
import App from "./src/app/App.vue";
import { routes } from "./src/app/routes";

window.fetch = fakeFetch;
Object.assign(window, { server }); // so a test can say: server.failNextChange = true
localStorage.clear(); // start from the page's own language and the light theme

const router = createRouter({ history: createMemoryHistory(), routes });
await router.push("/");
createApp(App)
  .use(createPinia())
  .use(router)
  .use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 30_000, retry: false } } } })
  .mount("#app");
''', CSS)

# ================================================================== tests
PLAIN["vitest.config.ts"] = r'''import { defineConfig } from "vitest/config";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()],
  test: { environment: "jsdom", setupFiles: ["./vitest.setup.ts"], include: ["src/**/*.test.ts"] },
});
'''
PLAIN["vitest.setup.ts"] = r'''import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/vue";
import { afterEach } from "vitest";

afterEach(cleanup);
'''
PLAIN["src/features/products/ProductForm.test.ts"] = r'''import { render, screen } from "@testing-library/vue";
import userEvent from "@testing-library/user-event";
import { createPinia } from "pinia";
import { describe, expect, it, vi } from "vitest";
import ProductForm from "./ProductForm.vue";

const mug = { id: 2, name: "Bit mug", price: 8500, stock: 40 };
const show = (onSave: (p: typeof mug) => Promise<Record<string, string> | void>) =>
  render(ProductForm, { props: { product: mug, onSave }, global: { plugins: [createPinia()] } });

describe("ProductForm", () => {
  it("{w_t_form}", async () => {
    const onSave = vi.fn();
    show(onSave);
    await userEvent.clear(screen.getByLabelText("Name"));
    await userEvent.clear(screen.getByLabelText("Price in piastres"));
    await userEvent.type(screen.getByLabelText("Price in piastres"), "85.5");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Write a name of 2 to 40 characters.")).toBeInTheDocument();
    expect(screen.getByText("The price must be a whole number above zero.")).toBeInTheDocument();
    expect(onSave).not.toHaveBeenCalled();
  });

  it("{w_t_save}", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    show(onSave);
    await userEvent.clear(screen.getByLabelText("Stock"));
    await userEvent.type(screen.getByLabelText("Stock"), "39");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByRole("status")).toHaveTextContent("Saved.");
    expect(onSave).toHaveBeenCalledWith({ id: 2, name: "Bit mug", price: 8500, stock: 39 });
  });

  it("{w_t_server}", async () => {
    show(async () => ({ name: "Another product already has this name." }));
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Another product already has this name.")).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toHaveAttribute("aria-invalid", "true");
  });
});
'''
PLAIN["playwright.config.ts"] = r'''import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  reporter: "list",
  webServer: { command: "node ../../../serve.mjs 4176", url: "http://localhost:4176/vendor-vue/vue.js", reuseExistingServer: true },
  use: { baseURL: "http://localhost:4176/vue/capstone/{lang}/", browserName: "chromium" },
});
'''

NODE["size.ts"] = r'''import { build, type Rollup } from "vite";
import vue from "@vitejs/plugin-vue";
import { gzipSync } from "node:zlib";

// {w_c_size}
const BUDGET_KB = 150;

const output = (await build({
  logLevel: "silent",
  plugins: [vue()],
  build: { write: false, rollupOptions: { input: "src/main.ts" } },
})) as Rollup.RolldownOutput;

const chunks = output.output.filter((file) => file.type === "chunk");
const gzipKB = (code: string) => gzipSync(code).length / 1024;
const packageOf = (id: string) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(id)?.[1] ?? "{w_s_ours}";

// The first load: the entry and every chunk it imports directly
const first = new Set<string>();
const visit = (fileName: string) => {
  if (first.has(fileName)) return;
  first.add(fileName);
  for (const imported of chunks.find((c) => c.fileName === fileName)?.imports ?? []) visit(imported);
};
visit(chunks.find((c) => c.isEntry)!.fileName);

let firstKB = 0;
for (const chunk of chunks) {
  const kb = gzipKB(chunk.code);
  if (first.has(chunk.fileName)) firstKB += kb;
  else console.log(`{w_s_later}: ${kb.toFixed(1)} KB gzip (${[...new Set(chunk.moduleIds.map(packageOf))].join(" + ")})`);
}
console.log(`{w_s_first}: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `✓ {w_s_under} ${BUDGET_KB} KB` : `✗ {w_s_over} ${BUDGET_KB} KB`);
'''

for lang in T:
    (HERE / lang / "src" / "lib").mkdir(parents=True, exist_ok=True)
    (HERE / lang / "src" / "lib" / "useForm.ts").write_text((B2 / "vue" / "forms" / lang / "useForm.ts").read_text())
kit.generate(HERE, T, plain=PLAIN, node_files={}, browser_files=BROWSER)
# size.ts runs with Vite itself, so it is bundled for Node with its packages left outside
for lang, words in T.items():
    (HERE / lang / "size.ts").write_text(kit.fill(NODE["size.ts"], words))
    kit.node(HERE / lang / "size.ts", HERE / lang / "size.mjs")

check = B2 / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("types ok")
