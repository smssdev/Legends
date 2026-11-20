var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/like.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_like = __commonJS({
  "ar/like.tsx"() {
    function LikeButton({ initial }) {
      const [likes, setLikes] = useState(initial);
      const [liked, setLiked] = useState(false);
      function toggle() {
        setLiked(!liked);
        setLikes(liked ? likes - 1 : likes + 1);
      }
      return /* @__PURE__ */ jsxs("button", { className: liked ? "" : "secondary", "aria-pressed": liked, onClick: toggle, children: [
        liked ? "\u2665 \u0623\u0639\u062C\u0628\u0643" : "\u2661 \u0623\u0639\u062C\u0628\u0646\u064A",
        " \xB7 ",
        likes,
        " \u0625\u0639\u062C\u0627\u0628"
      ] });
    }
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsxs("p", { style: { display: "flex", gap: 8 }, children: [
        /* @__PURE__ */ jsx(LikeButton, { initial: 41 }),
        /* @__PURE__ */ jsx(LikeButton, { initial: 7 })
      ] })
    );
  }
});
export default require_like();
