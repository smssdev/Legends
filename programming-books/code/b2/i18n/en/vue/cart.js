// i18n/en/vue/cart.ts
import { createApp } from "vue";

// i18n/en/vue/CartApp.vue
import { defineComponent as _defineComponent2 } from "vue";
import { openBlock as _openBlock2, createBlock as _createBlock } from "vue";

// i18n/en/vue/Cart.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";

// i18n/en/vue/i18n.ts
import { computed, inject, provide, ref, watchEffect } from "vue";

// i18n/en/messages.ts
var messages = {
  en: {
    "cart.title": "Your cart",
    "cart.items": { one: "{count} item", other: "{count} items" },
    "cart.total": "Total: {total}",
    "cart.empty": "Your cart is empty."
  },
  ar: {
    "cart.title": "\u0633\u0644\u062A\u0643",
    "cart.items": {
      zero: "\u0644\u0627 \u0639\u0646\u0627\u0635\u0631",
      one: "\u0639\u0646\u0635\u0631 \u0648\u0627\u062D\u062F",
      two: "\u0639\u0646\u0635\u0631\u0627\u0646",
      few: "{count} \u0639\u0646\u0627\u0635\u0631",
      many: "{count} \u0639\u0646\u0635\u0631\u0627\u064B",
      other: "{count} \u0639\u0646\u0635\u0631"
    },
    "cart.total": "\u0627\u0644\u0645\u062C\u0645\u0648\u0639: {total}",
    "cart.empty": "\u0633\u0644\u062A\u0643 \u0641\u0627\u0631\u063A\u0629."
  }
};
function translate(locale, key, values = {}) {
  const entry = messages[locale][key];
  const text = typeof entry === "string" ? entry : entry[new Intl.PluralRules(locale).select(Number(values.count ?? 0))] ?? entry.other ?? "";
  const format = new Intl.NumberFormat(locale);
  return text.replace(/\{(\w+)\}/g, (_, name) => {
    const value = values[name];
    return typeof value === "number" ? format.format(value) : String(value ?? "");
  });
}

// i18n/en/vue/i18n.ts
var I18nKey = /* @__PURE__ */ Symbol("i18n");
function provideI18n(initial) {
  const locale = ref(initial);
  watchEffect(() => {
    document.documentElement.lang = locale.value;
    document.documentElement.dir = locale.value === "ar" ? "rtl" : "ltr";
  });
  const t = computed(
    () => (key, values) => translate(locale.value, key, values)
  );
  const money = computed(() => {
    const currency = new Intl.NumberFormat(locale.value === "ar" ? "ar-EG" : "en-EG", { style: "currency", currency: "EGP" });
    return (v) => currency.format(v);
  });
  provide(I18nKey, { locale, t, money });
}
function useI18n() {
  const value = inject(I18nKey);
  if (!value) throw new Error("useI18n() must be used inside a component that called provideI18n()");
  return value;
}

// i18n/en/vue/Cart.vue
var _hoisted_1 = { class: "card" };
var _hoisted_2 = { class: "badge" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Cart",
  setup(__props) {
    const LINES = [
      { name: "Code from Zero", price: 250 },
      { name: "Bit mug", price: 85 }
    ];
    const { t, money, locale } = useI18n();
    const total = LINES.reduce((sum, l) => sum + l.price, 0);
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("section", _hoisted_1, [
        _createElementVNode("h2", null, [
          _createTextVNode(
            _toDisplayString(_unref(t)("cart.title")) + " ",
            1
            /* TEXT */
          ),
          _createElementVNode(
            "span",
            _hoisted_2,
            _toDisplayString(_unref(t)("cart.items", { count: LINES.length })),
            1
            /* TEXT */
          )
        ]),
        (_openBlock(), _createElementBlock(
          _Fragment,
          null,
          _renderList(LINES, (l) => {
            return _createElementVNode("div", {
              key: l.name,
              class: "row"
            }, [
              _createElementVNode(
                "bdi",
                null,
                _toDisplayString(l.name),
                1
                /* TEXT */
              ),
              _createElementVNode(
                "span",
                null,
                _toDisplayString(_unref(money)(l.price)),
                1
                /* TEXT */
              )
            ]);
          }),
          64
          /* STABLE_FRAGMENT */
        )),
        _createElementVNode("p", null, [
          _createElementVNode(
            "b",
            null,
            _toDisplayString(_unref(t)("cart.total", { total: _unref(money)(_unref(total)) })),
            1
            /* TEXT */
          )
        ]),
        _createElementVNode(
          "button",
          {
            type: "button",
            class: "next",
            onClick: _cache[0] || (_cache[0] = ($event) => locale.value = _unref(locale) === "ar" ? "en" : "ar")
          },
          _toDisplayString(_unref(locale) === "ar" ? "English" : "\u0627\u0644\u0639\u0631\u0628\u064A\u0629"),
          1
          /* TEXT */
        )
      ]);
    };
  }
});
var Cart_default = _sfc;

// i18n/en/vue/CartApp.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "CartApp",
  setup(__props) {
    provideI18n("en");
    return (_ctx, _cache) => {
      return _openBlock2(), _createBlock(Cart_default);
    };
  }
});
var CartApp_default = _sfc2;

// i18n/en/vue/cart.ts
createApp(CartApp_default).mount("#app");
