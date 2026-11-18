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

// ar/auth.tsx
import { createContext, useContext, useMemo, useState } from "react";
import { jsx } from "react/jsx-runtime";
function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const value = useMemo(
    () => ({ user, signIn: (name) => setUser({ name }), signOut: () => setUser(null) }),
    [user]
  );
  return /* @__PURE__ */ jsx(AuthContext.Provider, { value, children });
}
function useAuth() {
  const auth = useContext(AuthContext);
  if (!auth) throw new Error("useAuth must be used inside <AuthProvider>");
  return auth;
}
var AuthContext;
var init_auth = __esm({
  "ar/auth.tsx"() {
    AuthContext = createContext(null);
  }
});

// ar/context.tsx
import { createRoot } from "react-dom/client";
import { jsx as jsx2, jsxs } from "react/jsx-runtime";
var require_context = __commonJS({
  "ar/context.tsx"() {
    init_auth();
    function Header() {
      return /* @__PURE__ */ jsxs("header", { children: [
        /* @__PURE__ */ jsx2("span", { className: "brand", children: "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A" }),
        /* @__PURE__ */ jsx2(UserMenu, {})
      ] });
    }
    function UserMenu() {
      const { user, signIn, signOut } = useAuth();
      if (!user) return /* @__PURE__ */ jsx2("button", { onClick: () => signIn("\u0633\u0627\u0631\u0629"), children: "\u0633\u062C\u0651\u0644 \u0627\u0644\u062F\u062E\u0648\u0644" });
      return /* @__PURE__ */ jsxs("span", { className: "row", children: [
        "\u0623\u0647\u0644\u0627\u064B\u060C ",
        user.name,
        /* @__PURE__ */ jsx2("button", { className: "secondary", onClick: signOut, children: "\u0633\u062C\u0651\u0644 \u0627\u0644\u062E\u0631\u0648\u062C" })
      ] });
    }
    function Profile() {
      const { user } = useAuth();
      return /* @__PURE__ */ jsxs("section", { className: "card", children: [
        /* @__PURE__ */ jsx2("h2", { children: "\u0645\u0644\u0641\u0643 \u0627\u0644\u0634\u062E\u0635\u064A" }),
        /* @__PURE__ */ jsx2("p", { className: "muted", children: user ? `${user.name} \xB7 \u0639\u0636\u0648 \u0645\u0646\u0630 2025` : "\u0632\u0627\u0626\u0631" })
      ] });
    }
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsxs(AuthProvider, { children: [
        /* @__PURE__ */ jsx2(Header, {}),
        /* @__PURE__ */ jsx2("main", { children: /* @__PURE__ */ jsx2(Profile, {}) })
      ] })
    );
  }
});
export default require_context();
