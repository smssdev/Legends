// vue/reactivity/en/timer.ts
import { createApp } from "vue";

// vue/reactivity/en/Timer.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { onWatcherCleanup, ref, watch } from "vue";
var _hoisted_1 = ["aria-pressed"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Timer",
  setup(__props) {
    const running = ref(false);
    const seconds = ref(0);
    watch(running, (on) => {
      if (!on) return;
      const id = setInterval(() => seconds.value++, 1e3);
      onWatcherCleanup(() => clearInterval(id));
    });
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("p", null, [
        _createElementVNode(
          "strong",
          null,
          _toDisplayString(seconds.value),
          1
          /* TEXT */
        ),
        _cache[1] || (_cache[1] = _createTextVNode(
          " seconds ",
          -1
          /* CACHED */
        )),
        _createElementVNode("button", {
          type: "button",
          "aria-pressed": running.value,
          onClick: _cache[0] || (_cache[0] = ($event) => running.value = !running.value)
        }, _toDisplayString(running.value ? "Stop" : "Start"), 9, _hoisted_1)
      ]);
    };
  }
});
var Timer_default = _sfc;

// vue/reactivity/en/timer.ts
createApp(Timer_default).mount("#app");
