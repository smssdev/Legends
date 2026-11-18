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

// en/projects/signup-schema.ts
import { z } from "zod";
var signupSchema;
var init_signup_schema = __esm({
  "en/projects/signup-schema.ts"() {
    signupSchema = z.object({
      email: z.email("Please enter an email like name@example.com."),
      password: z.string().min(8, "At least 8 characters, with a number.").regex(/\d/, "At least 8 characters, with a number."),
      confirm: z.string(),
      terms: z.literal(true, "Please accept the terms to continue.")
    }).refine((data) => data.password === data.confirm, {
      message: "The passwords do not match.",
      path: ["confirm"]
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

// en/projects/signup.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var require_signup = __commonJS({
  "en/projects/signup.tsx"() {
    init_signup_schema();
    init_field();
    async function createAccount(data) {
      await new Promise((resolve) => setTimeout(resolve, 400));
      if (data.email === "sara@example.com") return { ok: false, field: "email", message: "This email already has an account. Sign in instead?" };
      return { ok: true };
    }
    function SignupForm() {
      const [done, setDone] = useState(false);
      const {
        register,
        handleSubmit,
        setError,
        formState: { errors, isSubmitting }
      } = useForm({ resolver: zodResolver(signupSchema), mode: "onTouched" });
      async function onSubmit(data) {
        const result = await createAccount(data);
        if (!result.ok) {
          setError(result.field, { message: result.message }, { shouldFocus: true });
          return;
        }
        setDone(true);
      }
      if (done) return /* @__PURE__ */ jsx2("p", { className: "card done", role: "status", children: "Your account is ready." });
      return /* @__PURE__ */ jsxs2("form", { onSubmit: handleSubmit(onSubmit), noValidate: true, children: [
        /* @__PURE__ */ jsx2(Field, { id: "email", label: "Email", error: errors.email?.message, children: /* @__PURE__ */ jsx2("input", { id: "email", type: "email", autoComplete: "email", dir: "ltr", ...register("email") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "password", label: "Password", error: errors.password?.message, children: /* @__PURE__ */ jsx2("input", { id: "password", type: "password", autoComplete: "new-password", dir: "ltr", ...register("password") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "confirm", label: "Confirm password", error: errors.confirm?.message, children: /* @__PURE__ */ jsx2("input", { id: "confirm", type: "password", autoComplete: "new-password", dir: "ltr", ...register("confirm") }) }),
        /* @__PURE__ */ jsxs2("div", { className: "field", children: [
          /* @__PURE__ */ jsxs2("label", { className: "check", children: [
            /* @__PURE__ */ jsx2("input", { type: "checkbox", "aria-invalid": errors.terms ? true : void 0, ...register("terms") }),
            "I accept the terms"
          ] }),
          errors.terms && /* @__PURE__ */ jsx2("p", { className: "error", children: errors.terms.message })
        ] }),
        /* @__PURE__ */ jsx2("button", { type: "submit", disabled: isSubmitting, children: isSubmitting ? "Sending\u2026" : "Create account" })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(SignupForm, {}));
  }
});
export default require_signup();
