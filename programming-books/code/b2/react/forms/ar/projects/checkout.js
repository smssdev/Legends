var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/projects/checkout-schema.ts
import { z } from "zod";
var delivery, payment, checkoutSchema, STEPS;
var init_checkout_schema = __esm({
  "ar/projects/checkout-schema.ts"() {
    delivery = z.object({
      city: z.enum(["cairo", "alexandria", "giza"], "\u0627\u062E\u062A\u0631 \u0645\u062F\u064A\u0646\u0629."),
      street: z.string().trim().min(5, "\u0627\u0643\u062A\u0628 \u0627\u0644\u0634\u0627\u0631\u0639 \u0648\u0631\u0642\u0645 \u0627\u0644\u0645\u0628\u0646\u0649."),
      phone: z.string().regex(/^01[0125]\d{8}$/, "\u0627\u0643\u062A\u0628 \u0631\u0642\u0645 \u062C\u0648\u0627\u0644 \u0645\u0635\u0631\u064A\u0627\u064B \u0645\u0646 11 \u0631\u0642\u0645\u0627\u064B.")
    });
    payment = z.object({
      method: z.enum(["card", "cash"])
    });
    checkoutSchema = delivery.extend(payment.shape);
    STEPS = [
      { title: "\u0627\u0644\u062A\u0648\u0635\u064A\u0644", fields: ["city", "street", "phone"] },
      { title: "\u0627\u0644\u062F\u0641\u0639", fields: ["method"] },
      { title: "\u0627\u0644\u0645\u0631\u0627\u062C\u0639\u0629", fields: [] }
    ];
  }
});

// ar/field.tsx
import { cloneElement, isValidElement } from "react";
import { jsx, jsxs } from "react/jsx-runtime";
function Field({ id, label, error, children }) {
  const errorId = `${id}-error`;
  const input = isValidElement(children) ? cloneElement(children, {
    "aria-invalid": error ? true : void 0,
    "aria-describedby": error ? errorId : void 0
  }) : children;
  return /* @__PURE__ */ jsxs("div", { className: "field", children: [
    /* @__PURE__ */ jsx("label", { htmlFor: id, children: label }),
    input,
    error && /* @__PURE__ */ jsx("p", { className: "error", id: errorId, children: error })
  ] });
}
var init_field = __esm({
  "ar/field.tsx"() {
  }
});

// ar/projects/checkout.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Fragment, jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var require_checkout = __commonJS({
  "ar/projects/checkout.tsx"() {
    init_checkout_schema();
    init_field();
    var CITY_NAMES = { cairo: "\u0627\u0644\u0642\u0627\u0647\u0631\u0629", alexandria: "\u0627\u0644\u0625\u0633\u0643\u0646\u062F\u0631\u064A\u0629", giza: "\u0627\u0644\u062C\u064A\u0632\u0629" };
    function CheckoutForm() {
      const [step, setStep] = useState(0);
      const [placed, setPlaced] = useState(false);
      const form = useForm({
        resolver: zodResolver(checkoutSchema),
        defaultValues: { method: "cash" },
        mode: "onTouched"
      });
      const { register, trigger, getValues, handleSubmit, formState } = form;
      const errors = formState.errors;
      async function next() {
        const ok = await trigger([...STEPS[step].fields], { shouldFocus: true });
        if (ok) setStep(step + 1);
      }
      if (placed) return /* @__PURE__ */ jsx2("p", { className: "card done", role: "status", children: "\u062A\u0645 \u0627\u0644\u0637\u0644\u0628!" });
      const values = getValues();
      return /* @__PURE__ */ jsxs2("form", { onSubmit: handleSubmit(() => setPlaced(true)), noValidate: true, children: [
        /* @__PURE__ */ jsx2("ol", { className: "steps", children: STEPS.map((s, i) => /* @__PURE__ */ jsx2("li", { "aria-current": i === step ? "step" : void 0, children: s.title }, s.title)) }),
        /* @__PURE__ */ jsxs2("p", { className: "sr-only", children: [
          "\u0627\u0644\u062E\u0637\u0648\u0629 ",
          step + 1,
          " \u0645\u0646 ",
          STEPS.length
        ] }),
        step === 0 && /* @__PURE__ */ jsxs2(Fragment, { children: [
          /* @__PURE__ */ jsx2(Field, { id: "city", label: "\u0627\u0644\u0645\u062F\u064A\u0646\u0629", error: errors.city?.message, children: /* @__PURE__ */ jsxs2("select", { id: "city", ...register("city"), children: [
            /* @__PURE__ */ jsx2("option", { value: "", children: "\u0627\u062E\u062A\u0631\u2026" }),
            Object.entries(CITY_NAMES).map(([value, name]) => /* @__PURE__ */ jsx2("option", { value, children: name }, value))
          ] }) }),
          /* @__PURE__ */ jsx2(Field, { id: "street", label: "\u0627\u0644\u0634\u0627\u0631\u0639 \u0648\u0631\u0642\u0645 \u0627\u0644\u0645\u0628\u0646\u0649", error: errors.street?.message, children: /* @__PURE__ */ jsx2("input", { id: "street", autoComplete: "street-address", ...register("street") }) }),
          /* @__PURE__ */ jsx2(Field, { id: "phone", label: "\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644", error: errors.phone?.message, children: /* @__PURE__ */ jsx2("input", { id: "phone", type: "tel", autoComplete: "tel", dir: "ltr", ...register("phone") }) })
        ] }),
        step === 1 && /* @__PURE__ */ jsxs2("fieldset", { className: "field", style: { border: 0, padding: 0 }, children: [
          /* @__PURE__ */ jsx2("legend", { style: { fontWeight: 600 }, children: "\u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639" }),
          /* @__PURE__ */ jsxs2("label", { className: "check", children: [
            /* @__PURE__ */ jsx2("input", { type: "radio", value: "cash", ...register("method") }),
            " \u0627\u0644\u062F\u0641\u0639 \u0639\u0646\u062F \u0627\u0644\u0627\u0633\u062A\u0644\u0627\u0645"
          ] }),
          /* @__PURE__ */ jsxs2("label", { className: "check", children: [
            /* @__PURE__ */ jsx2("input", { type: "radio", value: "card", ...register("method") }),
            " \u0628\u0637\u0627\u0642\u0629"
          ] })
        ] }),
        step === 2 && /* @__PURE__ */ jsxs2("dl", { children: [
          /* @__PURE__ */ jsx2("dt", { children: "\u0627\u0644\u062A\u0648\u0635\u064A\u0644" }),
          /* @__PURE__ */ jsxs2("dd", { children: [
            CITY_NAMES[values.city],
            "\u060C ",
            values.street,
            "\u060C ",
            /* @__PURE__ */ jsx2("span", { dir: "ltr", children: values.phone })
          ] }),
          /* @__PURE__ */ jsx2("dt", { children: "\u0627\u0644\u062F\u0641\u0639" }),
          /* @__PURE__ */ jsx2("dd", { children: values.method === "card" ? "\u0628\u0637\u0627\u0642\u0629" : "\u0627\u0644\u062F\u0641\u0639 \u0639\u0646\u062F \u0627\u0644\u0627\u0633\u062A\u0644\u0627\u0645" })
        ] }),
        /* @__PURE__ */ jsxs2("div", { className: "row", children: [
          /* @__PURE__ */ jsx2("button", { type: "button", className: "secondary", onClick: () => setStep(step - 1), disabled: step === 0, children: "\u0631\u062C\u0648\u0639" }),
          step < STEPS.length - 1 ? /* @__PURE__ */ jsx2("button", { type: "button", onClick: next, children: "\u0627\u0644\u062A\u0627\u0644\u064A" }, "next") : (
            // مفتاح مختلف: زر جديد، لا زر «التالي» وقد صار زر إرسال
            /* @__PURE__ */ jsx2("button", { type: "submit", children: "\u0623\u0643\u0651\u062F \u0627\u0644\u0637\u0644\u0628" }, "submit")
          )
        ] })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(CheckoutForm, {}));
  }
});
export default require_checkout();
