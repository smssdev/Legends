// vue/composables/en/stopwatch.ts
import { createApp } from "vue";

// vue/composables/en/Two.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createVNode as _createVNode, Fragment as _Fragment, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// vue/composables/en/Stopwatch.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, openBlock as _openBlock, createElementBlock as _createElementBlock, createTextVNode as _createTextVNode } from "vue";

// vue/composables/en/composables/useStopwatch.ts
import { onScopeDispose, readonly, ref } from "vue";
function useStopwatch() {
  const seconds = ref(0);
  const running = ref(false);
  let timer;
  function start() {
    if (running.value) return;
    running.value = true;
    timer = setInterval(() => seconds.value++, 1e3);
  }
  function stop() {
    clearInterval(timer);
    running.value = false;
  }
  function reset() {
    stop();
    seconds.value = 0;
  }
  onScopeDispose(stop);
  return { seconds: readonly(seconds), running: readonly(running), start, stop, reset };
}

// vue/composables/en/Stopwatch.vue
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Stopwatch",
  setup(__props) {
    const { seconds, running, start, stop, reset } = useStopwatch();
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("p", null, [
        _createElementVNode(
          "strong",
          null,
          _toDisplayString(_unref(seconds)),
          1
          /* TEXT */
        ),
        _cache[3] || (_cache[3] = _createTextVNode(
          " seconds ",
          -1
          /* CACHED */
        )),
        !_unref(running) ? (_openBlock(), _createElementBlock("button", {
          key: 0,
          type: "button",
          onClick: _cache[0] || (_cache[0] = //@ts-ignore
          (...args) => _unref(start) && _unref(start)(...args))
        }, "Start")) : (_openBlock(), _createElementBlock("button", {
          key: 1,
          type: "button",
          onClick: _cache[1] || (_cache[1] = //@ts-ignore
          (...args) => _unref(stop) && _unref(stop)(...args))
        }, "Stop")),
        _createElementVNode("button", {
          type: "button",
          class: "secondary",
          onClick: _cache[2] || (_cache[2] = //@ts-ignore
          (...args) => _unref(reset) && _unref(reset)(...args))
        }, "Reset")
      ]);
    };
  }
});
var Stopwatch_default = _sfc;

// vue/composables/en/Two.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Two",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2(
        _Fragment,
        null,
        [
          _createVNode(Stopwatch_default),
          _createVNode(Stopwatch_default)
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var Two_default = _sfc2;

// vue/composables/en/stopwatch.ts
createApp(Two_default).mount("#app");
