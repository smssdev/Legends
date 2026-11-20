// vue/composables/ar/stopwatch.ts
import { createApp } from "vue";

// vue/composables/ar/Two.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createVNode as _createVNode, Fragment as _Fragment, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// vue/composables/ar/Stopwatch.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, openBlock as _openBlock, createElementBlock as _createElementBlock, createTextVNode as _createTextVNode } from "vue";

// vue/composables/ar/composables/useStopwatch.ts
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

// vue/composables/ar/Stopwatch.vue
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
          " \u062B\u0627\u0646\u064A\u0629 ",
          -1
          /* CACHED */
        )),
        !_unref(running) ? (_openBlock(), _createElementBlock("button", {
          key: 0,
          type: "button",
          onClick: _cache[0] || (_cache[0] = //@ts-ignore
          (...args) => _unref(start) && _unref(start)(...args))
        }, "\u0627\u0628\u062F\u0623")) : (_openBlock(), _createElementBlock("button", {
          key: 1,
          type: "button",
          onClick: _cache[1] || (_cache[1] = //@ts-ignore
          (...args) => _unref(stop) && _unref(stop)(...args))
        }, "\u0623\u0648\u0642\u0641")),
        _createElementVNode("button", {
          type: "button",
          class: "secondary",
          onClick: _cache[2] || (_cache[2] = //@ts-ignore
          (...args) => _unref(reset) && _unref(reset)(...args))
        }, "\u0635\u0641\u0651\u0631")
      ]);
    };
  }
});
var Stopwatch_default = _sfc;

// vue/composables/ar/Two.vue
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

// vue/composables/ar/stopwatch.ts
createApp(Two_default).mount("#app");
