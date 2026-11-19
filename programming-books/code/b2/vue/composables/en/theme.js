// vue/composables/en/theme.ts
import { createApp } from "vue";

// vue/composables/en/Theme.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { useLocalStorage } from "@vueuse/core";
import { watchEffect } from "vue";
var _hoisted_1 = ["aria-pressed"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Theme",
  setup(__props) {
    const dark = useLocalStorage("dark", false);
    watchEffect(() => document.documentElement.classList.toggle("dark", dark.value));
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("button", {
        type: "button",
        "aria-pressed": _unref(dark),
        onClick: _cache[0] || (_cache[0] = ($event) => dark.value = !_unref(dark))
      }, "Dark theme", 8, _hoisted_1);
    };
  }
});
var Theme_default = _sfc;

// vue/composables/en/theme.ts
createApp(Theme_default).mount("#app");
