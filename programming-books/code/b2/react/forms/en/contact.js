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

// en/contact-schema.ts
import { z } from "zod";
var contactSchema;
var init_contact_schema = __esm({
  "en/contact-schema.ts"() {
    contactSchema = z.object({
      name: z.string().trim().min(3, "Please write your full name (at least 3 letters)."),
      email: z.email("Please enter an email like name@example.com."),
      age: z.coerce.number().int("Age must be a whole number.").min(13, "You must be 13 or older."),
      message: z.string().trim().min(20, "Please write at least 20 characters.")
    });
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

// en/contact.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var require_contact = __commonJS({
  "en/contact.tsx"() {
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
      if (sent) return /* @__PURE__ */ jsx2("p", { className: "card done", role: "status", children: "Thank you! We will reply within two days." });
      return /* @__PURE__ */ jsxs2("form", { onSubmit: handleSubmit(onSubmit), noValidate: true, children: [
        /* @__PURE__ */ jsx2(Field, { id: "name", label: "Full name", error: errors.name?.message, children: /* @__PURE__ */ jsx2("input", { id: "name", autoComplete: "name", ...register("name") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "email", label: "Email", error: errors.email?.message, children: /* @__PURE__ */ jsx2("input", { id: "email", type: "email", autoComplete: "email", dir: "ltr", ...register("email") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "age", label: "Age", error: errors.age?.message, children: /* @__PURE__ */ jsx2("input", { id: "age", inputMode: "numeric", ...register("age") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "message", label: "Message", error: errors.message?.message, children: /* @__PURE__ */ jsx2("textarea", { id: "message", rows: 3, ...register("message") }) }),
        /* @__PURE__ */ jsx2("button", { type: "submit", disabled: isSubmitting, children: isSubmitting ? "Sending\u2026" : "Send" })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(ContactForm, {}));
  }
});
export default require_contact();
