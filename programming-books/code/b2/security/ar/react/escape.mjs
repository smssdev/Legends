// ar/react/escape.tsx
import { renderToStaticMarkup } from "react-dom/server";
import { jsx } from "react/jsx-runtime";
var comment = `<img src="x" onerror="alert('hacked')">`;
console.log(renderToStaticMarkup(/* @__PURE__ */ jsx("p", { children: comment })));
console.log(renderToStaticMarkup(/* @__PURE__ */ jsx("p", { dangerouslySetInnerHTML: { __html: comment } })));
var link = "javascript:alert('hacked')";
var safe = /^https?:\/\//.test(link) ? link : "#";
console.log(renderToStaticMarkup(/* @__PURE__ */ jsx("a", { href: safe, children: "\u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062E\u0635\u064A" })));
