var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/like.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_like = __commonJS({
  "en/like.tsx"() {
    function LikeButton({ initial }) {
      const [likes, setLikes] = useState(initial);
      const [liked, setLiked] = useState(false);
      function toggle() {
        setLiked(!liked);
        setLikes(liked ? likes - 1 : likes + 1);
      }
      return /* @__PURE__ */ jsxs("button", { className: liked ? "" : "secondary", "aria-pressed": liked, onClick: toggle, children: [
        liked ? "\u2665 Liked" : "\u2661 Like",
        " \xB7 ",
        likes,
        " likes"
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
