import { createSSRApp } from "vue";
import { renderToString } from "vue/server-renderer";
import Comment from "./Comment.vue";

const html = await renderToString(createSSRApp(Comment));
console.log(html.replace(/<!--\[-->|<!--\]-->/g, "").replaceAll("><", ">\n<"));
