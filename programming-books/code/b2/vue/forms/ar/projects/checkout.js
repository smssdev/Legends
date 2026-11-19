// vue/forms/ar/projects/checkout.ts
import { createApp } from "vue";

// vue/forms/ar/projects/CheckoutForm.vue
import { defineComponent as _defineComponent2 } from "vue";
import { openBlock as _openBlock2, createElementBlock as _createElementBlock2, unref as _unref, renderList as _renderList, Fragment as _Fragment, toDisplayString as _toDisplayString2, createElementVNode as _createElementVNode2, vModelSelect as _vModelSelect, mergeProps as _mergeProps, withDirectives as _withDirectives, withCtx as _withCtx, createVNode as _createVNode, vModelDynamic as _vModelDynamic, vModelText as _vModelText, vModelRadio as _vModelRadio, createTextVNode as _createTextVNode, withModifiers as _withModifiers } from "vue";
import { ref as ref2 } from "vue";

// vue/forms/ar/FormField.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createCommentVNode as _createCommentVNode, renderSlot as _renderSlot, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var _hoisted_1 = { class: "field" };
var _hoisted_2 = ["for"];
var _hoisted_3 = ["id"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "FormField",
  props: {
    id: {},
    label: {},
    error: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("div", _hoisted_1, [
        _createElementVNode("label", { for: __props.id }, _toDisplayString(__props.label), 9, _hoisted_2),
        _createCommentVNode(" \u062A\u0633\u062A\u0644\u0645 \u0627\u0644\u0641\u062A\u062D\u0629 \u0627\u0644\u0633\u0645\u0627\u062A \u0627\u0644\u062A\u064A \u062A\u0631\u0628\u0637 \u0627\u0644\u062D\u0642\u0644 \u0628\u0639\u0646\u0648\u0627\u0646\u0647 \u0648\u062E\u0637\u0626\u0647 "),
        _renderSlot(_ctx.$slots, "default", {
          id: __props.id,
          ariaInvalid: !!__props.error,
          ariaDescribedby: __props.error ? `${__props.id}-error` : void 0
        }),
        __props.error ? (_openBlock(), _createElementBlock("p", {
          key: 0,
          id: `${__props.id}-error`,
          class: "error"
        }, _toDisplayString(__props.error), 9, _hoisted_3)) : _createCommentVNode("v-if", true)
      ]);
    };
  }
});
var FormField_default = _sfc;

// vue/forms/ar/useForm.ts
import { computed, nextTick, reactive, ref, watch } from "vue";
function useForm(schema, initial) {
  const values = reactive({ ...initial });
  const allErrors = ref({});
  const touched = reactive(/* @__PURE__ */ new Set());
  const submitted = ref(false);
  const submitting = ref(false);
  function check() {
    const result = schema.safeParse(values);
    const next = {};
    for (const issue of result.success ? [] : result.error.issues) next[issue.path[0]] ??= issue.message;
    allErrors.value = next;
    return result.success ? result.data : void 0;
  }
  watch(values, check, { deep: true });
  const errors = computed(() => {
    const shown = {};
    for (const [key, message] of Object.entries(allErrors.value)) {
      if (submitted.value || touched.has(key)) shown[key] = message;
    }
    return shown;
  });
  async function focusFirstError() {
    await nextTick();
    document.querySelector("[aria-invalid='true']")?.focus();
  }
  function checkFields(fields) {
    fields.forEach((f) => touched.add(f));
    check();
    const ok = fields.every((f) => !allErrors.value[f]);
    if (!ok) void focusFirstError();
    return ok;
  }
  function handleSubmit(send) {
    return async () => {
      submitted.value = true;
      const data = check();
      if (!data) return focusFirstError();
      submitting.value = true;
      try {
        const fromServer = await send(data);
        if (fromServer) {
          allErrors.value = fromServer;
          void focusFirstError();
        }
      } finally {
        submitting.value = false;
      }
    };
  }
  return { values, errors, submitting, checkFields, handleSubmit, blur: (field) => touched.add(field) };
}

// vue/forms/ar/projects/checkout-schema.ts
import * as z from "zod";
var checkoutSchema = z.object({
  city: z.enum(["cairo", "alexandria", "giza"], "\u0627\u062E\u062A\u0631 \u0645\u062F\u064A\u0646\u0629."),
  street: z.string().trim().min(5, "\u0627\u0643\u062A\u0628 \u0627\u0644\u0634\u0627\u0631\u0639 \u0648\u0631\u0642\u0645 \u0627\u0644\u0645\u0628\u0646\u0649."),
  phone: z.string().regex(/^01[0125]\d{8}$/, "\u0627\u0643\u062A\u0628 \u0631\u0642\u0645 \u062C\u0648\u0627\u0644 \u0645\u0635\u0631\u064A\u0627\u064B \u0645\u0646 11 \u0631\u0642\u0645\u0627\u064B."),
  method: z.enum(["card", "cash"])
});
var STEPS = [
  { title: "\u0627\u0644\u062A\u0648\u0635\u064A\u0644", fields: ["city", "street", "phone"] },
  { title: "\u0627\u0644\u062F\u0641\u0639", fields: ["method"] },
  { title: "\u0627\u0644\u0645\u0631\u0627\u062C\u0639\u0629", fields: [] }
];

// vue/forms/ar/projects/CheckoutForm.vue
var _hoisted_12 = {
  key: 0,
  class: "card done",
  role: "status"
};
var _hoisted_22 = { class: "steps" };
var _hoisted_32 = ["aria-current"];
var _hoisted_4 = ["value"];
var _hoisted_5 = {
  key: 1,
  class: "field"
};
var _hoisted_6 = { class: "check" };
var _hoisted_7 = { class: "check" };
var _hoisted_8 = { key: 2 };
var _hoisted_9 = { dir: "ltr" };
var _hoisted_10 = { class: "row" };
var _hoisted_11 = ["disabled"];
var _hoisted_122 = {
  key: "place",
  type: "submit"
};
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "CheckoutForm",
  setup(__props) {
    const { values, errors, blur, checkFields, handleSubmit } = useForm(checkoutSchema, {
      city: "",
      street: "",
      phone: "",
      method: "cash"
    });
    const step = ref2(0);
    const placed = ref2(false);
    const cities = { cairo: "\u0627\u0644\u0642\u0627\u0647\u0631\u0629", alexandria: "\u0627\u0644\u0625\u0633\u0643\u0646\u062F\u0631\u064A\u0629", giza: "\u0627\u0644\u062C\u064A\u0632\u0629" };
    function next() {
      if (checkFields(STEPS[step.value].fields)) step.value++;
    }
    const place = handleSubmit(async () => {
      placed.value = true;
    });
    return (_ctx, _cache) => {
      return placed.value ? (_openBlock2(), _createElementBlock2("p", _hoisted_12, "\u062A\u0645 \u0627\u0644\u0637\u0644\u0628!")) : (_openBlock2(), _createElementBlock2(
        "form",
        {
          key: 1,
          novalidate: "",
          onSubmit: _cache[9] || (_cache[9] = _withModifiers(
            //@ts-ignore
            (...args) => _unref(place) && _unref(place)(...args),
            ["prevent"]
          ))
        },
        [
          _createElementVNode2("ol", _hoisted_22, [
            (_openBlock2(true), _createElementBlock2(
              _Fragment,
              null,
              _renderList(_unref(STEPS), (s, i) => {
                return _openBlock2(), _createElementBlock2("li", {
                  key: s.title,
                  "aria-current": i === step.value ? "step" : void 0
                }, _toDisplayString2(s.title), 9, _hoisted_32);
              }),
              128
              /* KEYED_FRAGMENT */
            ))
          ]),
          step.value === 0 ? (_openBlock2(), _createElementBlock2(
            _Fragment,
            { key: 0 },
            [
              _createVNode(FormField_default, {
                id: "city",
                label: "\u0627\u0644\u0645\u062F\u064A\u0646\u0629",
                error: _unref(errors).city
              }, {
                default: _withCtx((attrs) => [
                  _withDirectives(_createElementVNode2(
                    "select",
                    _mergeProps(attrs, {
                      "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => _unref(values).city = $event),
                      onBlur: _cache[1] || (_cache[1] = ($event) => _unref(blur)("city"))
                    }),
                    [
                      _cache[10] || (_cache[10] = _createElementVNode2(
                        "option",
                        {
                          value: "",
                          disabled: ""
                        },
                        "\u0627\u062E\u062A\u0631\u2026",
                        -1
                        /* CACHED */
                      )),
                      (_openBlock2(), _createElementBlock2(
                        _Fragment,
                        null,
                        _renderList(cities, (name, value) => {
                          return _createElementVNode2("option", {
                            key: value,
                            value
                          }, _toDisplayString2(name), 9, _hoisted_4);
                        }),
                        64
                        /* STABLE_FRAGMENT */
                      ))
                    ],
                    16
                    /* FULL_PROPS */
                  ), [
                    [_vModelSelect, _unref(values).city]
                  ])
                ]),
                _: 1
                /* STABLE */
              }, 8, ["error"]),
              _createVNode(FormField_default, {
                id: "street",
                label: "\u0627\u0644\u0634\u0627\u0631\u0639 \u0648\u0631\u0642\u0645 \u0627\u0644\u0645\u0628\u0646\u0649",
                error: _unref(errors).street
              }, {
                default: _withCtx((attrs) => [
                  _withDirectives(_createElementVNode2(
                    "input",
                    _mergeProps(attrs, {
                      "onUpdate:modelValue": _cache[2] || (_cache[2] = ($event) => _unref(values).street = $event),
                      autocomplete: "street-address",
                      onBlur: _cache[3] || (_cache[3] = ($event) => _unref(blur)("street"))
                    }),
                    null,
                    16
                    /* FULL_PROPS */
                  ), [
                    [_vModelDynamic, _unref(values).street]
                  ])
                ]),
                _: 1
                /* STABLE */
              }, 8, ["error"]),
              _createVNode(FormField_default, {
                id: "phone",
                label: "\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644",
                error: _unref(errors).phone
              }, {
                default: _withCtx((attrs) => [
                  _withDirectives(_createElementVNode2(
                    "input",
                    _mergeProps(attrs, {
                      "onUpdate:modelValue": _cache[4] || (_cache[4] = ($event) => _unref(values).phone = $event),
                      type: "tel",
                      autocomplete: "tel",
                      dir: "ltr",
                      onBlur: _cache[5] || (_cache[5] = ($event) => _unref(blur)("phone"))
                    }),
                    null,
                    16
                    /* FULL_PROPS */
                  ), [
                    [_vModelText, _unref(values).phone]
                  ])
                ]),
                _: 1
                /* STABLE */
              }, 8, ["error"])
            ],
            64
            /* STABLE_FRAGMENT */
          )) : step.value === 1 ? (_openBlock2(), _createElementBlock2("fieldset", _hoisted_5, [
            _cache[13] || (_cache[13] = _createElementVNode2(
              "legend",
              null,
              "\u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639",
              -1
              /* CACHED */
            )),
            _createElementVNode2("label", _hoisted_6, [
              _withDirectives(_createElementVNode2(
                "input",
                {
                  "onUpdate:modelValue": _cache[6] || (_cache[6] = ($event) => _unref(values).method = $event),
                  type: "radio",
                  value: "card"
                },
                null,
                512
                /* NEED_PATCH */
              ), [
                [_vModelRadio, _unref(values).method]
              ]),
              _cache[11] || (_cache[11] = _createTextVNode(
                " \u0628\u0637\u0627\u0642\u0629",
                -1
                /* CACHED */
              ))
            ]),
            _createElementVNode2("label", _hoisted_7, [
              _withDirectives(_createElementVNode2(
                "input",
                {
                  "onUpdate:modelValue": _cache[7] || (_cache[7] = ($event) => _unref(values).method = $event),
                  type: "radio",
                  value: "cash"
                },
                null,
                512
                /* NEED_PATCH */
              ), [
                [_vModelRadio, _unref(values).method]
              ]),
              _cache[12] || (_cache[12] = _createTextVNode(
                " \u0627\u0644\u062F\u0641\u0639 \u0639\u0646\u062F \u0627\u0644\u0627\u0633\u062A\u0644\u0627\u0645",
                -1
                /* CACHED */
              ))
            ])
          ])) : (_openBlock2(), _createElementBlock2("dl", _hoisted_8, [
            _cache[14] || (_cache[14] = _createElementVNode2(
              "dt",
              null,
              "\u0627\u0644\u062A\u0648\u0635\u064A\u0644",
              -1
              /* CACHED */
            )),
            _createElementVNode2("dd", null, [
              _createTextVNode(
                _toDisplayString2(cities[_unref(values).city]) + "\u060C " + _toDisplayString2(_unref(values).street) + " \xB7 ",
                1
                /* TEXT */
              ),
              _createElementVNode2(
                "span",
                _hoisted_9,
                _toDisplayString2(_unref(values).phone),
                1
                /* TEXT */
              )
            ]),
            _cache[15] || (_cache[15] = _createElementVNode2(
              "dt",
              null,
              "\u0627\u0644\u062F\u0641\u0639",
              -1
              /* CACHED */
            )),
            _createElementVNode2(
              "dd",
              null,
              _toDisplayString2(_unref(values).method === "card" ? "\u0628\u0637\u0627\u0642\u0629" : "\u0627\u0644\u062F\u0641\u0639 \u0639\u0646\u062F \u0627\u0644\u0627\u0633\u062A\u0644\u0627\u0645"),
              1
              /* TEXT */
            )
          ])),
          _createElementVNode2("div", _hoisted_10, [
            _createElementVNode2("button", {
              type: "button",
              class: "secondary",
              disabled: step.value === 0,
              onClick: _cache[8] || (_cache[8] = ($event) => step.value--)
            }, "\u0631\u062C\u0648\u0639", 8, _hoisted_11),
            step.value < _unref(STEPS).length - 1 ? (_openBlock2(), _createElementBlock2("button", {
              key: "next",
              type: "button",
              onClick: next
            }, "\u0627\u0644\u062A\u0627\u0644\u064A")) : (_openBlock2(), _createElementBlock2("button", _hoisted_122, "\u0623\u0643\u0651\u062F \u0627\u0644\u0637\u0644\u0628"))
          ])
        ],
        32
        /* NEED_HYDRATION */
      ));
    };
  }
});
var CheckoutForm_default = _sfc2;

// vue/forms/ar/projects/checkout.ts
createApp(CheckoutForm_default).mount("#app");
