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

// ar/projects/signup-schema.ts
import { z } from "zod";
var signupSchema;
var init_signup_schema = __esm({
  "ar/projects/signup-schema.ts"() {
    signupSchema = z.object({
      email: z.email("\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0627\u064B \u0645\u062B\u0644 name@example.com"),
      password: z.string().min(8, "8 \u0623\u062D\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644\u060C \u0648\u0641\u064A\u0647\u0627 \u0631\u0642\u0645.").regex(/\d/, "8 \u0623\u062D\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644\u060C \u0648\u0641\u064A\u0647\u0627 \u0631\u0642\u0645."),
      confirm: z.string(),
      terms: z.literal(true, "\u0648\u0627\u0641\u0642 \u0639\u0644\u0649 \u0627\u0644\u0634\u0631\u0648\u0637 \u0644\u062A\u062A\u0627\u0628\u0639.")
    }).refine((data) => data.password === data.confirm, {
      message: "\u0643\u0644\u0645\u062A\u0627 \u0627\u0644\u0645\u0631\u0648\u0631 \u063A\u064A\u0631 \u0645\u062A\u0637\u0627\u0628\u0642\u062A\u064A\u0646.",
      path: ["confirm"]
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

// ar/projects/signup.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var require_signup = __commonJS({
  "ar/projects/signup.tsx"() {
    init_signup_schema();
    init_field();
    async function createAccount(data) {
      await new Promise((resolve) => setTimeout(resolve, 400));
      if (data.email === "sara@example.com") return { ok: false, field: "email", message: "\u0644\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u064A\u062F \u062D\u0633\u0627\u0628 \u0628\u0627\u0644\u0641\u0639\u0644. \u0647\u0644 \u062A\u0631\u064A\u062F \u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644\u061F" };
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
      if (done) return /* @__PURE__ */ jsx2("p", { className: "card done", role: "status", children: "\u062D\u0633\u0627\u0628\u0643 \u062C\u0627\u0647\u0632." });
      return /* @__PURE__ */ jsxs2("form", { onSubmit: handleSubmit(onSubmit), noValidate: true, children: [
        /* @__PURE__ */ jsx2(Field, { id: "email", label: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A", error: errors.email?.message, children: /* @__PURE__ */ jsx2("input", { id: "email", type: "email", autoComplete: "email", dir: "ltr", ...register("email") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "password", label: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631", error: errors.password?.message, children: /* @__PURE__ */ jsx2("input", { id: "password", type: "password", autoComplete: "new-password", dir: "ltr", ...register("password") }) }),
        /* @__PURE__ */ jsx2(Field, { id: "confirm", label: "\u0623\u0643\u0651\u062F \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631", error: errors.confirm?.message, children: /* @__PURE__ */ jsx2("input", { id: "confirm", type: "password", autoComplete: "new-password", dir: "ltr", ...register("confirm") }) }),
        /* @__PURE__ */ jsxs2("div", { className: "field", children: [
          /* @__PURE__ */ jsxs2("label", { className: "check", children: [
            /* @__PURE__ */ jsx2("input", { type: "checkbox", "aria-invalid": errors.terms ? true : void 0, ...register("terms") }),
            "\u0623\u0648\u0627\u0641\u0642 \u0639\u0644\u0649 \u0627\u0644\u0634\u0631\u0648\u0637"
          ] }),
          errors.terms && /* @__PURE__ */ jsx2("p", { className: "error", children: errors.terms.message })
        ] }),
        /* @__PURE__ */ jsx2("button", { type: "submit", disabled: isSubmitting, children: isSubmitting ? "\u062C\u0627\u0631\u064D \u0627\u0644\u0625\u0631\u0633\u0627\u0644\u2026" : "\u0623\u0646\u0634\u0626 \u0627\u0644\u062D\u0633\u0627\u0628" })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(SignupForm, {}));
  }
});
export default require_signup();
