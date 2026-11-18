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

// en/projects/checkout-schema.ts
import { z } from "zod";
var delivery, payment, checkoutSchema, STEPS;
var init_checkout_schema = __esm({
  "en/projects/checkout-schema.ts"() {
    delivery = z.object({
      city: z.enum(["cairo", "alexandria", "giza"], "Please choose a city."),
      street: z.string().trim().min(5, "Please write the street and building number."),
      phone: z.string().regex(/^01[0125]\d{8}$/, "Please enter an 11-digit Egyptian mobile number.")
    });
    payment = z.object({
      method: z.enum(["card", "cash"])
    });
    checkoutSchema = delivery.extend(payment.shape);
    STEPS = [
      { title: "Delivery", fields: ["city", "street", "phone"] },
      { title: "Payment", fields: ["method"] },
      { title: "Review", fields: [] }
    ];
  }
});

// en/field.tsx
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
  "en/field.tsx"() {
  }
});

// en/projects/checkout.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Fragment, jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var require_checkout = __commonJS({
  "en/projects/checkout.tsx"() {
    init_checkout_schema();
    init_field();
    var CITY_NAMES = { cairo: "Cairo", alexandria: "Alexandria", giza: "Giza" };
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
      if (placed) return /* @__PURE__ */ jsx2("p", { className: "card done", role: "status", children: "Order placed!" });
      const values = getValues();
      return /* @__PURE__ */ jsxs2("form", { onSubmit: handleSubmit(() => setPlaced(true)), noValidate: true, children: [
        /* @__PURE__ */ jsx2("ol", { className: "steps", children: STEPS.map((s, i) => /* @__PURE__ */ jsx2("li", { "aria-current": i === step ? "step" : void 0, children: s.title }, s.title)) }),
        /* @__PURE__ */ jsxs2("p", { className: "sr-only", children: [
          "Step ",
          step + 1,
          " of ",
          STEPS.length
        ] }),
        step === 0 && /* @__PURE__ */ jsxs2(Fragment, { children: [
          /* @__PURE__ */ jsx2(Field, { id: "city", label: "City", error: errors.city?.message, children: /* @__PURE__ */ jsxs2("select", { id: "city", ...register("city"), children: [
            /* @__PURE__ */ jsx2("option", { value: "", children: "Choose\u2026" }),
            Object.entries(CITY_NAMES).map(([value, name]) => /* @__PURE__ */ jsx2("option", { value, children: name }, value))
          ] }) }),
          /* @__PURE__ */ jsx2(Field, { id: "street", label: "Street and number", error: errors.street?.message, children: /* @__PURE__ */ jsx2("input", { id: "street", autoComplete: "street-address", ...register("street") }) }),
          /* @__PURE__ */ jsx2(Field, { id: "phone", label: "Mobile number", error: errors.phone?.message, children: /* @__PURE__ */ jsx2("input", { id: "phone", type: "tel", autoComplete: "tel", dir: "ltr", ...register("phone") }) })
        ] }),
        step === 1 && /* @__PURE__ */ jsxs2("fieldset", { className: "field", style: { border: 0, padding: 0 }, children: [
          /* @__PURE__ */ jsx2("legend", { style: { fontWeight: 600 }, children: "Payment method" }),
          /* @__PURE__ */ jsxs2("label", { className: "check", children: [
            /* @__PURE__ */ jsx2("input", { type: "radio", value: "cash", ...register("method") }),
            " Cash on delivery"
          ] }),
          /* @__PURE__ */ jsxs2("label", { className: "check", children: [
            /* @__PURE__ */ jsx2("input", { type: "radio", value: "card", ...register("method") }),
            " Card"
          ] })
        ] }),
        step === 2 && /* @__PURE__ */ jsxs2("dl", { children: [
          /* @__PURE__ */ jsx2("dt", { children: "Delivery" }),
          /* @__PURE__ */ jsxs2("dd", { children: [
            CITY_NAMES[values.city],
            ", ",
            values.street,
            ", ",
            /* @__PURE__ */ jsx2("span", { dir: "ltr", children: values.phone })
          ] }),
          /* @__PURE__ */ jsx2("dt", { children: "Payment" }),
          /* @__PURE__ */ jsx2("dd", { children: values.method === "card" ? "Card" : "Cash on delivery" })
        ] }),
        /* @__PURE__ */ jsxs2("div", { className: "row", children: [
          /* @__PURE__ */ jsx2("button", { type: "button", className: "secondary", onClick: () => setStep(step - 1), disabled: step === 0, children: "Back" }),
          step < STEPS.length - 1 ? /* @__PURE__ */ jsx2("button", { type: "button", onClick: next, children: "Next" }, "next") : (
            // A different key: a new button, not the Next button turned into a submit button
            /* @__PURE__ */ jsx2("button", { type: "submit", children: "Place order" }, "submit")
          )
        ] })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(CheckoutForm, {}));
  }
});
export default require_checkout();
