// vue/components/en/projects/tabs.ts
import { createApp } from "vue";

// vue/components/en/projects/Details.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode2, withCtx as _withCtx, openBlock as _openBlock2, createBlock as _createBlock } from "vue";

// vue/components/en/projects/TabList.vue
import { defineComponent as _defineComponent } from "vue";
import { renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, unref as _unref, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, renderSlot as _renderSlot } from "vue";
import { ref, useId, useTemplateRef } from "vue";
var _hoisted_1 = { class: "tabs" };
var _hoisted_2 = ["aria-label"];
var _hoisted_3 = ["id", "aria-selected", "aria-controls", "tabindex", "onClick"];
var _hoisted_4 = ["id", "aria-labelledby", "hidden"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "TabList",
  props: {
    labels: {},
    label: {}
  },
  setup(__props) {
    const props = __props;
    const active = ref(0);
    const id = useId();
    const buttons = useTemplateRef("tab");
    function select(index) {
      const next = (index + props.labels.length) % props.labels.length;
      active.value = next;
      buttons.value?.[next]?.focus();
    }
    function onKeydown(event) {
      const rtl = document.dir === "rtl";
      if (event.key === "ArrowRight") select(active.value + (rtl ? -1 : 1));
      if (event.key === "ArrowLeft") select(active.value + (rtl ? 1 : -1));
      if (event.key === "Home") select(0);
      if (event.key === "End") select(props.labels.length - 1);
    }
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("div", _hoisted_1, [
        _createElementVNode("div", {
          role: "tablist",
          "aria-label": __props.label,
          onKeydown
        }, [
          (_openBlock(true), _createElementBlock(
            _Fragment,
            null,
            _renderList(__props.labels, (text, i) => {
              return _openBlock(), _createElementBlock("button", {
                id: `${_unref(id)}-tab-${i}`,
                ref_for: true,
                ref: "tab",
                key: text,
                type: "button",
                role: "tab",
                "aria-selected": i === active.value,
                "aria-controls": `${_unref(id)}-panel-${i}`,
                tabindex: i === active.value ? 0 : -1,
                onClick: ($event) => select(i)
              }, _toDisplayString(text), 9, _hoisted_3);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ], 40, _hoisted_2),
        (_openBlock(true), _createElementBlock(
          _Fragment,
          null,
          _renderList(__props.labels, (text, i) => {
            return _openBlock(), _createElementBlock("div", {
              id: `${_unref(id)}-panel-${i}`,
              key: text,
              role: "tabpanel",
              "aria-labelledby": `${_unref(id)}-tab-${i}`,
              hidden: i !== active.value
            }, [
              _renderSlot(_ctx.$slots, `tab-${i}`)
            ], 8, _hoisted_4);
          }),
          128
          /* KEYED_FRAGMENT */
        ))
      ]);
    };
  }
});
var TabList_default = _sfc;

// vue/components/en/projects/Details.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Details",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createBlock(TabList_default, {
        label: "Product details",
        labels: ["Description", "Reviews", "Shipping"]
      }, {
        "tab-0": _withCtx(() => [..._cache[0] || (_cache[0] = [
          _createElementVNode2(
            "p",
            null,
            "A friendly guide that takes you from your first line of code to your first app.",
            -1
            /* CACHED */
          )
        ])]),
        "tab-1": _withCtx(() => [..._cache[1] || (_cache[1] = [
          _createElementVNode2(
            "p",
            null,
            "\u201CClear, kind and practical. My son finished it in a month.\u201D \u2605\u2605\u2605\u2605\u2605",
            -1
            /* CACHED */
          )
        ])]),
        "tab-2": _withCtx(() => [..._cache[2] || (_cache[2] = [
          _createElementVNode2(
            "p",
            null,
            "Free delivery in Egypt for orders over 50 EGP. Arrives in 2\u20134 days.",
            -1
            /* CACHED */
          )
        ])]),
        _: 1
        /* STABLE */
      });
    };
  }
});
var Details_default = _sfc2;

// vue/components/en/projects/tabs.ts
createApp(Details_default).mount("#app");
