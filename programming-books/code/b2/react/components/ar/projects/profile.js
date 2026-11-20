var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/projects/profile.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_profile = __commonJS({
  "ar/projects/profile.tsx"() {
    function Avatar({ name }) {
      return /* @__PURE__ */ jsx("div", { className: "avatar", "aria-hidden": "true", children: name[0] });
    }
    function Stat({ value, label }) {
      return /* @__PURE__ */ jsxs("span", { children: [
        /* @__PURE__ */ jsx("b", { children: value }),
        label
      ] });
    }
    function ProfileCard({ person, children }) {
      const [following, setFollowing] = useState(false);
      const followers = person.followers + (following ? 1 : 0);
      return /* @__PURE__ */ jsxs("article", { className: "profile", children: [
        /* @__PURE__ */ jsx("div", { className: "cover" }),
        /* @__PURE__ */ jsxs("div", { className: "body", children: [
          /* @__PURE__ */ jsx(Avatar, { name: person.name }),
          /* @__PURE__ */ jsx("h2", { children: person.name }),
          /* @__PURE__ */ jsxs("p", { className: "meta", children: [
            person.role,
            " \xB7 ",
            person.city
          ] }),
          children,
          /* @__PURE__ */ jsxs("div", { className: "stats", children: [
            /* @__PURE__ */ jsx(Stat, { value: person.projects, label: "\u0645\u0634\u0627\u0631\u064A\u0639" }),
            /* @__PURE__ */ jsx(Stat, { value: followers, label: "\u0645\u062A\u0627\u0628\u0639\u0648\u0646" })
          ] }),
          /* @__PURE__ */ jsx("button", { className: following ? "secondary" : "", "aria-pressed": following, onClick: () => setFollowing(!following), children: following ? "\u062A\u062A\u0627\u0628\u0639\u0647\u0627" : "\u062A\u0627\u0628\u0650\u0639" })
        ] })
      ] });
    }
    var sara = { name: "\u0633\u0627\u0631\u0629", role: "\u0645\u0637\u0648\u0631\u0629 \u0648\u0627\u062C\u0647\u0627\u062A", city: "\u0627\u0644\u0625\u0633\u0643\u0646\u062F\u0631\u064A\u0629", projects: 12, followers: 340 };
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx(ProfileCard, { person: sara, children: /* @__PURE__ */ jsx("p", { children: "\u0623\u0628\u0646\u064A \u062A\u0637\u0628\u064A\u0642\u0627\u062A \u0648\u064A\u0628 \u0633\u0631\u064A\u0639\u0629 \u0648\u0633\u0647\u0644\u0629 \u0627\u0644\u0648\u0635\u0648\u0644 \u0628\u0640 React \u0648TypeScript." }) })
    );
  }
});
export default require_profile();
