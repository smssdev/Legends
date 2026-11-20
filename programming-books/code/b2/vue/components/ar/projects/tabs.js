// vue/components/ar/projects/tabs.ts
import { createApp } from "vue";

// vue/components/ar/projects/Details.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode2, withCtx as _withCtx, openBlock as _openBlock2, createBlock as _createBlock } from "vue";

// vue/components/ar/projects/TabList.vue
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

// vue/components/ar/projects/Details.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Details",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createBlock(TabList_default, {
        label: "\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0645\u0646\u062A\u062C",
        labels: ["\u0627\u0644\u0648\u0635\u0641", "\u0627\u0644\u0645\u0631\u0627\u062C\u0639\u0627\u062A", "\u0627\u0644\u0634\u062D\u0646"]
      }, {
        "tab-0": _withCtx(() => [..._cache[0] || (_cache[0] = [
          _createElementVNode2(
            "p",
            null,
            "\u062F\u0644\u064A\u0644 \u0648\u062F\u0648\u062F \u064A\u0623\u062E\u0630\u0643 \u0645\u0646 \u0623\u0648\u0644 \u0633\u0637\u0631 \u0643\u0648\u062F \u0625\u0644\u0649 \u0623\u0648\u0644 \u062A\u0637\u0628\u064A\u0642 \u0644\u0643.",
            -1
            /* CACHED */
          )
        ])]),
        "tab-1": _withCtx(() => [..._cache[1] || (_cache[1] = [
          _createElementVNode2(
            "p",
            null,
            "\xAB\u0648\u0627\u0636\u062D \u0648\u0644\u0637\u064A\u0641 \u0648\u0639\u0645\u0644\u064A. \u0623\u0646\u0647\u0627\u0647 \u0627\u0628\u0646\u064A \u0641\u064A \u0634\u0647\u0631.\xBB \u2605\u2605\u2605\u2605\u2605",
            -1
            /* CACHED */
          )
        ])]),
        "tab-2": _withCtx(() => [..._cache[2] || (_cache[2] = [
          _createElementVNode2(
            "p",
            null,
            "\u062A\u0648\u0635\u064A\u0644 \u0645\u062C\u0627\u0646\u064A \u062F\u0627\u062E\u0644 \u0645\u0635\u0631 \u0644\u0644\u0637\u0644\u0628\u0627\u062A \u0641\u0648\u0642 50 \u062C\u0646\u064A\u0647\u0627\u064B. \u064A\u0635\u0644 \u062E\u0644\u0627\u0644 2 \u0625\u0644\u0649 4 \u0623\u064A\u0627\u0645.",
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

// vue/components/ar/projects/tabs.ts
createApp(Details_default).mount("#app");
