import { slugify, truncate, clamp, percent } from "./index.mjs";

const title = "  Modern JavaScript in Depth!  ";
console.log(slugify(title));
console.log(truncate(title.trim(), 18));
console.log(clamp(140, 0, 100), clamp(-5, 0, 100));
console.log(percent(7, 20) + "%");
