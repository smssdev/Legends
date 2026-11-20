var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};

// vue/capstone/ar/src/i18n/messages.ts
var en, ar, messages;
var init_messages = __esm({
  "vue/capstone/ar/src/i18n/messages.ts"() {
    "use strict";
    en = {
      brand: "Bit's shop admin",
      skip: "Skip to content",
      overview: "Overview",
      orders: "Orders",
      products: "Products",
      switchLanguage: "\u0627\u0644\u0639\u0631\u0628\u064A\u0629",
      dark: "Dark theme",
      revenue: "Revenue",
      ordersCount: "Orders",
      average: "Average order",
      toShip: "Waiting to ship",
      lastWeek: "Revenue, last 7 days",
      all: "All",
      new: "New",
      paid: "Paid",
      shipped: "Shipped",
      cancelled: "Cancelled",
      search: "Search by customer",
      order: "Order",
      customer: "Customer",
      city: "City",
      total: "Total",
      date: "Date",
      status: "Status",
      found: "{count} orders",
      page: "Page {page} of {pages}",
      previous: "Previous",
      next: "Next",
      none: "No orders match these filters.",
      orderTitle: "Order #{id}",
      markAs: "Mark as",
      allOrders: "All orders",
      failed: "Could not save, so the change was undone. Please try again.",
      name: "Name",
      price: "Price in piastres",
      stock: "Stock",
      edit: "Edit",
      save: "Save",
      saving: "Saving\u2026",
      saved: "Saved.",
      nameError: "Write a name of 2 to 40 characters.",
      priceError: "The price must be a whole number above zero.",
      stockError: "Stock must be a whole number, 0 or more.",
      loadError: "Could not load the data.",
      retry: "Try again",
      loading: "Loading\u2026",
      notFound: "There is no page at this address."
    };
    ar = {
      brand: "\u0625\u062F\u0627\u0631\u0629 \u0645\u062A\u062C\u0631 \u0628\u0650\u062A",
      skip: "\u062A\u062E\u0637\u064E\u0651 \u0625\u0644\u0649 \u0627\u0644\u0645\u062D\u062A\u0648\u0649",
      overview: "\u0646\u0638\u0631\u0629 \u0639\u0627\u0645\u0629",
      orders: "\u0627\u0644\u0637\u0644\u0628\u0627\u062A",
      products: "\u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A",
      switchLanguage: "English",
      dark: "\u0627\u0644\u0645\u0638\u0647\u0631 \u0627\u0644\u062F\u0627\u0643\u0646",
      revenue: "\u0627\u0644\u0625\u064A\u0631\u0627\u062F\u0627\u062A",
      ordersCount: "\u0627\u0644\u0637\u0644\u0628\u0627\u062A",
      average: "\u0645\u062A\u0648\u0633\u0637 \u0627\u0644\u0637\u0644\u0628",
      toShip: "\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0627\u0644\u0634\u062D\u0646",
      lastWeek: "\u0627\u0644\u0625\u064A\u0631\u0627\u062F\u0627\u062A \u0641\u064A \u0622\u062E\u0631 7 \u0623\u064A\u0627\u0645",
      all: "\u0627\u0644\u0643\u0644",
      new: "\u062C\u062F\u064A\u062F",
      paid: "\u0645\u062F\u0641\u0648\u0639",
      shipped: "\u0645\u0634\u062D\u0648\u0646",
      cancelled: "\u0645\u0644\u063A\u0649",
      search: "\u0627\u0628\u062D\u062B \u0628\u0627\u0633\u0645 \u0627\u0644\u0639\u0645\u064A\u0644",
      order: "\u0627\u0644\u0637\u0644\u0628",
      customer: "\u0627\u0644\u0639\u0645\u064A\u0644",
      city: "\u0627\u0644\u0645\u062F\u064A\u0646\u0629",
      total: "\u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A",
      date: "\u0627\u0644\u062A\u0627\u0631\u064A\u062E",
      status: "\u0627\u0644\u062D\u0627\u0644\u0629",
      found: "{count} \u0637\u0644\u0628\u0627\u064B",
      page: "\u0635\u0641\u062D\u0629 {page} \u0645\u0646 {pages}",
      previous: "\u0627\u0644\u0633\u0627\u0628\u0642",
      next: "\u0627\u0644\u062A\u0627\u0644\u064A",
      none: "\u0644\u0627 \u0637\u0644\u0628\u0627\u062A \u062A\u0637\u0627\u0628\u0642 \u0647\u0630\u0647 \u0627\u0644\u0645\u0631\u0634\u062D\u0627\u062A.",
      orderTitle: "\u0627\u0644\u0637\u0644\u0628 \u0631\u0642\u0645 {id}",
      markAs: "\u063A\u064A\u0651\u0631 \u0627\u0644\u062D\u0627\u0644\u0629 \u0625\u0644\u0649",
      allOrders: "\u0643\u0644 \u0627\u0644\u0637\u0644\u0628\u0627\u062A",
      failed: "\u062A\u0639\u0630\u0651\u0631 \u0627\u0644\u062D\u0641\u0638\u060C \u0641\u0623\u064F\u0644\u063A\u064A \u0627\u0644\u062A\u063A\u064A\u064A\u0631. \u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649.",
      name: "\u0627\u0644\u0627\u0633\u0645",
      price: "\u0627\u0644\u0633\u0639\u0631 \u0628\u0627\u0644\u0642\u0631\u0648\u0634",
      stock: "\u0627\u0644\u0645\u062E\u0632\u0648\u0646",
      edit: "\u062A\u0639\u062F\u064A\u0644",
      save: "\u0627\u062D\u0641\u0638",
      saving: "\u062C\u0627\u0631\u064D \u0627\u0644\u062D\u0641\u0638\u2026",
      saved: "\u062D\u064F\u0641\u0638.",
      nameError: "\u0627\u0643\u062A\u0628 \u0627\u0633\u0645\u0627\u064B \u0645\u0646 2 \u0625\u0644\u0649 40 \u062D\u0631\u0641\u0627\u064B.",
      priceError: "\u0627\u0644\u0633\u0639\u0631 \u0639\u062F\u062F \u0635\u062D\u064A\u062D \u0623\u0643\u0628\u0631 \u0645\u0646 \u0635\u0641\u0631.",
      stockError: "\u0627\u0644\u0645\u062E\u0632\u0648\u0646 \u0639\u062F\u062F \u0635\u062D\u064A\u062D\u060C \u0635\u0641\u0631 \u0623\u0648 \u0623\u0643\u062B\u0631.",
      loadError: "\u062A\u0639\u0630\u0651\u0631 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A.",
      retry: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      loading: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0645\u064A\u0644\u2026",
      notFound: "\u0644\u0627 \u0635\u0641\u062D\u0629 \u0639\u0644\u0649 \u0647\u0630\u0627 \u0627\u0644\u0639\u0646\u0648\u0627\u0646."
    };
    messages = { en, ar };
  }
});

// vue/capstone/ar/src/i18n/format.ts
function makeT(lang) {
  const money = new Intl.NumberFormat(locales[lang], { style: "currency", currency: "EGP", maximumFractionDigits: 0 });
  const date = new Intl.DateTimeFormat(locales[lang], { day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
  const weekday = new Intl.DateTimeFormat(locales[lang], { weekday: "short", timeZone: "UTC" });
  const number2 = new Intl.NumberFormat(locales[lang]);
  const t = (key, values = {}) => messages[lang][key].replace(/\{(\w+)\}/g, (_, name) => {
    const value = values[name];
    return typeof value === "number" ? number2.format(value) : String(value);
  });
  return Object.assign(t, {
    lang,
    money: (piastres) => money.format(piastres / 100),
    date: (iso2) => date.format(new Date(iso2)),
    weekday: (day2) => weekday.format(new Date(day2))
  });
}
var locales;
var init_format = __esm({
  "vue/capstone/ar/src/i18n/format.ts"() {
    "use strict";
    init_messages();
    locales = { en: "en-EG", ar: "ar-EG" };
  }
});

// vue/capstone/ar/src/settings.ts
import { computed } from "vue";
import { defineStore } from "pinia";
import { useLocalStorage } from "@vueuse/core";
var useSettings;
var init_settings = __esm({
  "vue/capstone/ar/src/settings.ts"() {
    "use strict";
    init_format();
    useSettings = defineStore("settings", () => {
      const lang = useLocalStorage("admin-lang", globalThis.document?.documentElement.lang === "ar" ? "ar" : "en");
      const dark = useLocalStorage("admin-dark", false);
      const t = computed(() => makeT(lang.value));
      return {
        lang,
        dark,
        t,
        toggleLanguage: () => lang.value = lang.value === "en" ? "ar" : "en",
        toggleDark: () => dark.value = !dark.value
      };
    });
  }
});

// vue/capstone/ar/src/api/schemas.ts
import * as z from "zod";
var OrderStatus, Order, Product;
var init_schemas = __esm({
  "vue/capstone/ar/src/api/schemas.ts"() {
    "use strict";
    OrderStatus = z.enum(["new", "paid", "shipped", "cancelled"]);
    Order = z.object({
      id: z.number().int(),
      customer: z.string(),
      city: z.string(),
      total: z.number().int().nonnegative(),
      // piastres
      status: OrderStatus,
      createdAt: z.iso.datetime()
    });
    Product = z.object({
      id: z.number().int(),
      name: z.string(),
      price: z.number().int().positive(),
      // piastres
      stock: z.number().int().nonnegative()
    });
  }
});

// vue/capstone/ar/src/api/client.ts
import * as z2 from "zod";
async function request(path, schema, init) {
  const response = await fetch(path, { ...init, headers: { "Content-Type": "application/json" } });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const errors = body.errors;
    throw new ApiError(response.status, errors);
  }
  return schema.parse(body);
}
var ApiError, send, api;
var init_client = __esm({
  "vue/capstone/ar/src/api/client.ts"() {
    "use strict";
    init_schemas();
    ApiError = class extends Error {
      constructor(status, errors = {}) {
        super(`HTTP ${status}`);
        this.status = status;
        this.errors = errors;
      }
      status;
      errors;
    };
    send = (method, data) => ({ method, body: JSON.stringify(data) });
    api = {
      orders: () => request("/api/orders", z2.array(Order)),
      order: (id2) => request(`/api/orders/${id2}`, Order),
      setStatus: (id2, status) => request(`/api/orders/${id2}`, Order, send("PATCH", { status })),
      products: () => request("/api/products", z2.array(Product)),
      product: (id2) => request(`/api/products/${id2}`, Product),
      saveProduct: (product) => request(`/api/products/${product.id}`, Product, send("PUT", product))
    };
  }
});

// vue/capstone/ar/src/api/queries.ts
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";
import { toValue } from "vue";
function useOrder(id2) {
  return useQuery({ queryKey: ["orders", id2], queryFn: () => api.order(toValue(id2)) });
}
function useProduct(id2) {
  return useQuery({ queryKey: ["products", id2], queryFn: () => api.product(toValue(id2)) });
}
function useSetStatus(id2) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (status) => api.setStatus(toValue(id2), status),
    // اعرض الحالة الجديدة فوراً، وأعد القديمة إن رفض الخادم
    onMutate: async (status) => {
      const key = keys.order(toValue(id2));
      await client.cancelQueries({ queryKey: key });
      const before = client.getQueryData(key);
      if (before) client.setQueryData(key, { ...before, status });
      return { before };
    },
    onError: (_error, _status, context) => {
      if (context?.before) client.setQueryData(keys.order(toValue(id2)), context.before);
    },
    onSettled: () => client.invalidateQueries({ queryKey: keys.orders })
  });
}
function useSaveProduct() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (product) => api.saveProduct(product),
    onSuccess: (saved) => {
      client.setQueryData(keys.product(saved.id), saved);
      void client.invalidateQueries({ queryKey: keys.products, exact: true });
    }
  });
}
var keys, useOrders, useProducts;
var init_queries = __esm({
  "vue/capstone/ar/src/api/queries.ts"() {
    "use strict";
    init_client();
    keys = {
      orders: ["orders"],
      order: (id2) => ["orders", id2],
      products: ["products"],
      product: (id2) => ["products", id2]
    };
    useOrders = () => useQuery({ queryKey: keys.orders, queryFn: api.orders });
    useProducts = () => useQuery({ queryKey: keys.products, queryFn: api.products });
  }
});

// vue/capstone/ar/src/ui/BaseCard.vue
import { defineComponent as _defineComponent2 } from "vue";
import { toDisplayString as _toDisplayString2, openBlock as _openBlock2, createElementBlock as _createElementBlock2, createCommentVNode as _createCommentVNode, renderSlot as _renderSlot } from "vue";
var _hoisted_12, _hoisted_22, _sfc2, BaseCard_default;
var init_BaseCard = __esm({
  "vue/capstone/ar/src/ui/BaseCard.vue"() {
    "use strict";
    _hoisted_12 = { class: "card" };
    _hoisted_22 = { key: 0 };
    _sfc2 = /* @__PURE__ */ _defineComponent2({
      __name: "BaseCard",
      props: {
        title: {}
      },
      setup(__props) {
        return (_ctx, _cache) => {
          return _openBlock2(), _createElementBlock2("section", _hoisted_12, [
            __props.title ? (_openBlock2(), _createElementBlock2(
              "h2",
              _hoisted_22,
              _toDisplayString2(__props.title),
              1
              /* TEXT */
            )) : _createCommentVNode("v-if", true),
            _renderSlot(_ctx.$slots, "default")
          ]);
        };
      }
    });
    BaseCard_default = _sfc2;
  }
});

// vue/capstone/ar/src/ui/LoadError.vue
import { defineComponent as _defineComponent3 } from "vue";
import { unref as _unref2, toDisplayString as _toDisplayString3, createElementVNode as _createElementVNode2, openBlock as _openBlock3, createElementBlock as _createElementBlock3 } from "vue";
import { storeToRefs as storeToRefs2 } from "pinia";
var _hoisted_13, _sfc3, LoadError_default;
var init_LoadError = __esm({
  "vue/capstone/ar/src/ui/LoadError.vue"() {
    "use strict";
    init_settings();
    _hoisted_13 = {
      role: "alert",
      class: "card"
    };
    _sfc3 = /* @__PURE__ */ _defineComponent3({
      __name: "LoadError",
      emits: ["retry"],
      setup(__props, { emit: __emit }) {
        const emit = __emit;
        const { t } = storeToRefs2(useSettings());
        return (_ctx, _cache) => {
          return _openBlock3(), _createElementBlock3("div", _hoisted_13, [
            _createElementVNode2(
              "p",
              null,
              _toDisplayString3(_unref2(t)("loadError")),
              1
              /* TEXT */
            ),
            _createElementVNode2(
              "button",
              {
                type: "button",
                onClick: _cache[0] || (_cache[0] = ($event) => emit("retry"))
              },
              _toDisplayString3(_unref2(t)("retry")),
              1
              /* TEXT */
            )
          ]);
        };
      }
    });
    LoadError_default = _sfc3;
  }
});

// vue/capstone/ar/src/ui/LoadingSkeleton.vue
import { defineComponent as _defineComponent4 } from "vue";
import { unref as _unref3, createElementVNode as _createElementVNode3, openBlock as _openBlock4, createElementBlock as _createElementBlock4 } from "vue";
import { storeToRefs as storeToRefs3 } from "pinia";
var _hoisted_14, _sfc4, LoadingSkeleton_default;
var init_LoadingSkeleton = __esm({
  "vue/capstone/ar/src/ui/LoadingSkeleton.vue"() {
    "use strict";
    init_settings();
    _hoisted_14 = ["aria-label"];
    _sfc4 = /* @__PURE__ */ _defineComponent4({
      __name: "LoadingSkeleton",
      setup(__props) {
        const { t } = storeToRefs3(useSettings());
        return (_ctx, _cache) => {
          return _openBlock4(), _createElementBlock4("div", {
            "aria-busy": "true",
            "aria-label": _unref3(t)("loading")
          }, [..._cache[0] || (_cache[0] = [
            _createElementVNode3(
              "div",
              { class: "skeleton" },
              null,
              -1
              /* CACHED */
            ),
            _createElementVNode3(
              "div",
              { class: "skeleton" },
              null,
              -1
              /* CACHED */
            ),
            _createElementVNode3(
              "div",
              { class: "skeleton" },
              null,
              -1
              /* CACHED */
            )
          ])], 8, _hoisted_14);
        };
      }
    });
    LoadingSkeleton_default = _sfc4;
  }
});

// vue/capstone/ar/src/features/products/ProductsPage.vue
var ProductsPage_exports = {};
__export(ProductsPage_exports, {
  default: () => ProductsPage_default
});
import { defineComponent as _defineComponent9 } from "vue";
import { unref as _unref8, openBlock as _openBlock9, createBlock as _createBlock4, toDisplayString as _toDisplayString8, createElementVNode as _createElementVNode7, renderList as _renderList4, Fragment as _Fragment4, createElementBlock as _createElementBlock9, createTextVNode as _createTextVNode4, resolveComponent as _resolveComponent4, withCtx as _withCtx5, createVNode as _createVNode5 } from "vue";
import { storeToRefs as storeToRefs8 } from "pinia";
var _hoisted_18, _hoisted_26, _hoisted_35, _sfc9, ProductsPage_default;
var init_ProductsPage = __esm({
  "vue/capstone/ar/src/features/products/ProductsPage.vue"() {
    "use strict";
    init_queries();
    init_settings();
    init_BaseCard();
    init_LoadError();
    init_LoadingSkeleton();
    _hoisted_18 = { scope: "col" };
    _hoisted_26 = { scope: "col" };
    _hoisted_35 = { scope: "col" };
    _sfc9 = /* @__PURE__ */ _defineComponent9({
      __name: "ProductsPage",
      setup(__props) {
        const { t } = storeToRefs8(useSettings());
        const { data: products2, isPending, isError, refetch } = useProducts();
        return (_ctx, _cache) => {
          const _component_RouterLink = _resolveComponent4("RouterLink");
          return _unref8(isPending) ? (_openBlock9(), _createBlock4(LoadingSkeleton_default, { key: 0 })) : _unref8(isError) ? (_openBlock9(), _createBlock4(LoadError_default, {
            key: 1,
            onRetry: _cache[0] || (_cache[0] = ($event) => _unref8(refetch)())
          })) : (_openBlock9(), _createElementBlock9(
            _Fragment4,
            { key: 2 },
            [
              _createElementVNode7(
                "h1",
                null,
                _toDisplayString8(_unref8(t)("products")),
                1
                /* TEXT */
              ),
              _createVNode5(BaseCard_default, null, {
                default: _withCtx5(() => [
                  _createElementVNode7("table", null, [
                    _createElementVNode7("thead", null, [
                      _createElementVNode7("tr", null, [
                        _createElementVNode7(
                          "th",
                          _hoisted_18,
                          _toDisplayString8(_unref8(t)("name")),
                          1
                          /* TEXT */
                        ),
                        _createElementVNode7(
                          "th",
                          _hoisted_26,
                          _toDisplayString8(_unref8(t)("price")),
                          1
                          /* TEXT */
                        ),
                        _createElementVNode7(
                          "th",
                          _hoisted_35,
                          _toDisplayString8(_unref8(t)("stock")),
                          1
                          /* TEXT */
                        )
                      ])
                    ]),
                    _createElementVNode7("tbody", null, [
                      (_openBlock9(true), _createElementBlock9(
                        _Fragment4,
                        null,
                        _renderList4(_unref8(products2), (p) => {
                          return _openBlock9(), _createElementBlock9("tr", {
                            key: p.id
                          }, [
                            _createElementVNode7("td", null, [
                              _createVNode5(_component_RouterLink, {
                                to: `/products/${p.id}`,
                                "aria-label": `${_unref8(t)("edit")}: ${p.name}`
                              }, {
                                default: _withCtx5(() => [
                                  _createTextVNode4(
                                    _toDisplayString8(p.name),
                                    1
                                    /* TEXT */
                                  )
                                ]),
                                _: 2
                                /* DYNAMIC */
                              }, 1032, ["to", "aria-label"])
                            ]),
                            _createElementVNode7(
                              "td",
                              null,
                              _toDisplayString8(_unref8(t).money(p.price)),
                              1
                              /* TEXT */
                            ),
                            _createElementVNode7(
                              "td",
                              null,
                              _toDisplayString8(p.stock),
                              1
                              /* TEXT */
                            )
                          ]);
                        }),
                        128
                        /* KEYED_FRAGMENT */
                      ))
                    ])
                  ])
                ]),
                _: 1
                /* STABLE */
              })
            ],
            64
            /* STABLE_FRAGMENT */
          ));
        };
      }
    });
    ProductsPage_default = _sfc9;
  }
});

// vue/capstone/ar/src/lib/useForm.ts
import { computed as computed4, nextTick, reactive, ref, watch } from "vue";
function useForm(schema, initial) {
  const values = reactive({ ...initial });
  const allErrors = ref({});
  const touched = reactive(/* @__PURE__ */ new Set());
  const submitted = ref(false);
  const submitting = ref(false);
  function check() {
    const result = schema.safeParse(values);
    const next = {};
    for (const issue of result.success ? [] : result.error.issues) next[issue.path[0]] ??= issue.message;
    allErrors.value = next;
    return result.success ? result.data : void 0;
  }
  watch(values, check, { deep: true });
  const errors = computed4(() => {
    const shown = {};
    for (const [key, message] of Object.entries(allErrors.value)) {
      if (submitted.value || touched.has(key)) shown[key] = message;
    }
    return shown;
  });
  async function focusFirstError() {
    await nextTick();
    document.querySelector("[aria-invalid='true']")?.focus();
  }
  function checkFields(fields) {
    fields.forEach((f) => touched.add(f));
    check();
    const ok = fields.every((f) => !allErrors.value[f]);
    if (!ok) void focusFirstError();
    return ok;
  }
  function handleSubmit(send2) {
    return async () => {
      submitted.value = true;
      const data = check();
      if (!data) return focusFirstError();
      submitting.value = true;
      try {
        const fromServer = await send2(data);
        if (fromServer) {
          allErrors.value = fromServer;
          void focusFirstError();
        }
      } finally {
        submitting.value = false;
      }
    };
  }
  return { values, errors, submitting, checkFields, handleSubmit, blur: (field) => touched.add(field) };
}
var init_useForm = __esm({
  "vue/capstone/ar/src/lib/useForm.ts"() {
    "use strict";
  }
});

// vue/capstone/ar/src/features/products/ProductForm.vue
import { defineComponent as _defineComponent10 } from "vue";
import { renderList as _renderList5, Fragment as _Fragment5, openBlock as _openBlock10, createElementBlock as _createElementBlock10, unref as _unref9, toDisplayString as _toDisplayString9, createElementVNode as _createElementVNode8, vModelText as _vModelText2, withDirectives as _withDirectives2, createCommentVNode as _createCommentVNode6, withModifiers as _withModifiers } from "vue";
import { computed as computed5, ref as ref2 } from "vue";
import { storeToRefs as storeToRefs9 } from "pinia";
import * as z3 from "zod";
var _hoisted_19, _hoisted_27, _hoisted_36, _hoisted_45, _hoisted_53, _sfc10, ProductForm_default;
var init_ProductForm = __esm({
  "vue/capstone/ar/src/features/products/ProductForm.vue"() {
    "use strict";
    init_useForm();
    init_settings();
    _hoisted_19 = ["for"];
    _hoisted_27 = ["id", "onUpdate:modelValue", "inputmode", "aria-invalid", "aria-describedby", "onBlur"];
    _hoisted_36 = ["id"];
    _hoisted_45 = ["disabled"];
    _hoisted_53 = {
      key: 0,
      role: "status",
      class: "done"
    };
    _sfc10 = /* @__PURE__ */ _defineComponent10({
      __name: "ProductForm",
      props: {
        product: {},
        onSave: { type: Function }
      },
      setup(__props) {
        const props = __props;
        const { t } = storeToRefs9(useSettings());
        const schema = computed5(
          () => z3.object({
            name: z3.string().trim().min(2, t.value("nameError")).max(40, t.value("nameError")),
            price: z3.coerce.number().int(t.value("priceError")).positive(t.value("priceError")),
            stock: z3.coerce.number().int(t.value("stockError")).min(0, t.value("stockError"))
          })
        );
        const { values, errors, submitting, blur, handleSubmit } = useForm(schema.value, {
          name: props.product.name,
          price: String(props.product.price),
          stock: String(props.product.stock)
        });
        const saved = ref2(false);
        const submit = handleSubmit(async (data) => {
          saved.value = false;
          const fromServer = await props.onSave({ ...props.product, ...data });
          if (!fromServer) saved.value = true;
          return fromServer;
        });
        return (_ctx, _cache) => {
          return _openBlock10(), _createElementBlock10(
            "form",
            {
              novalidate: "",
              onSubmit: _cache[0] || (_cache[0] = _withModifiers(
                //@ts-ignore
                (...args) => _unref9(submit) && _unref9(submit)(...args),
                ["prevent"]
              ))
            },
            [
              (_openBlock10(), _createElementBlock10(
                _Fragment5,
                null,
                _renderList5(["name", "price", "stock"], (field) => {
                  return _openBlock10(), _createElementBlock10(
                    _Fragment5,
                    { key: field },
                    [
                      _createElementVNode8("label", { for: field }, _toDisplayString9(_unref9(t)(field)), 9, _hoisted_19),
                      _withDirectives2(_createElementVNode8("input", {
                        id: field,
                        "onUpdate:modelValue": ($event) => _unref9(values)[field] = $event,
                        inputmode: field === "name" ? void 0 : "numeric",
                        "aria-invalid": !!_unref9(errors)[field],
                        "aria-describedby": `${field}-error`,
                        onBlur: ($event) => _unref9(blur)(field)
                      }, null, 40, _hoisted_27), [
                        [_vModelText2, _unref9(values)[field]]
                      ]),
                      _unref9(errors)[field] ? (_openBlock10(), _createElementBlock10("p", {
                        key: 0,
                        id: `${field}-error`,
                        class: "error"
                      }, _toDisplayString9(_unref9(errors)[field]), 9, _hoisted_36)) : _createCommentVNode6("v-if", true)
                    ],
                    64
                    /* STABLE_FRAGMENT */
                  );
                }),
                64
                /* STABLE_FRAGMENT */
              )),
              _createElementVNode8("p", null, [
                _createElementVNode8("button", {
                  type: "submit",
                  disabled: _unref9(submitting)
                }, _toDisplayString9(_unref9(submitting) ? _unref9(t)("saving") : _unref9(t)("save")), 9, _hoisted_45)
              ]),
              saved.value ? (_openBlock10(), _createElementBlock10(
                "p",
                _hoisted_53,
                _toDisplayString9(_unref9(t)("saved")),
                1
                /* TEXT */
              )) : _createCommentVNode6("v-if", true)
            ],
            32
            /* NEED_HYDRATION */
          );
        };
      }
    });
    ProductForm_default = _sfc10;
  }
});

// vue/capstone/ar/src/features/products/ProductPage.vue
var ProductPage_exports = {};
__export(ProductPage_exports, {
  default: () => ProductPage_default
});
import { defineComponent as _defineComponent11 } from "vue";
import { unref as _unref10, openBlock as _openBlock11, createBlock as _createBlock5, createCommentVNode as _createCommentVNode7, toDisplayString as _toDisplayString10, createElementVNode as _createElementVNode9, withCtx as _withCtx6, createVNode as _createVNode6, createTextVNode as _createTextVNode5, resolveComponent as _resolveComponent5, Fragment as _Fragment6, createElementBlock as _createElementBlock11 } from "vue";
import { storeToRefs as storeToRefs10 } from "pinia";
var _sfc11, ProductPage_default;
var init_ProductPage = __esm({
  "vue/capstone/ar/src/features/products/ProductPage.vue"() {
    "use strict";
    init_client();
    init_queries();
    init_settings();
    init_BaseCard();
    init_LoadError();
    init_LoadingSkeleton();
    init_ProductForm();
    _sfc11 = /* @__PURE__ */ _defineComponent11({
      __name: "ProductPage",
      props: {
        id: {}
      },
      setup(__props) {
        const props = __props;
        const { t } = storeToRefs10(useSettings());
        const { data: product, isPending, isError, refetch } = useProduct(() => props.id);
        const save = useSaveProduct();
        async function onSave(changed) {
          try {
            await save.mutateAsync(changed);
          } catch (error) {
            if (error instanceof ApiError && error.status === 422) return error.errors;
            throw error;
          }
        }
        return (_ctx, _cache) => {
          const _component_RouterLink = _resolveComponent5("RouterLink");
          return _unref10(isPending) ? (_openBlock11(), _createBlock5(LoadingSkeleton_default, { key: 0 })) : _unref10(isError) ? (_openBlock11(), _createBlock5(LoadError_default, {
            key: 1,
            onRetry: _cache[0] || (_cache[0] = ($event) => _unref10(refetch)())
          })) : _unref10(product) ? (_openBlock11(), _createElementBlock11(
            _Fragment6,
            { key: 2 },
            [
              _createElementVNode9(
                "h1",
                null,
                _toDisplayString10(_unref10(product).name),
                1
                /* TEXT */
              ),
              _createVNode6(BaseCard_default, null, {
                default: _withCtx6(() => [
                  (_openBlock11(), _createBlock5(ProductForm_default, {
                    key: _unref10(product).id,
                    product: _unref10(product),
                    "on-save": onSave
                  }, null, 8, ["product"]))
                ]),
                _: 1
                /* STABLE */
              }),
              _createVNode6(_component_RouterLink, { to: "/products" }, {
                default: _withCtx6(() => [
                  _createTextVNode5(
                    _toDisplayString10(_unref10(t)("products")),
                    1
                    /* TEXT */
                  )
                ]),
                _: 1
                /* STABLE */
              })
            ],
            64
            /* STABLE_FRAGMENT */
          )) : _createCommentVNode7("v-if", true);
        };
      }
    });
    ProductPage_default = _sfc11;
  }
});

// vue/capstone/ar/page.ts
import { createApp } from "vue";
import { createPinia } from "pinia";
import { createMemoryHistory, createRouter } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";

// vue/capstone/ar/src/api/fake-server.ts
var day = 24 * 60 * 60 * 1e3;
var today = Math.floor(Date.now() / day) * day;
var seed = 7;
var random = () => (seed = seed * 16807 % 2147483647) / 2147483647;
var pick = (list) => list[Math.floor(random() * list.length)];
var names = "\u0633\u0627\u0631\u0629 \u0639\u0627\u062F\u0644|\u0639\u0645\u0631 \u0641\u0627\u0631\u0648\u0642|\u0645\u0646\u0649 \u0633\u0645\u064A\u0631|\u064A\u0648\u0633\u0641 \u0647\u0627\u0646\u064A|\u0644\u064A\u0644\u0649 \u0646\u0628\u064A\u0644|\u0643\u0631\u064A\u0645 \u0641\u062A\u062D\u064A|\u0646\u0648\u0631 \u062D\u0633\u0646|\u0639\u0644\u064A \u0645\u0635\u0637\u0641\u0649|\u0647\u0646\u0627 \u0648\u0627\u0626\u0644".split("|");
var cities = "\u0627\u0644\u0642\u0627\u0647\u0631\u0629|\u0627\u0644\u062C\u064A\u0632\u0629|\u0627\u0644\u0625\u0633\u0643\u0646\u062F\u0631\u064A\u0629|\u0627\u0644\u0645\u0646\u0635\u0648\u0631\u0629|\u0623\u0633\u0648\u0627\u0646".split("|");
var statuses = ["new", "paid", "paid", "shipped", "shipped", "shipped", "cancelled"];
var orders = Array.from({ length: 36 }, (_, i) => ({
  id: 1036 - i,
  customer: names[i % names.length],
  city: pick(cities),
  total: 2500 + Math.round(random() * 40) * 500,
  status: i < 3 ? "new" : pick(statuses),
  createdAt: new Date(today + 20 * 60 * 60 * 1e3 - Math.floor(i / 4.5) * day - Math.floor(random() * 8) * 60 * 60 * 1e3).toISOString()
}));
var products = [
  { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25e3, stock: 12 },
  { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8500, stock: 40 },
  { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12e3, stock: 0 },
  { id: 4, name: "\u0645\u0644\u0635\u0642 \u0628\u0650\u062A", price: 1500, stock: 300 }
];
var server = { delay: 250, failNextChange: false };
var json = (data, status = 200) => new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
async function fakeFetch(input, init) {
  await new Promise((resolve) => setTimeout(resolve, server.delay));
  const path = new URL(String(input), "http://shop").pathname;
  const method = init?.method ?? "GET";
  const body = init?.body ? JSON.parse(String(init.body)) : {};
  if (method !== "GET" && server.failNextChange) {
    server.failNextChange = false;
    return json({ message: "busy" }, 503);
  }
  if (path === "/api/orders") return json(orders);
  if (path === "/api/products") return json(products);
  const order = /^\/api\/orders\/(\d+)$/.exec(path);
  if (order) {
    const found = orders.find((o) => o.id === Number(order[1]));
    if (!found) return json({}, 404);
    if (method === "PATCH") found.status = body.status;
    return json(found);
  }
  const product = /^\/api\/products\/(\d+)$/.exec(path);
  if (product) {
    const found = products.find((p) => p.id === Number(product[1]));
    if (!found) return json({}, 404);
    if (method === "PUT") {
      const name = String(body.name).trim();
      if (products.some((p) => p.id !== found.id && p.name.toLowerCase() === name.toLowerCase())) {
        return json({ errors: { name: "\u0645\u0646\u062A\u062C \u0622\u062E\u0631 \u064A\u062D\u0645\u0644 \u0647\u0630\u0627 \u0627\u0644\u0627\u0633\u0645." } }, 422);
      }
      Object.assign(found, { name, price: body.price, stock: body.stock });
    }
    return json(found);
  }
  return json({}, 404);
}

// vue/capstone/ar/src/app/App.vue
init_settings();
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, resolveComponent as _resolveComponent, withCtx as _withCtx, createVNode as _createVNode, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { watchEffect } from "vue";
import { storeToRefs } from "pinia";
var _hoisted_1 = { class: "app" };
var _hoisted_2 = {
  class: "skip",
  href: "#main"
};
var _hoisted_3 = ["aria-label"];
var _hoisted_4 = { class: "brand" };
var _hoisted_5 = { class: "top" };
var _hoisted_6 = ["lang"];
var _hoisted_7 = ["aria-pressed"];
var _hoisted_8 = { id: "main" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "App",
  setup(__props) {
    const settings = useSettings();
    const { t, lang, dark } = storeToRefs(settings);
    watchEffect(() => {
      const html = document.documentElement;
      html.lang = lang.value;
      html.dir = lang.value === "ar" ? "rtl" : "ltr";
      html.classList.toggle("dark", dark.value);
    });
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent("RouterLink");
      const _component_RouterView = _resolveComponent("RouterView");
      return _openBlock(), _createElementBlock("div", _hoisted_1, [
        _createElementVNode(
          "a",
          _hoisted_2,
          _toDisplayString(_unref(t)("skip")),
          1
          /* TEXT */
        ),
        _createElementVNode("nav", {
          class: "side",
          "aria-label": _unref(t)("brand")
        }, [
          _createElementVNode(
            "span",
            _hoisted_4,
            _toDisplayString(_unref(t)("brand")),
            1
            /* TEXT */
          ),
          _createVNode(_component_RouterLink, {
            to: "/",
            "exact-active-class": "active",
            "active-class": ""
          }, {
            default: _withCtx(() => [
              _createTextVNode(
                _toDisplayString(_unref(t)("overview")),
                1
                /* TEXT */
              )
            ]),
            _: 1
            /* STABLE */
          }),
          _createVNode(_component_RouterLink, {
            to: "/orders",
            "active-class": "active"
          }, {
            default: _withCtx(() => [
              _createTextVNode(
                _toDisplayString(_unref(t)("orders")),
                1
                /* TEXT */
              )
            ]),
            _: 1
            /* STABLE */
          }),
          _createVNode(_component_RouterLink, {
            to: "/products",
            "active-class": "active"
          }, {
            default: _withCtx(() => [
              _createTextVNode(
                _toDisplayString(_unref(t)("products")),
                1
                /* TEXT */
              )
            ]),
            _: 1
            /* STABLE */
          })
        ], 8, _hoisted_3),
        _createElementVNode("div", null, [
          _createElementVNode("header", _hoisted_5, [
            _createElementVNode("button", {
              type: "button",
              class: "secondary",
              lang: _unref(lang) === "en" ? "ar" : "en",
              onClick: _cache[0] || (_cache[0] = ($event) => _unref(settings).toggleLanguage())
            }, _toDisplayString(_unref(t)("switchLanguage")), 9, _hoisted_6),
            _createElementVNode("button", {
              type: "button",
              class: "secondary",
              "aria-pressed": _unref(dark),
              onClick: _cache[1] || (_cache[1] = ($event) => _unref(settings).toggleDark())
            }, _toDisplayString(_unref(t)("dark")), 9, _hoisted_7)
          ]),
          _createElementVNode("main", _hoisted_8, [
            _createVNode(_component_RouterView)
          ])
        ])
      ]);
    };
  }
});
var App_default = _sfc;

// vue/capstone/ar/src/app/routes.ts
import { h } from "vue";

// vue/capstone/ar/src/features/overview/OverviewPage.vue
init_queries();
import { defineComponent as _defineComponent5 } from "vue";
import { unref as _unref4, openBlock as _openBlock5, createBlock as _createBlock, createCommentVNode as _createCommentVNode2, toDisplayString as _toDisplayString4, createElementVNode as _createElementVNode4, renderList as _renderList, Fragment as _Fragment, createElementBlock as _createElementBlock5, normalizeStyle as _normalizeStyle, withCtx as _withCtx2, createVNode as _createVNode2 } from "vue";
import { computed as computed2 } from "vue";
import { storeToRefs as storeToRefs4 } from "pinia";

// vue/capstone/ar/src/lib/orders.ts
var PAGE_SIZE = 8;
var STATUSES = ["new", "paid", "shipped", "cancelled"];
function readFilters(params) {
  const status = params.get("status");
  return {
    status: STATUSES.includes(status) ? status : "all",
    q: params.get("q") ?? "",
    page: Math.max(1, Number(params.get("page")) || 1)
  };
}
function filterOrders(orders2, { status, q, page }) {
  const query = q.trim().toLocaleLowerCase();
  const matching = orders2.filter((o) => status === "all" || o.status === status).filter((o) => !query || o.customer.toLocaleLowerCase().includes(query)).toSorted((a, b) => b.createdAt.localeCompare(a.createdAt));
  const pages = Math.max(1, Math.ceil(matching.length / PAGE_SIZE));
  const current = Math.min(page, pages);
  return { rows: matching.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE), page: current, pages, count: matching.length };
}
function overview(orders2, now) {
  const earning = orders2.filter((o) => o.status === "paid" || o.status === "shipped");
  const revenue = earning.reduce((sum, o) => sum + o.total, 0);
  const days = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(now);
    date.setUTCDate(date.getUTCDate() - (6 - i));
    const key = date.toISOString().slice(0, 10);
    const total = earning.filter((o) => o.createdAt.startsWith(key)).reduce((sum, o) => sum + o.total, 0);
    return { day: key, total };
  });
  return {
    revenue,
    orders: orders2.filter((o) => o.status !== "cancelled").length,
    average: earning.length ? Math.round(revenue / earning.length) : 0,
    toShip: orders2.filter((o) => o.status === "paid").length,
    days
  };
}

// vue/capstone/ar/src/features/overview/OverviewPage.vue
init_settings();
init_BaseCard();
init_LoadError();
init_LoadingSkeleton();
var _hoisted_15 = { class: "kpis" };
var _hoisted_23 = { class: "bars" };
var _hoisted_32 = { "aria-hidden": "true" };
var _hoisted_42 = { class: "sr-only" };
var _sfc5 = /* @__PURE__ */ _defineComponent5({
  __name: "OverviewPage",
  setup(__props) {
    const { t } = storeToRefs4(useSettings());
    const { data, isPending, isError, refetch } = useOrders();
    const o = computed2(() => data.value ? overview(data.value, /* @__PURE__ */ new Date()) : null);
    const highest = computed2(() => Math.max(1, ...o.value?.days.map((d) => d.total) ?? []));
    const kpis = computed2(
      () => o.value ? [
        [t.value("revenue"), t.value.money(o.value.revenue)],
        [t.value("ordersCount"), String(o.value.orders)],
        [t.value("average"), t.value.money(o.value.average)],
        [t.value("toShip"), String(o.value.toShip)]
      ] : []
    );
    return (_ctx, _cache) => {
      return _unref4(isPending) ? (_openBlock5(), _createBlock(LoadingSkeleton_default, { key: 0 })) : _unref4(isError) ? (_openBlock5(), _createBlock(LoadError_default, {
        key: 1,
        onRetry: _cache[0] || (_cache[0] = ($event) => _unref4(refetch)())
      })) : o.value ? (_openBlock5(), _createElementBlock5(
        _Fragment,
        { key: 2 },
        [
          _createElementVNode4(
            "h1",
            null,
            _toDisplayString4(_unref4(t)("overview")),
            1
            /* TEXT */
          ),
          _createElementVNode4("div", _hoisted_15, [
            (_openBlock5(true), _createElementBlock5(
              _Fragment,
              null,
              _renderList(kpis.value, ([label, value]) => {
                return _openBlock5(), _createElementBlock5("figure", {
                  key: label,
                  class: "card kpi"
                }, [
                  _createElementVNode4(
                    "p",
                    null,
                    _toDisplayString4(label),
                    1
                    /* TEXT */
                  ),
                  _createElementVNode4(
                    "strong",
                    null,
                    _toDisplayString4(value),
                    1
                    /* TEXT */
                  )
                ]);
              }),
              128
              /* KEYED_FRAGMENT */
            ))
          ]),
          _createVNode2(BaseCard_default, {
            title: _unref4(t)("lastWeek")
          }, {
            default: _withCtx2(() => [
              _createElementVNode4("ol", _hoisted_23, [
                (_openBlock5(true), _createElementBlock5(
                  _Fragment,
                  null,
                  _renderList(o.value.days, (d) => {
                    return _openBlock5(), _createElementBlock5("li", {
                      key: d.day
                    }, [
                      _createElementVNode4(
                        "span",
                        {
                          class: "bar",
                          style: _normalizeStyle({ blockSize: `${d.total / highest.value * 100}%` })
                        },
                        null,
                        4
                        /* STYLE */
                      ),
                      _createElementVNode4(
                        "span",
                        _hoisted_32,
                        _toDisplayString4(_unref4(t).weekday(d.day)),
                        1
                        /* TEXT */
                      ),
                      _createElementVNode4(
                        "span",
                        _hoisted_42,
                        _toDisplayString4(`${_unref4(t).weekday(d.day)}: ${_unref4(t).money(d.total)}`),
                        1
                        /* TEXT */
                      )
                    ]);
                  }),
                  128
                  /* KEYED_FRAGMENT */
                ))
              ])
            ]),
            _: 1
            /* STABLE */
          }, 8, ["title"])
        ],
        64
        /* STABLE_FRAGMENT */
      )) : _createCommentVNode2("v-if", true);
    };
  }
});
var OverviewPage_default = _sfc5;

// vue/capstone/ar/src/features/orders/OrdersPage.vue
init_queries();
import { defineComponent as _defineComponent7 } from "vue";
import { unref as _unref6, toDisplayString as _toDisplayString6, createElementVNode as _createElementVNode5, renderList as _renderList2, Fragment as _Fragment2, openBlock as _openBlock7, createElementBlock as _createElementBlock7, createTextVNode as _createTextVNode2, resolveComponent as _resolveComponent2, withCtx as _withCtx3, createBlock as _createBlock2, vModelText as _vModelText, withDirectives as _withDirectives, createCommentVNode as _createCommentVNode3, createVNode as _createVNode3 } from "vue";
import { computed as computed3 } from "vue";
import { useRoute, useRouter } from "vue-router";
import { storeToRefs as storeToRefs6 } from "pinia";
init_settings();
init_LoadError();
init_LoadingSkeleton();

// vue/capstone/ar/src/ui/StatusBadge.vue
init_settings();
import { defineComponent as _defineComponent6 } from "vue";
import { unref as _unref5, toDisplayString as _toDisplayString5, normalizeClass as _normalizeClass, openBlock as _openBlock6, createElementBlock as _createElementBlock6 } from "vue";
import { storeToRefs as storeToRefs5 } from "pinia";
var _sfc6 = /* @__PURE__ */ _defineComponent6({
  __name: "StatusBadge",
  props: {
    status: {}
  },
  setup(__props) {
    const { t } = storeToRefs5(useSettings());
    return (_ctx, _cache) => {
      return _openBlock6(), _createElementBlock6(
        "span",
        {
          class: _normalizeClass(["badge", __props.status])
        },
        _toDisplayString5(_unref5(t)(__props.status)),
        3
        /* TEXT, CLASS */
      );
    };
  }
});
var StatusBadge_default = _sfc6;

// vue/capstone/ar/src/features/orders/OrdersPage.vue
var _hoisted_16 = ["aria-label"];
var _hoisted_24 = {
  for: "q",
  class: "sr-only"
};
var _hoisted_33 = ["placeholder"];
var _hoisted_43 = {
  key: 2,
  role: "status"
};
var _hoisted_52 = {
  key: 3,
  class: "card"
};
var _hoisted_62 = { class: "sr-only" };
var _hoisted_72 = { scope: "col" };
var _hoisted_82 = { scope: "col" };
var _hoisted_9 = { scope: "col" };
var _hoisted_10 = { scope: "col" };
var _hoisted_11 = { class: "pager" };
var _hoisted_122 = { key: 1 };
var _hoisted_132 = { key: 3 };
var _sfc7 = /* @__PURE__ */ _defineComponent7({
  __name: "OrdersPage",
  setup(__props) {
    const { t } = storeToRefs6(useSettings());
    const route = useRoute();
    const router2 = useRouter();
    const { data, isPending, isError, refetch } = useOrders();
    const filters = computed3(() => {
      const params = new URLSearchParams();
      for (const [key, value] of Object.entries(route.query)) if (typeof value === "string") params.set(key, value);
      return readFilters(params);
    });
    const result = computed3(() => data.value ? filterOrders(data.value, filters.value) : null);
    const link = (changes) => ({ query: { ...route.query, ...changes } });
    const search = computed3({
      get: () => filters.value.q,
      set: (q) => router2.replace(link({ q: q || void 0, page: void 0 }))
    });
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent2("RouterLink");
      return _openBlock7(), _createElementBlock7(
        _Fragment2,
        null,
        [
          _createElementVNode5(
            "h1",
            null,
            _toDisplayString6(_unref6(t)("orders")),
            1
            /* TEXT */
          ),
          _createElementVNode5("nav", {
            class: "filters",
            "aria-label": _unref6(t)("status")
          }, [
            (_openBlock7(true), _createElementBlock7(
              _Fragment2,
              null,
              _renderList2(["all", ..._unref6(STATUSES)], (s) => {
                return _openBlock7(), _createBlock2(_component_RouterLink, {
                  key: s,
                  to: link({ status: s === "all" ? void 0 : s, page: void 0 }),
                  "aria-current": filters.value.status === s ? "page" : void 0
                }, {
                  default: _withCtx3(() => [
                    _createTextVNode2(
                      _toDisplayString6(_unref6(t)(s)),
                      1
                      /* TEXT */
                    )
                  ]),
                  _: 2
                  /* DYNAMIC */
                }, 1032, ["to", "aria-current"]);
              }),
              128
              /* KEYED_FRAGMENT */
            ))
          ], 8, _hoisted_16),
          _createElementVNode5(
            "label",
            _hoisted_24,
            _toDisplayString6(_unref6(t)("search")),
            1
            /* TEXT */
          ),
          _withDirectives(_createElementVNode5("input", {
            id: "q",
            "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => search.value = $event),
            type: "search",
            placeholder: _unref6(t)("search")
          }, null, 8, _hoisted_33), [
            [_vModelText, search.value]
          ]),
          _unref6(isPending) ? (_openBlock7(), _createBlock2(LoadingSkeleton_default, { key: 0 })) : _unref6(isError) ? (_openBlock7(), _createBlock2(LoadError_default, {
            key: 1,
            onRetry: _cache[1] || (_cache[1] = ($event) => _unref6(refetch)())
          })) : result.value && result.value.count === 0 ? (_openBlock7(), _createElementBlock7(
            "p",
            _hoisted_43,
            _toDisplayString6(_unref6(t)("none")),
            1
            /* TEXT */
          )) : result.value ? (_openBlock7(), _createElementBlock7("section", _hoisted_52, [
            _createElementVNode5("table", null, [
              _createElementVNode5(
                "caption",
                _hoisted_62,
                _toDisplayString6(_unref6(t)("found", { count: result.value.count })),
                1
                /* TEXT */
              ),
              _createElementVNode5("thead", null, [
                _createElementVNode5("tr", null, [
                  _createElementVNode5(
                    "th",
                    _hoisted_72,
                    _toDisplayString6(_unref6(t)("order")),
                    1
                    /* TEXT */
                  ),
                  _createElementVNode5(
                    "th",
                    _hoisted_82,
                    _toDisplayString6(_unref6(t)("customer")),
                    1
                    /* TEXT */
                  ),
                  _createElementVNode5(
                    "th",
                    _hoisted_9,
                    _toDisplayString6(_unref6(t)("total")),
                    1
                    /* TEXT */
                  ),
                  _createElementVNode5(
                    "th",
                    _hoisted_10,
                    _toDisplayString6(_unref6(t)("status")),
                    1
                    /* TEXT */
                  )
                ])
              ]),
              _createElementVNode5("tbody", null, [
                (_openBlock7(true), _createElementBlock7(
                  _Fragment2,
                  null,
                  _renderList2(result.value.rows, (o) => {
                    return _openBlock7(), _createElementBlock7("tr", {
                      key: o.id
                    }, [
                      _createElementVNode5("td", null, [
                        _createVNode3(_component_RouterLink, {
                          to: `/orders/${o.id}`
                        }, {
                          default: _withCtx3(() => [
                            _createTextVNode2(
                              "#" + _toDisplayString6(o.id),
                              1
                              /* TEXT */
                            )
                          ]),
                          _: 2
                          /* DYNAMIC */
                        }, 1032, ["to"])
                      ]),
                      _createElementVNode5(
                        "td",
                        null,
                        _toDisplayString6(o.customer),
                        1
                        /* TEXT */
                      ),
                      _createElementVNode5(
                        "td",
                        null,
                        _toDisplayString6(_unref6(t).money(o.total)),
                        1
                        /* TEXT */
                      ),
                      _createElementVNode5("td", null, [
                        _createVNode3(StatusBadge_default, {
                          status: o.status
                        }, null, 8, ["status"])
                      ])
                    ]);
                  }),
                  128
                  /* KEYED_FRAGMENT */
                ))
              ])
            ]),
            _createElementVNode5("div", _hoisted_11, [
              result.value.page > 1 ? (_openBlock7(), _createBlock2(_component_RouterLink, {
                key: 0,
                to: link({ page: String(result.value.page - 1) })
              }, {
                default: _withCtx3(() => [
                  _createTextVNode2(
                    _toDisplayString6(_unref6(t)("previous")),
                    1
                    /* TEXT */
                  )
                ]),
                _: 1
                /* STABLE */
              }, 8, ["to"])) : (_openBlock7(), _createElementBlock7("span", _hoisted_122)),
              _createElementVNode5(
                "span",
                null,
                _toDisplayString6(_unref6(t)("page", { page: result.value.page, pages: result.value.pages })),
                1
                /* TEXT */
              ),
              result.value.page < result.value.pages ? (_openBlock7(), _createBlock2(_component_RouterLink, {
                key: 2,
                to: link({ page: String(result.value.page + 1) })
              }, {
                default: _withCtx3(() => [
                  _createTextVNode2(
                    _toDisplayString6(_unref6(t)("next")),
                    1
                    /* TEXT */
                  )
                ]),
                _: 1
                /* STABLE */
              }, 8, ["to"])) : (_openBlock7(), _createElementBlock7("span", _hoisted_132))
            ])
          ])) : _createCommentVNode3("v-if", true)
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var OrdersPage_default = _sfc7;

// vue/capstone/ar/src/features/orders/OrderPage.vue
init_queries();
import { defineComponent as _defineComponent8 } from "vue";
import { unref as _unref7, openBlock as _openBlock8, createBlock as _createBlock3, createCommentVNode as _createCommentVNode4, toDisplayString as _toDisplayString7, createElementVNode as _createElementVNode6, createVNode as _createVNode4, renderList as _renderList3, Fragment as _Fragment3, createElementBlock as _createElementBlock8, withCtx as _withCtx4, createTextVNode as _createTextVNode3, resolveComponent as _resolveComponent3 } from "vue";
import { storeToRefs as storeToRefs7 } from "pinia";
init_settings();
init_BaseCard();
init_LoadError();
init_LoadingSkeleton();
var _hoisted_17 = { "aria-live": "polite" };
var _hoisted_25 = { class: "actions" };
var _hoisted_34 = ["disabled", "onClick"];
var _hoisted_44 = {
  key: 0,
  role: "alert",
  class: "error"
};
var _sfc8 = /* @__PURE__ */ _defineComponent8({
  __name: "OrderPage",
  props: {
    id: {}
  },
  setup(__props) {
    const props = __props;
    const { t } = storeToRefs7(useSettings());
    const { data: order, isPending, isError, refetch } = useOrder(() => props.id);
    const setStatus = useSetStatus(() => props.id);
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent3("RouterLink");
      return _unref7(isPending) ? (_openBlock8(), _createBlock3(LoadingSkeleton_default, { key: 0 })) : _unref7(isError) ? (_openBlock8(), _createBlock3(LoadError_default, {
        key: 1,
        onRetry: _cache[0] || (_cache[0] = ($event) => _unref7(refetch)())
      })) : _unref7(order) ? (_openBlock8(), _createElementBlock8(
        _Fragment3,
        { key: 2 },
        [
          _createElementVNode6(
            "h1",
            null,
            _toDisplayString7(_unref7(t)("orderTitle", { id: String(_unref7(order).id) })),
            1
            /* TEXT */
          ),
          _createVNode4(BaseCard_default, null, {
            default: _withCtx4(() => [
              _createElementVNode6("dl", null, [
                _createElementVNode6(
                  "dt",
                  null,
                  _toDisplayString7(_unref7(t)("customer")),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dd",
                  null,
                  _toDisplayString7(_unref7(order).customer),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dt",
                  null,
                  _toDisplayString7(_unref7(t)("city")),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dd",
                  null,
                  _toDisplayString7(_unref7(order).city),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dt",
                  null,
                  _toDisplayString7(_unref7(t)("date")),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dd",
                  null,
                  _toDisplayString7(_unref7(t).date(_unref7(order).createdAt)),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dt",
                  null,
                  _toDisplayString7(_unref7(t)("total")),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dd",
                  null,
                  _toDisplayString7(_unref7(t).money(_unref7(order).total)),
                  1
                  /* TEXT */
                ),
                _createElementVNode6(
                  "dt",
                  null,
                  _toDisplayString7(_unref7(t)("status")),
                  1
                  /* TEXT */
                ),
                _createElementVNode6("dd", _hoisted_17, [
                  _createVNode4(StatusBadge_default, {
                    status: _unref7(order).status
                  }, null, 8, ["status"])
                ])
              ]),
              _createElementVNode6(
                "p",
                null,
                _toDisplayString7(_unref7(t)("markAs")),
                1
                /* TEXT */
              ),
              _createElementVNode6("div", _hoisted_25, [
                (_openBlock8(true), _createElementBlock8(
                  _Fragment3,
                  null,
                  _renderList3(_unref7(STATUSES).filter((s) => s !== _unref7(order).status), (s) => {
                    return _openBlock8(), _createElementBlock8("button", {
                      key: s,
                      type: "button",
                      class: "secondary",
                      disabled: _unref7(setStatus).isPending.value,
                      onClick: ($event) => _unref7(setStatus).mutate(s)
                    }, _toDisplayString7(_unref7(t)(s)), 9, _hoisted_34);
                  }),
                  128
                  /* KEYED_FRAGMENT */
                ))
              ]),
              _unref7(setStatus).isError.value ? (_openBlock8(), _createElementBlock8(
                "p",
                _hoisted_44,
                _toDisplayString7(_unref7(t)("failed")),
                1
                /* TEXT */
              )) : _createCommentVNode4("v-if", true)
            ]),
            _: 1
            /* STABLE */
          }),
          _createVNode4(_component_RouterLink, { to: "/orders" }, {
            default: _withCtx4(() => [
              _createTextVNode3(
                _toDisplayString7(_unref7(t)("allOrders")),
                1
                /* TEXT */
              )
            ]),
            _: 1
            /* STABLE */
          })
        ],
        64
        /* STABLE_FRAGMENT */
      )) : _createCommentVNode4("v-if", true);
    };
  }
});
var OrderPage_default = _sfc8;

// vue/capstone/ar/src/app/routes.ts
var id = (route) => ({ id: Number(route.params.id) });
var routes = [
  { path: "/", component: OverviewPage_default },
  {
    path: "/orders",
    children: [
      { path: "", component: OrdersPage_default },
      { path: ":id(\\d+)", component: OrderPage_default, props: id }
    ]
  },
  {
    path: "/products",
    // يُحمَّل حين يُفتح فقط: كود النموذج ليس في التنزيل الأول
    children: [
      { path: "", component: () => Promise.resolve().then(() => (init_ProductsPage(), ProductsPage_exports)) },
      { path: ":id(\\d+)", component: () => Promise.resolve().then(() => (init_ProductPage(), ProductPage_exports)), props: id }
    ]
  },
  { path: "/:path(.*)*", component: { render: () => h("p", { role: "alert" }, "404") } }
];

// vue/capstone/ar/page.ts
window.fetch = fakeFetch;
Object.assign(window, { server });
localStorage.clear();
var router = createRouter({ history: createMemoryHistory(), routes });
await router.push("/");
createApp(App_default).use(createPinia()).use(router).use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 3e4, retry: false } } } }).mount("#app");
