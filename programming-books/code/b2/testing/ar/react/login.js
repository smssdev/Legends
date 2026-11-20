// ar/react/login.tsx
import { createRoot } from "react-dom/client";

// ar/react/LoginForm.tsx
import { useState } from "react";

// ar/react/api.ts
async function signIn(email, password) {
  await new Promise((resolve) => setTimeout(resolve, 50));
  if (email === "sara@example.com" && password === "bit2026code") return { name: "\u0633\u0627\u0631\u0629" };
  throw new Error("\u0627\u0644\u0628\u0631\u064A\u062F \u0623\u0648 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D\u0629.");
}

// ar/react/LoginForm.tsx
import { jsx, jsxs } from "react/jsx-runtime";
function LoginForm({ signIn: signIn2 = signIn }) {
  const [error, setError] = useState("");
  const [user, setUser] = useState(null);
  const [busy, setBusy] = useState(false);
  async function submit(event) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const email = String(data.get("email") ?? "").trim();
    if (!email) return setError("\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0643 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A.");
    setBusy(true);
    try {
      const result = await signIn2(email, String(data.get("password") ?? ""));
      setUser(result.name);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  if (user) return /* @__PURE__ */ jsxs("h2", { children: [
    "\u0623\u0647\u0644\u0627\u064B \u0628\u0639\u0648\u062F\u062A\u0643 \u064A\u0627 ",
    user,
    "!"
  ] });
  return /* @__PURE__ */ jsxs("form", { onSubmit: submit, noValidate: true, "aria-describedby": error ? "login-error" : void 0, children: [
    /* @__PURE__ */ jsx("label", { htmlFor: "email", children: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A" }),
    /* @__PURE__ */ jsx("input", { id: "email", name: "email", type: "email", autoComplete: "email", dir: "ltr" }),
    /* @__PURE__ */ jsx("label", { htmlFor: "password", children: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631" }),
    /* @__PURE__ */ jsx("input", { id: "password", name: "password", type: "password", autoComplete: "current-password", dir: "ltr" }),
    error && /* @__PURE__ */ jsx("p", { id: "login-error", role: "alert", children: error }),
    /* @__PURE__ */ jsx("button", { type: "submit", disabled: busy, children: busy ? "\u062C\u0627\u0631\u064D \u0627\u0644\u062F\u062E\u0648\u0644\u2026" : "\u0633\u062C\u0651\u0644 \u0627\u0644\u062F\u062E\u0648\u0644" })
  ] });
}

// ar/react/login.tsx
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
createRoot(document.getElementById("root")).render(
  /* @__PURE__ */ jsxs2("main", { children: [
    /* @__PURE__ */ jsx2("h1", { children: "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A" }),
    /* @__PURE__ */ jsx2(LoginForm, {})
  ] })
);
