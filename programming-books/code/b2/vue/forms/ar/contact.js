// vue/forms/ar/contact.ts
import { createApp } from "vue";

// vue/forms/ar/ContactForm.vue
import { defineComponent as _defineComponent2 } from "vue";
import { openBlock as _openBlock2, createElementBlock as _createElementBlock2, unref as _unref, vModelDynamic as _vModelDynamic, mergeProps as _mergeProps, createElementVNode as _createElementVNode2, withDirectives as _withDirectives, withCtx as _withCtx, createVNode as _createVNode, vModelText as _vModelText, toDisplayString as _toDisplayString2, withModifiers as _withModifiers } from "vue";
import { ref as ref2 } from "vue";

// vue/forms/ar/contact-schema.ts
import * as z from "zod";
var contactSchema = z.object({
  name: z.string().trim().min(3, "\u0627\u0643\u062A\u0628 \u0627\u0633\u0645\u0643 \u0627\u0644\u0643\u0627\u0645\u0644 (3 \u0623\u062D\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644)."),
  email: z.email("\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0627\u064B \u0645\u062B\u0644 name@example.com"),
  age: z.coerce.number().int("\u064A\u062C\u0628 \u0623\u0646 \u064A\u0643\u0648\u0646 \u0627\u0644\u0639\u0645\u0631 \u0631\u0642\u0645\u0627\u064B \u0635\u062D\u064A\u062D\u0627\u064B.").min(13, "\u064A\u062C\u0628 \u0623\u0646 \u064A\u0643\u0648\u0646 \u0639\u0645\u0631\u0643 13 \u0633\u0646\u0629 \u0623\u0648 \u0623\u0643\u062B\u0631."),
  message: z.string().trim().min(20, "\u0627\u0643\u062A\u0628 20 \u062D\u0631\u0641\u0627\u064B \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644.")
});

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

// vue/forms/ar/ContactForm.vue
var _hoisted_12 = {
  key: 0,
  class: "card done",
  role: "status"
};
var _hoisted_22 = ["disabled"];
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "ContactForm",
  setup(__props) {
    const { values, errors, submitting, blur, handleSubmit } = useForm(contactSchema, {
      name: "",
      email: "",
      age: "",
      message: ""
    });
    const sent = ref2(false);
    const submit = handleSubmit(async (contact) => {
      await new Promise((resolve) => setTimeout(resolve, 600));
      sent.value = true;
    });
    return (_ctx, _cache) => {
      return sent.value ? (_openBlock2(), _createElementBlock2("p", _hoisted_12, "\u0634\u0643\u0631\u0627\u064B \u0644\u0643! \u0633\u0646\u0631\u062F \u062E\u0644\u0627\u0644 \u064A\u0648\u0645\u064A\u0646.")) : (_openBlock2(), _createElementBlock2(
        "form",
        {
          key: 1,
          novalidate: "",
          onSubmit: _cache[8] || (_cache[8] = _withModifiers(
            //@ts-ignore
            (...args) => _unref(submit) && _unref(submit)(...args),
            ["prevent"]
          ))
        },
        [
          _createVNode(FormField_default, {
            id: "name",
            label: "\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644",
            error: _unref(errors).name
          }, {
            default: _withCtx((attrs) => [
              _withDirectives(_createElementVNode2(
                "input",
                _mergeProps(attrs, {
                  "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => _unref(values).name = $event),
                  autocomplete: "name",
                  onBlur: _cache[1] || (_cache[1] = ($event) => _unref(blur)("name"))
                }),
                null,
                16
                /* FULL_PROPS */
              ), [
                [_vModelDynamic, _unref(values).name]
              ])
            ]),
            _: 1
            /* STABLE */
          }, 8, ["error"]),
          _createVNode(FormField_default, {
            id: "email",
            label: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A",
            error: _unref(errors).email
          }, {
            default: _withCtx((attrs) => [
              _withDirectives(_createElementVNode2(
                "input",
                _mergeProps(attrs, {
                  "onUpdate:modelValue": _cache[2] || (_cache[2] = ($event) => _unref(values).email = $event),
                  type: "email",
                  autocomplete: "email",
                  dir: "ltr",
                  onBlur: _cache[3] || (_cache[3] = ($event) => _unref(blur)("email"))
                }),
                null,
                16
                /* FULL_PROPS */
              ), [
                [_vModelText, _unref(values).email]
              ])
            ]),
            _: 1
            /* STABLE */
          }, 8, ["error"]),
          _createVNode(FormField_default, {
            id: "age",
            label: "\u0627\u0644\u0639\u0645\u0631",
            error: _unref(errors).age
          }, {
            default: _withCtx((attrs) => [
              _withDirectives(_createElementVNode2(
                "input",
                _mergeProps(attrs, {
                  "onUpdate:modelValue": _cache[4] || (_cache[4] = ($event) => _unref(values).age = $event),
                  inputmode: "numeric",
                  onBlur: _cache[5] || (_cache[5] = ($event) => _unref(blur)("age"))
                }),
                null,
                16
                /* FULL_PROPS */
              ), [
                [_vModelDynamic, _unref(values).age]
              ])
            ]),
            _: 1
            /* STABLE */
          }, 8, ["error"]),
          _createVNode(FormField_default, {
            id: "message",
            label: "\u0627\u0644\u0631\u0633\u0627\u0644\u0629",
            error: _unref(errors).message
          }, {
            default: _withCtx((attrs) => [
              _withDirectives(_createElementVNode2(
                "textarea",
                _mergeProps(attrs, {
                  "onUpdate:modelValue": _cache[6] || (_cache[6] = ($event) => _unref(values).message = $event),
                  rows: "3",
                  onBlur: _cache[7] || (_cache[7] = ($event) => _unref(blur)("message"))
                }),
                null,
                16
                /* FULL_PROPS */
              ), [
                [_vModelText, _unref(values).message]
              ])
            ]),
            _: 1
            /* STABLE */
          }, 8, ["error"]),
          _createElementVNode2("button", {
            type: "submit",
            disabled: _unref(submitting)
          }, _toDisplayString2(_unref(submitting) ? "\u062C\u0627\u0631\u064D \u0627\u0644\u0625\u0631\u0633\u0627\u0644\u2026" : "\u0623\u0631\u0633\u0644"), 9, _hoisted_22)
        ],
        32
        /* NEED_HYDRATION */
      ));
    };
  }
});
var ContactForm_default = _sfc2;

// vue/forms/ar/contact.ts
createApp(ContactForm_default).mount("#app");
