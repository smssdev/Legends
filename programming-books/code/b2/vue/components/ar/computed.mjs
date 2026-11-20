// vue/components/ar/computed.ts
import { createSSRApp, h } from "vue";
import { renderToString } from "vue/server-renderer";

// vue/components/ar/CartTotal.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { computed } from "vue";

// vue/components/ar/counts.ts
var counts = { method: 0, computed: 0 };

// vue/components/ar/CartTotal.vue
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "CartTotal",
  props: {
    prices: {}
  },
  setup(__props) {
    const props = __props;
    function totalMethod() {
      counts.method++;
      return props.prices.reduce((sum, p) => sum + p, 0);
    }
    const total = computed(() => {
      counts.computed++;
      return props.prices.reduce((sum, p) => sum + p, 0);
    });
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _createElementVNode(
            "p",
            null,
            _toDisplayString(totalMethod()) + " = " + _toDisplayString(totalMethod()) + " = " + _toDisplayString(totalMethod()),
            1
            /* TEXT */
          ),
          _createElementVNode(
            "p",
            null,
            _toDisplayString(total.value) + " = " + _toDisplayString(total.value) + " = " + _toDisplayString(total.value),
            1
            /* TEXT */
          )
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var CartTotal_default = _sfc;

// vue/components/ar/computed.ts
console.log(await renderToString(createSSRApp({ render: () => h(CartTotal_default, { prices: [25, 8, 12] }) })));
console.log("\u0645\u0631\u0627\u062A \u0627\u0633\u062A\u062F\u0639\u0627\u0621 \u0627\u0644\u062F\u0627\u0644\u0629:", counts.method);
console.log("\u0645\u0631\u0627\u062A \u062D\u0633\u0627\u0628 \u0627\u0644\u0642\u064A\u0645\u0629 \u0627\u0644\u0645\u062D\u0633\u0648\u0628\u0629:", counts.computed);
