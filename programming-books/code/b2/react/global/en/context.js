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

// en/auth.tsx
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
  "en/auth.tsx"() {
    AuthContext = createContext(null);
  }
});

// en/context.tsx
import { createRoot } from "react-dom/client";
import { jsx as jsx2, jsxs } from "react/jsx-runtime";
var require_context = __commonJS({
  "en/context.tsx"() {
    init_auth();
    function Header() {
      return /* @__PURE__ */ jsxs("header", { children: [
        /* @__PURE__ */ jsx2("span", { className: "brand", children: "Bit's shop" }),
        /* @__PURE__ */ jsx2(UserMenu, {})
      ] });
    }
    function UserMenu() {
      const { user, signIn, signOut } = useAuth();
      if (!user) return /* @__PURE__ */ jsx2("button", { onClick: () => signIn("Sara"), children: "Sign in" });
      return /* @__PURE__ */ jsxs("span", { className: "row", children: [
        "Hello, ",
        user.name,
        /* @__PURE__ */ jsx2("button", { className: "secondary", onClick: signOut, children: "Sign out" })
      ] });
    }
    function Profile() {
      const { user } = useAuth();
      return /* @__PURE__ */ jsxs("section", { className: "card", children: [
        /* @__PURE__ */ jsx2("h2", { children: "Your profile" }),
        /* @__PURE__ */ jsx2("p", { className: "muted", children: user ? `${user.name} \xB7 Member since 2025` : "Guest" })
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
