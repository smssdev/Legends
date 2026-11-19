// vue/components/en/first.ts
import { createSSRApp } from "vue";
import { renderToString } from "vue/server-renderer";

// vue/components/en/Greeting.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var name = "Sara";
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Greeting",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("h1", null, "Hello, " + _toDisplayString(name) + "!");
    };
  }
});
var Greeting_default = _sfc;

// vue/components/en/first.ts
console.log(await renderToString(createSSRApp(Greeting_default)));
