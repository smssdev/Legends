// a11y/ar/vue/projects/menu.ts
import { createApp } from "vue";

// a11y/ar/vue/projects/Menu.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// a11y/ar/vue/projects/MenuButton.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, withModifiers as _withModifiers, withKeys as _withKeys, createElementVNode as _createElementVNode, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, normalizeClass as _normalizeClass, createCommentVNode as _createCommentVNode } from "vue";
import { nextTick, ref, useId, useTemplateRef, watch } from "vue";
var _hoisted_1 = { class: "menu-wrap" };
var _hoisted_2 = ["id", "aria-expanded", "aria-controls"];
var _hoisted_3 = ["id", "aria-labelledby"];
var _hoisted_4 = ["onClick"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "MenuButton",
  props: {
    label: {},
    items: {}
  },
  setup(__props) {
    const props = __props;
    const open = ref(false);
    const active = ref(0);
    const id = useId();
    const button = useTemplateRef("button");
    const itemEls = useTemplateRef("item");
    watch([open, active], async () => {
      await nextTick();
      if (open.value) itemEls.value?.[active.value]?.focus();
    });
    function openAt(index) {
      active.value = index;
      open.value = true;
    }
    function close() {
      open.value = false;
      button.value?.focus();
    }
    function onMenuKey(event) {
      const last = props.items.length - 1;
      if (event.key === "ArrowDown") active.value = active.value === last ? 0 : active.value + 1;
      else if (event.key === "ArrowUp") active.value = active.value === 0 ? last : active.value - 1;
      else if (event.key === "Home") active.value = 0;
      else if (event.key === "End") active.value = last;
      else if (event.key === "Escape" || event.key === "Tab") close();
      else return;
      event.preventDefault();
    }
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("div", _hoisted_1, [
        _createElementVNode("button", {
          id: `${_unref(id)}-button`,
          ref_key: "button",
          ref: button,
          type: "button",
          "aria-haspopup": "menu",
          "aria-expanded": open.value,
          "aria-controls": `${_unref(id)}-menu`,
          onClick: _cache[0] || (_cache[0] = ($event) => open.value ? close() : openAt(0)),
          onKeydown: [
            _cache[1] || (_cache[1] = _withKeys(_withModifiers(($event) => openAt(0), ["prevent"]), ["down"])),
            _cache[2] || (_cache[2] = _withKeys(_withModifiers(($event) => openAt(__props.items.length - 1), ["prevent"]), ["up"]))
          ]
        }, _toDisplayString(__props.label) + " \u25BE ", 41, _hoisted_2),
        open.value ? (_openBlock(), _createElementBlock("ul", {
          key: 0,
          id: `${_unref(id)}-menu`,
          role: "menu",
          "aria-labelledby": `${_unref(id)}-button`,
          onKeydown: onMenuKey
        }, [
          (_openBlock(true), _createElementBlock(
            _Fragment,
            null,
            _renderList(__props.items, (item) => {
              return _openBlock(), _createElementBlock("li", {
                key: item.label,
                role: "none"
              }, [
                _createElementVNode("button", {
                  ref_for: true,
                  ref: "item",
                  type: "button",
                  role: "menuitem",
                  tabindex: "-1",
                  class: _normalizeClass({ "danger-text": item.danger }),
                  onClick: ($event) => (item.onSelect(), close())
                }, _toDisplayString(item.label), 11, _hoisted_4)
              ]);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ], 40, _hoisted_3)) : _createCommentVNode("v-if", true)
      ]);
    };
  }
});
var MenuButton_default = _sfc;

// a11y/ar/vue/projects/Menu.vue
var _hoisted_12 = { class: "card" };
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Menu",
  setup(__props) {
    const noop = () => {
    };
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("div", _hoisted_12, [
        _createVNode(MenuButton_default, {
          label: "\u0625\u062C\u0631\u0627\u0621\u0627\u062A \u0627\u0644\u0637\u0644\u0628 #1042",
          items: [
            { label: "\u062A\u062A\u0628\u0651\u0639", onSelect: noop },
            { label: "\u0646\u0632\u0651\u0644 \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629", onSelect: noop },
            { label: "\u0623\u0631\u062C\u0639 \u0645\u0646\u062A\u062C\u0627\u062A", onSelect: noop },
            { label: "\u0623\u0644\u063A\u0650 \u0627\u0644\u0637\u0644\u0628", danger: true, onSelect: noop }
          ]
        }, null, 8, ["items"])
      ]);
    };
  }
});
var Menu_default = _sfc2;

// a11y/ar/vue/projects/menu.ts
createApp(Menu_default).mount("#app");
