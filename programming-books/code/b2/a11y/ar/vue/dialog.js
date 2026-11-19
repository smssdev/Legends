// a11y/ar/vue/dialog.ts
import { createApp } from "vue";

// a11y/ar/vue/Settings.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode2, createTextVNode as _createTextVNode, withCtx as _withCtx, createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";
import { ref } from "vue";

// a11y/ar/vue/ConfirmDialog.vue
import { useModel as _useModel, mergeModels as _mergeModels, defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, renderSlot as _renderSlot, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { useTemplateRef, watchEffect } from "vue";
var _hoisted_1 = { id: "dlg-title" };
var _hoisted_2 = { id: "dlg-text" };
var _hoisted_3 = { class: "row" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "ConfirmDialog",
  props: /* @__PURE__ */ _mergeModels({
    title: {},
    confirmLabel: {},
    cancelLabel: {}
  }, {
    "modelValue": { type: Boolean, ...{ required: true } },
    "modelModifiers": {}
  }),
  emits: /* @__PURE__ */ _mergeModels(["confirm"], ["update:modelValue"]),
  setup(__props, { emit: __emit }) {
    const open = _useModel(__props, "modelValue");
    const emit = __emit;
    const dialog = useTemplateRef("dialog");
    watchEffect(() => {
      const el = dialog.value;
      if (!el) return;
      if (open.value && !el.open) el.showModal();
      if (!open.value && el.open) el.close();
    });
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        "dialog",
        {
          ref_key: "dialog",
          ref: dialog,
          "aria-labelledby": "dlg-title",
          "aria-describedby": "dlg-text",
          onClose: _cache[2] || (_cache[2] = ($event) => open.value = false)
        },
        [
          _createElementVNode(
            "h2",
            _hoisted_1,
            _toDisplayString(__props.title),
            1
            /* TEXT */
          ),
          _createElementVNode("p", _hoisted_2, [
            _renderSlot(_ctx.$slots, "default")
          ]),
          _createElementVNode("div", _hoisted_3, [
            _createElementVNode(
              "button",
              {
                type: "button",
                class: "secondary",
                autofocus: "",
                onClick: _cache[0] || (_cache[0] = ($event) => open.value = false)
              },
              _toDisplayString(__props.cancelLabel),
              1
              /* TEXT */
            ),
            _createElementVNode(
              "button",
              {
                type: "button",
                class: "danger",
                onClick: _cache[1] || (_cache[1] = ($event) => (emit("confirm"), open.value = false))
              },
              _toDisplayString(__props.confirmLabel),
              1
              /* TEXT */
            )
          ])
        ],
        544
        /* NEED_HYDRATION, NEED_PATCH */
      );
    };
  }
});
var ConfirmDialog_default = _sfc;

// a11y/ar/vue/Settings.vue
var _hoisted_12 = { class: "card" };
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Settings",
  setup(__props) {
    const open = ref(false);
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("div", _hoisted_12, [
        _createElementVNode2("button", {
          type: "button",
          class: "danger",
          onClick: _cache[0] || (_cache[0] = ($event) => open.value = true)
        }, "\u0627\u062D\u0630\u0641 \u0627\u0644\u062D\u0633\u0627\u0628\u2026"),
        _createVNode(ConfirmDialog_default, {
          modelValue: open.value,
          "onUpdate:modelValue": _cache[1] || (_cache[1] = ($event) => open.value = $event),
          title: "\u0623\u062A\u062D\u0630\u0641 \u062D\u0633\u0627\u0628\u0643\u061F",
          "confirm-label": "\u0627\u062D\u0630\u0641",
          "cancel-label": "\u0623\u0644\u063A\u0650"
        }, {
          default: _withCtx(() => [..._cache[2] || (_cache[2] = [
            _createTextVNode(
              " \u0633\u062A\u064F\u062D\u0630\u0641 \u0643\u0644 \u0637\u0644\u0628\u0627\u062A\u0643 \u0648\u0642\u0648\u0627\u0626\u0645\u0643 \u0627\u0644\u0645\u062D\u0641\u0648\u0638\u0629\u060C \u0648\u0644\u0627 \u064A\u0645\u0643\u0646 \u0627\u0644\u062A\u0631\u0627\u062C\u0639 \u0639\u0646 \u0630\u0644\u0643. ",
              -1
              /* CACHED */
            )
          ])]),
          _: 1
          /* STABLE */
        }, 8, ["modelValue"])
      ]);
    };
  }
});
var Settings_default = _sfc2;

// a11y/ar/vue/dialog.ts
createApp(Settings_default).mount("#app");
