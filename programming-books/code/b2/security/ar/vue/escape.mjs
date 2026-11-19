// security/ar/vue/escape.ts
import { createSSRApp } from "vue";
import { renderToString } from "vue/server-renderer";

// security/ar/vue/Comment.vue
import { defineComponent as _defineComponent } from "vue";
import { createCommentVNode as _createCommentVNode, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, unref as _unref, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var _hoisted_1 = ["href"];
var comment = `<img src="x" onerror="alert('hacked')">`;
var link = "javascript:alert('hacked')";
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Comment",
  setup(__props) {
    const safe = /^https?:\/\//.test(link) ? link : "#";
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _createCommentVNode(" Text in double braces is escaped: it is shown, never run "),
          _createElementVNode("p", null, _toDisplayString(comment)),
          _createCommentVNode(" v-html puts raw HTML into the page "),
          _createElementVNode("p", { innerHTML: comment }),
          _createElementVNode("a", { href: _unref(safe) }, "\u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062E\u0635\u064A", 8, _hoisted_1)
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var Comment_default = _sfc;

// security/ar/vue/escape.ts
var html = await renderToString(createSSRApp(Comment_default));
console.log(html.replace(/<!--\[-->|<!--\]-->/g, "").replaceAll("><", ">\n<"));
