// en/react/login.tsx
import { createRoot } from "react-dom/client";

// en/react/LoginForm.tsx
import { useState } from "react";

// en/react/api.ts
async function signIn(email, password) {
  await new Promise((resolve) => setTimeout(resolve, 50));
  if (email === "sara@example.com" && password === "bit2026code") return { name: "Sara" };
  throw new Error("Wrong email or password.");
}

// en/react/LoginForm.tsx
import { jsx, jsxs } from "react/jsx-runtime";
function LoginForm({ signIn: signIn2 = signIn }) {
  const [error, setError] = useState("");
  const [user, setUser] = useState(null);
  const [busy, setBusy] = useState(false);
  async function submit(event) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const email = String(data.get("email") ?? "").trim();
    if (!email) return setError("Please enter your email.");
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
    "Welcome back, ",
    user,
    "!"
  ] });
  return /* @__PURE__ */ jsxs("form", { onSubmit: submit, noValidate: true, "aria-describedby": error ? "login-error" : void 0, children: [
    /* @__PURE__ */ jsx("label", { htmlFor: "email", children: "Email" }),
    /* @__PURE__ */ jsx("input", { id: "email", name: "email", type: "email", autoComplete: "email", dir: "ltr" }),
    /* @__PURE__ */ jsx("label", { htmlFor: "password", children: "Password" }),
    /* @__PURE__ */ jsx("input", { id: "password", name: "password", type: "password", autoComplete: "current-password", dir: "ltr" }),
    error && /* @__PURE__ */ jsx("p", { id: "login-error", role: "alert", children: error }),
    /* @__PURE__ */ jsx("button", { type: "submit", disabled: busy, children: busy ? "Signing in\u2026" : "Sign in" })
  ] });
}

// en/react/login.tsx
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
createRoot(document.getElementById("root")).render(
  /* @__PURE__ */ jsxs2("main", { children: [
    /* @__PURE__ */ jsx2("h1", { children: "Bit's shop" }),
    /* @__PURE__ */ jsx2(LoginForm, {})
  ] })
);
