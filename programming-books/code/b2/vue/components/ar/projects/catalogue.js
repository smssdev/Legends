// vue/components/ar/projects/catalogue.ts
import { createApp } from "vue";

// vue/components/ar/projects/Catalogue.vue
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, toDisplayString as _toDisplayString, normalizeClass as _normalizeClass, unref as _unref, createCommentVNode as _createCommentVNode } from "vue";
import { computed, ref } from "vue";

// vue/components/ar/products.ts
var products = [
  { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25, category: "books", isNew: true, inStock: true },
  { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8, category: "gifts", inStock: true },
  { id: 3, name: "\u0645\u0644\u0635\u0642 \u0628\u0650\u062A", price: 3, category: "gifts", inStock: false },
  { id: 4, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12, category: "gifts", isNew: true, inStock: true }
];

// vue/components/ar/projects/Catalogue.vue
var _hoisted_1 = {
  class: "filters",
  role: "group",
  "aria-label": "\u0627\u0644\u0643\u062A\u0627\u0644\u0648\u062C"
};
var _hoisted_2 = ["aria-pressed", "onClick"];
var _hoisted_3 = { class: "count" };
var _hoisted_4 = { class: "grid" };
var _hoisted_5 = {
  key: 0,
  class: "badge"
};
var _hoisted_6 = { class: "price" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Catalogue",
  setup(__props) {
    const FILTERS = [
      { value: "all", label: "\u0627\u0644\u0643\u0644" },
      { value: "books", label: "\u0643\u062A\u0628" },
      { value: "gifts", label: "\u0647\u062F\u0627\u064A\u0627" }
    ];
    const filter = ref("all");
    const visible = computed(() => filter.value === "all" ? products : products.filter((p) => p.category === filter.value));
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("section", null, [
        _cache[0] || (_cache[0] = _createElementVNode(
          "h2",
          null,
          "\u0627\u0644\u0643\u062A\u0627\u0644\u0648\u062C",
          -1
          /* CACHED */
        )),
        _createElementVNode("div", _hoisted_1, [
          (_openBlock(), _createElementBlock(
            _Fragment,
            null,
            _renderList(FILTERS, (f) => {
              return _createElementVNode("button", {
                key: f.value,
                type: "button",
                class: _normalizeClass({ secondary: f.value !== filter.value }),
                "aria-pressed": f.value === filter.value,
                onClick: ($event) => filter.value = f.value
              }, _toDisplayString(f.label), 11, _hoisted_2);
            }),
            64
            /* STABLE_FRAGMENT */
          ))
        ]),
        _createElementVNode(
          "p",
          _hoisted_3,
          "\u064A\u0638\u0647\u0631 " + _toDisplayString(visible.value.length) + " \u0645\u0646 " + _toDisplayString(_unref(products).length) + " \u0645\u0646\u062A\u062C\u0627\u062A",
          1
          /* TEXT */
        ),
        _createElementVNode("div", _hoisted_4, [
          (_openBlock(true), _createElementBlock(
            _Fragment,
            null,
            _renderList(visible.value, (product) => {
              return _openBlock(), _createElementBlock("article", {
                key: product.id,
                class: "card"
              }, [
                product.isNew ? (_openBlock(), _createElementBlock("span", _hoisted_5, "\u062C\u062F\u064A\u062F")) : _createCommentVNode("v-if", true),
                _createElementVNode(
                  "h3",
                  null,
                  _toDisplayString(product.name),
                  1
                  /* TEXT */
                ),
                _createElementVNode(
                  "p",
                  _hoisted_6,
                  _toDisplayString(product.price.toFixed(2)) + " \u062C\u0646\u064A\u0647\u0627\u064B",
                  1
                  /* TEXT */
                )
              ]);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ])
      ]);
    };
  }
});
var Catalogue_default = _sfc;

// vue/components/ar/projects/catalogue.ts
createApp(Catalogue_default).mount("#app");
