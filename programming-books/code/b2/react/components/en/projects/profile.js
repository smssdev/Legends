var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/projects/profile.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_profile = __commonJS({
  "en/projects/profile.tsx"() {
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
            /* @__PURE__ */ jsx(Stat, { value: person.projects, label: "projects" }),
            /* @__PURE__ */ jsx(Stat, { value: followers, label: "followers" })
          ] }),
          /* @__PURE__ */ jsx("button", { className: following ? "secondary" : "", "aria-pressed": following, onClick: () => setFollowing(!following), children: following ? "Following" : "Follow" })
        ] })
      ] });
    }
    var sara = { name: "Sara", role: "Frontend developer", city: "Alexandria", projects: 12, followers: 340 };
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx(ProfileCard, { person: sara, children: /* @__PURE__ */ jsx("p", { children: "I build fast, accessible web apps with React and TypeScript." }) })
    );
  }
});
export default require_profile();
