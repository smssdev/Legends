// vue/components/en/projects/catalogue.ts
import { createApp } from "vue";

// vue/components/en/projects/Catalogue.vue
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, toDisplayString as _toDisplayString, normalizeClass as _normalizeClass, unref as _unref, createCommentVNode as _createCommentVNode } from "vue";
import { computed, ref } from "vue";

// vue/components/en/products.ts
var products = [
  { id: 1, name: "Code from Zero", price: 25, category: "books", isNew: true, inStock: true },
  { id: 2, name: "Bit mug", price: 8, category: "gifts", inStock: true },
  { id: 3, name: "Bit sticker", price: 3, category: "gifts", inStock: false },
  { id: 4, name: "Bit cap", price: 12, category: "gifts", isNew: true, inStock: true }
];

// vue/components/en/projects/Catalogue.vue
var _hoisted_1 = {
  class: "filters",
  role: "group",
  "aria-label": "Catalogue"
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
      { value: "all", label: "All" },
      { value: "books", label: "Books" },
      { value: "gifts", label: "Gifts" }
    ];
    const filter = ref("all");
    const visible = computed(() => filter.value === "all" ? products : products.filter((p) => p.category === filter.value));
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("section", null, [
        _cache[0] || (_cache[0] = _createElementVNode(
          "h2",
          null,
          "Catalogue",
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
          "Showing " + _toDisplayString(visible.value.length) + " of " + _toDisplayString(_unref(products).length) + " products",
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
                product.isNew ? (_openBlock(), _createElementBlock("span", _hoisted_5, "New")) : _createCommentVNode("v-if", true),
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
                  _toDisplayString(product.price.toFixed(2)) + " EGP",
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

// vue/components/en/projects/catalogue.ts
createApp(Catalogue_default).mount("#app");
