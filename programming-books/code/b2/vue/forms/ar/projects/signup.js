// vue/forms/ar/projects/signup.ts
import { createApp } from "vue";

// vue/forms/ar/projects/SignupForm.vue
import { defineComponent as _defineComponent2 } from "vue";
import { openBlock as _openBlock2, createElementBlock as _createElementBlock2, createCommentVNode as _createCommentVNode2, unref as _unref, vModelText as _vModelText, mergeProps as _mergeProps, createElementVNode as _createElementVNode2, withDirectives as _withDirectives, withCtx as _withCtx, createVNode as _createVNode, vModelCheckbox as _vModelCheckbox, createTextVNode as _createTextVNode, toDisplayString as _toDisplayString2, withModifiers as _withModifiers } from "vue";
import { ref as ref2 } from "vue";
import * as z2 from "zod";

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

// vue/forms/ar/projects/signup-schema.ts
import * as z from "zod";
var signupSchema = z.object({
  email: z.email("\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0627\u064B \u0645\u062B\u0644 name@example.com"),
  password: z.string().min(8, "8 \u0623\u062D\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644\u060C \u0648\u0641\u064A\u0647\u0627 \u0631\u0642\u0645.").regex(/\d/, "8 \u0623\u062D\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644\u060C \u0648\u0641\u064A\u0647\u0627 \u0631\u0642\u0645."),
  confirm: z.string(),
  terms: z.literal(true, "\u0648\u0627\u0641\u0642 \u0639\u0644\u0649 \u0627\u0644\u0634\u0631\u0648\u0637 \u0644\u062A\u062A\u0627\u0628\u0639.")
}).refine((data) => data.password === data.confirm, { message: "\u0643\u0644\u0645\u062A\u0627 \u0627\u0644\u0645\u0631\u0648\u0631 \u063A\u064A\u0631 \u0645\u062A\u0637\u0627\u0628\u0642\u062A\u064A\u0646.", path: ["confirm"] });

// vue/forms/ar/projects/SignupForm.vue
var _hoisted_12 = {
  key: 0,
  class: "card done",
  role: "status"
};
var _hoisted_22 = { class: "field" };
var _hoisted_32 = { class: "check" };
var _hoisted_4 = ["aria-invalid"];
var _hoisted_5 = {
  key: 0,
  class: "error"
};
var _hoisted_6 = ["disabled"];
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "SignupForm",
  setup(__props) {
    const fields = z2.object({ ...signupSchema.shape, terms: z2.boolean() });
    const { values, errors, submitting, blur, handleSubmit } = useForm(fields, {
      email: "",
      password: "",
      confirm: "",
      terms: false
    });
    const created = ref2(false);
    const submit = handleSubmit(async (data) => {
      const result = signupSchema.safeParse(data);
      if (!result.success) {
        return Object.fromEntries(result.error.issues.map((i) => [String(i.path[0]), i.message]));
      }
      await new Promise((resolve) => setTimeout(resolve, 400));
      if (data.email === "sara@example.com") return { email: "\u0644\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u064A\u062F \u062D\u0633\u0627\u0628 \u0628\u0627\u0644\u0641\u0639\u0644. \u0647\u0644 \u062A\u0631\u064A\u062F \u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644\u061F" };
      created.value = true;
    });
    return (_ctx, _cache) => {
      return created.value ? (_openBlock2(), _createElementBlock2("p", _hoisted_12, "\u062D\u0633\u0627\u0628\u0643 \u062C\u0627\u0647\u0632.")) : (_openBlock2(), _createElementBlock2(
        "form",
        {
          key: 1,
          novalidate: "",
          onSubmit: _cache[7] || (_cache[7] = _withModifiers(
            //@ts-ignore
            (...args) => _unref(submit) && _unref(submit)(...args),
            ["prevent"]
          ))
        },
        [
          _createVNode(FormField_default, {
            id: "email",
            label: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A",
            error: _unref(errors).email
          }, {
            default: _withCtx((attrs) => [
              _withDirectives(_createElementVNode2(
                "input",
                _mergeProps(attrs, {
                  "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => _unref(values).email = $event),
                  type: "email",
                  autocomplete: "email",
                  dir: "ltr",
                  onBlur: _cache[1] || (_cache[1] = ($event) => _unref(blur)("email"))
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
            id: "password",
            label: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631",
            error: _unref(errors).password
          }, {
            default: _withCtx((attrs) => [
              _withDirectives(_createElementVNode2(
                "input",
                _mergeProps(attrs, {
                  "onUpdate:modelValue": _cache[2] || (_cache[2] = ($event) => _unref(values).password = $event),
                  type: "password",
                  autocomplete: "new-password",
                  dir: "ltr",
                  onBlur: _cache[3] || (_cache[3] = ($event) => _unref(blur)("password"))
                }),
                null,
                16
                /* FULL_PROPS */
              ), [
                [_vModelText, _unref(values).password]
              ])
            ]),
            _: 1
            /* STABLE */
          }, 8, ["error"]),
          _createVNode(FormField_default, {
            id: "confirm",
            label: "\u0623\u0643\u0651\u062F \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631",
            error: _unref(errors).confirm
          }, {
            default: _withCtx((attrs) => [
              _withDirectives(_createElementVNode2(
                "input",
                _mergeProps(attrs, {
                  "onUpdate:modelValue": _cache[4] || (_cache[4] = ($event) => _unref(values).confirm = $event),
                  type: "password",
                  autocomplete: "new-password",
                  dir: "ltr",
                  onBlur: _cache[5] || (_cache[5] = ($event) => _unref(blur)("confirm"))
                }),
                null,
                16
                /* FULL_PROPS */
              ), [
                [_vModelText, _unref(values).confirm]
              ])
            ]),
            _: 1
            /* STABLE */
          }, 8, ["error"]),
          _createElementVNode2("div", _hoisted_22, [
            _createElementVNode2("label", _hoisted_32, [
              _withDirectives(_createElementVNode2("input", {
                "onUpdate:modelValue": _cache[6] || (_cache[6] = ($event) => _unref(values).terms = $event),
                type: "checkbox",
                "aria-invalid": !!_unref(errors).terms
              }, null, 8, _hoisted_4), [
                [_vModelCheckbox, _unref(values).terms]
              ]),
              _cache[8] || (_cache[8] = _createTextVNode(
                " \u0623\u0648\u0627\u0641\u0642 \u0639\u0644\u0649 \u0627\u0644\u0634\u0631\u0648\u0637",
                -1
                /* CACHED */
              ))
            ]),
            _unref(errors).terms ? (_openBlock2(), _createElementBlock2(
              "p",
              _hoisted_5,
              _toDisplayString2(_unref(errors).terms),
              1
              /* TEXT */
            )) : _createCommentVNode2("v-if", true)
          ]),
          _createElementVNode2("button", {
            type: "submit",
            disabled: _unref(submitting)
          }, "\u0623\u0646\u0634\u0626 \u0627\u0644\u062D\u0633\u0627\u0628", 8, _hoisted_6)
        ],
        32
        /* NEED_HYDRATION */
      ));
    };
  }
});
var SignupForm_default = _sfc2;

// vue/forms/ar/projects/signup.ts
createApp(SignupForm_default).mount("#app");
