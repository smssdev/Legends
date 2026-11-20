// vue/composables/ar/status.ts
import { createApp } from "vue";

// vue/composables/ar/Status.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, normalizeClass as _normalizeClass, createElementVNode as _createElementVNode, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { ref as ref2 } from "vue";

// vue/composables/ar/composables/useEventListener.ts
import { onScopeDispose } from "vue";
function useEventListener(target, event, handler) {
  target.addEventListener(event, handler);
  onScopeDispose(() => target.removeEventListener(event, handler));
}

// vue/composables/ar/composables/useOnline.ts
import { ref } from "vue";
function useOnline() {
  const online = ref(navigator.onLine);
  useEventListener(window, "online", () => online.value = true);
  useEventListener(window, "offline", () => online.value = false);
  return online;
}

// vue/composables/ar/Status.vue
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Status",
  setup(__props) {
    const online = useOnline();
    const width = ref2(window.innerWidth);
    useEventListener(window, "resize", () => width.value = window.innerWidth);
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _createElementVNode(
            "p",
            {
              class: _normalizeClass(_unref(online) ? "ok" : "warn"),
              role: "status"
            },
            _toDisplayString(_unref(online) ? "\u0645\u062A\u0635\u0644" : "\u063A\u064A\u0631 \u0645\u062A\u0635\u0644: \u0633\u062A\u064F\u062D\u0641\u0638 \u0627\u0644\u062A\u063A\u064A\u064A\u0631\u0627\u062A \u062D\u064A\u0646 \u062A\u0639\u0648\u062F"),
            3
            /* TEXT, CLASS */
          ),
          _createElementVNode(
            "p",
            null,
            "\u0639\u0631\u0636 \u0627\u0644\u0646\u0627\u0641\u0630\u0629: " + _toDisplayString(width.value) + "px",
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
var Status_default = _sfc;

// vue/composables/ar/status.ts
createApp(Status_default).mount("#app");
window.dispatchEvent(new Event("offline"));
