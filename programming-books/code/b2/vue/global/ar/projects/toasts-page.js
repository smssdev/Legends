// vue/global/ar/projects/toasts-page.ts
import { createApp } from "vue";
import { createPinia } from "pinia";

// vue/global/ar/projects/Shelf.vue
import { defineComponent as _defineComponent2 } from "vue";
import { renderList as _renderList2, Fragment as _Fragment2, openBlock as _openBlock2, createElementBlock as _createElementBlock2, toDisplayString as _toDisplayString2, createElementVNode as _createElementVNode2, unref as _unref2, createVNode as _createVNode } from "vue";
import { ref as ref2 } from "vue";

// vue/global/ar/projects/ToastList.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createCommentVNode as _createCommentVNode, Teleport as _Teleport, createBlock as _createBlock } from "vue";

// vue/global/ar/projects/toasts.ts
import { defineStore } from "pinia";
import { ref } from "vue";
var useToasts = defineStore("toasts", () => {
  const toasts = ref([]);
  let next = 1;
  function dismiss(id) {
    toasts.value = toasts.value.filter((t) => t.id !== id);
  }
  function notify(text, action) {
    const id = next++;
    toasts.value = [...toasts.value.slice(-2), { id, text, action }];
    setTimeout(() => dismiss(id), 5e3);
  }
  return { toasts, notify, dismiss };
});

// vue/global/ar/projects/ToastList.vue
var _hoisted_1 = {
  class: "toasts",
  role: "status",
  "aria-live": "polite",
  "aria-label": "\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A"
};
var _hoisted_2 = ["onClick"];
var _hoisted_3 = ["onClick"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "ToastList",
  setup(__props) {
    const store = useToasts();
    return (_ctx, _cache) => {
      return _openBlock(), _createBlock(_Teleport, { to: "body" }, [
        _createElementVNode("ul", _hoisted_1, [
          (_openBlock(true), _createElementBlock(
            _Fragment,
            null,
            _renderList(_unref(store).toasts, (t) => {
              return _openBlock(), _createElementBlock("li", {
                key: t.id,
                class: "toast"
              }, [
                _createElementVNode(
                  "span",
                  null,
                  _toDisplayString(t.text),
                  1
                  /* TEXT */
                ),
                t.action ? (_openBlock(), _createElementBlock("button", {
                  key: 0,
                  type: "button",
                  class: "secondary",
                  onClick: ($event) => (t.action.run(), _unref(store).dismiss(t.id))
                }, _toDisplayString(t.action.label), 9, _hoisted_2)) : _createCommentVNode("v-if", true),
                _createElementVNode("button", {
                  type: "button",
                  "aria-label": "\u0623\u063A\u0644\u0642",
                  onClick: ($event) => _unref(store).dismiss(t.id)
                }, "\xD7", 8, _hoisted_3)
              ]);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ])
      ]);
    };
  }
});
var ToastList_default = _sfc;

// vue/global/ar/projects/Shelf.vue
var _hoisted_12 = { class: "card" };
var _hoisted_22 = { class: "row" };
var _hoisted_32 = ["onClick"];
var _hoisted_4 = ["aria-label", "onClick"];
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Shelf",
  setup(__props) {
    const { notify } = useToasts();
    const items = ref2(["\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", "\u0643\u0648\u0628 \u0628\u0650\u062A", "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A"]);
    function remove(name) {
      items.value = items.value.filter((n) => n !== name);
      notify(`\u062D\u064F\u0630\u0641: ${name}`, { label: "\u062A\u0631\u0627\u062C\u0639", run: () => items.value.push(name) });
    }
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2(
        _Fragment2,
        null,
        [
          _createElementVNode2("section", _hoisted_12, [
            (_openBlock2(true), _createElementBlock2(
              _Fragment2,
              null,
              _renderList2(items.value, (name) => {
                return _openBlock2(), _createElementBlock2("div", {
                  key: name,
                  class: "row spread"
                }, [
                  _createElementVNode2(
                    "span",
                    null,
                    _toDisplayString2(name),
                    1
                    /* TEXT */
                  ),
                  _createElementVNode2("span", _hoisted_22, [
                    _createElementVNode2("button", {
                      type: "button",
                      onClick: ($event) => _unref2(notify)(`${name} \u0623\u064F\u0636\u064A\u0641 \u0625\u0644\u0649 \u0627\u0644\u0633\u0644\u0629`)
                    }, "\u0623\u0636\u0641", 8, _hoisted_32),
                    _createElementVNode2("button", {
                      type: "button",
                      class: "secondary",
                      "aria-label": `\u062D\u064F\u0630\u0641: ${name}`,
                      onClick: ($event) => remove(name)
                    }, "\xD7", 8, _hoisted_4)
                  ])
                ]);
              }),
              128
              /* KEYED_FRAGMENT */
            ))
          ]),
          _createVNode(ToastList_default)
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var Shelf_default = _sfc2;

// vue/global/ar/projects/toasts-page.ts
createApp(Shelf_default).use(createPinia()).mount("#app");
