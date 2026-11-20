// vue/composables/en/status.ts
import { createApp } from "vue";

// vue/composables/en/Status.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, normalizeClass as _normalizeClass, createElementVNode as _createElementVNode, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { ref as ref2 } from "vue";

// vue/composables/en/composables/useEventListener.ts
import { onScopeDispose } from "vue";
function useEventListener(target, event, handler) {
  target.addEventListener(event, handler);
  onScopeDispose(() => target.removeEventListener(event, handler));
}

// vue/composables/en/composables/useOnline.ts
import { ref } from "vue";
function useOnline() {
  const online = ref(navigator.onLine);
  useEventListener(window, "online", () => online.value = true);
  useEventListener(window, "offline", () => online.value = false);
  return online;
}

// vue/composables/en/Status.vue
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
            _toDisplayString(_unref(online) ? "Online" : "Offline: changes will be saved when you are back"),
            3
            /* TEXT, CLASS */
          ),
          _createElementVNode(
            "p",
            null,
            "Window width: " + _toDisplayString(width.value) + "px",
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

// vue/composables/en/status.ts
createApp(Status_default).mount("#app");
window.dispatchEvent(new Event("offline"));
