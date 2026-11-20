// vue/components/ar/template.ts
import { createSSRApp, h } from "vue";
import { renderToString } from "vue/server-renderer";

// vue/components/ar/CartSummary.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, normalizeClass as _normalizeClass, createElementVNode as _createElementVNode, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "CartSummary",
  props: {
    count: {},
    total: {}
  },
  setup(__props) {
    const props = __props;
    const isEmpty = props.count === 0;
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _createElementVNode(
            "p",
            {
              class: _normalizeClass(["summary", { empty: isEmpty }])
            },
            _toDisplayString(__props.count) + " \u0639\u0646\u0627\u0635\u0631 \u0641\u064A \u0633\u0644\u062A\u0643: " + _toDisplayString(__props.total.toFixed(2)) + " \u062C\u0646\u064A\u0647\u0627\u064B ",
            3
            /* TEXT, CLASS */
          ),
          _createElementVNode("button", {
            type: "button",
            disabled: isEmpty,
            style: { fontWeight: 700 }
          }, "\u0623\u0636\u0641 \u0625\u0644\u0649 \u0627\u0644\u0633\u0644\u0629")
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var CartSummary_default = _sfc;

// vue/components/ar/template.ts
console.log(await renderToString(createSSRApp({ render: () => h(CartSummary_default, { count: 3, total: 41 }) })));
console.log(await renderToString(createSSRApp({ render: () => h(CartSummary_default, { count: 0, total: 0 }) })));
