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

// ar/contact-schema.ts
import { z } from "zod";
var contactSchema;
var init_contact_schema = __esm({
  "ar/contact-schema.ts"() {
    contactSchema = z.object({
      name: z.string().trim().min(3, "\u0627\u0643\u062A\u0628 \u0627\u0633\u0645\u0643 \u0627\u0644\u0643\u0627\u0645\u0644 (3 \u0623\u062D\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644)."),
      email: z.email("\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0627\u064B \u0645\u062B\u0644 name@example.com"),
      age: z.coerce.number().int("\u064A\u062C\u0628 \u0623\u0646 \u064A\u0643\u0648\u0646 \u0627\u0644\u0639\u0645\u0631 \u0631\u0642\u0645\u0627\u064B \u0635\u062D\u064A\u062D\u0627\u064B.").min(13, "\u064A\u062C\u0628 \u0623\u0646 \u064A\u0643\u0648\u0646 \u0639\u0645\u0631\u0643 13 \u0633\u0646\u0629 \u0623\u0648 \u0623\u0643\u062B\u0631."),
      message: z.string().trim().min(20, "\u0627\u0643\u062A\u0628 20 \u062D\u0631\u0641\u0627\u064B \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644.")
    });
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

// ar/contact.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var require_contact = __commonJS({
  "ar/contact.tsx"() {
    init_contact_schema();
    init_field();
    function ContactForm() {
      const [sent, setSent] = useState(false);
      const {
        register,
        handleSubmit,
        formState: { errors, isSubmitting }
      } = useForm({
        resolver: zodResolver(contactSchema),
        mode: "onTouched"
      });
      async function onSubmit(data) {
        await new Promise((resolve) => setTimeout(resolve, 500));
        console.log(data);
        setSent(true);
      }
      if (sent) return /* @__PURE__ */ jsx2("p", { className: "card done", role: "status", children: "\u0634\u0643\u0631\u0627\u064B \u0644\u0643! \u0633\u0646\u0631\u062F \u062E\u0644\u0627\u0644 \u064A\u0648\u0645\u064A\u0646." });
      return /* @__PURE__ */ jsxs2("form", { onSubmit: handleSubmit(onSubmit), noValidate: true, children: [
        /* @__PURE__ */ jsx2(Field, { id: "name", label: "\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644", error: errors.name?.message, children: /* @__PURE__ */ jsx2("input", { id: "name", autoComplete: "name", ...register("name") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "email", label: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A", error: errors.email?.message, children: /* @__PURE__ */ jsx2("input", { id: "email", type: "email", autoComplete: "email", dir: "ltr", ...register("email") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "age", label: "\u0627\u0644\u0639\u0645\u0631", error: errors.age?.message, children: /* @__PURE__ */ jsx2("input", { id: "age", inputMode: "numeric", ...register("age") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "message", label: "\u0627\u0644\u0631\u0633\u0627\u0644\u0629", error: errors.message?.message, children: /* @__PURE__ */ jsx2("textarea", { id: "message", rows: 3, ...register("message") }) }),
        /* @__PURE__ */ jsx2("button", { type: "submit", disabled: isSubmitting, children: isSubmitting ? "\u062C\u0627\u0631\u064D \u0627\u0644\u0625\u0631\u0633\u0627\u0644\u2026" : "\u0623\u0631\u0633\u0644" })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(ContactForm, {}));
  }
});
export default require_contact();
