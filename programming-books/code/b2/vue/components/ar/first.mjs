// vue/components/ar/first.ts
import { createSSRApp } from "vue";
import { renderToString } from "vue/server-renderer";

// vue/components/ar/Greeting.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var name = "\u0633\u0627\u0631\u0629";
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Greeting",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("h1", null, "\u0623\u0647\u0644\u0627\u064B \u064A\u0627 " + _toDisplayString(name) + "!");
    };
  }
});
var Greeting_default = _sfc;

// vue/components/ar/first.ts
console.log(await renderToString(createSSRApp(Greeting_default)));
