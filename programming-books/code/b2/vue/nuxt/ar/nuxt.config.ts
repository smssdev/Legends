export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: false },
  css: ["~/assets/main.css"],
  // كيف يُصنع كل عنوان: يُرسم مسبقاً وقت البناء، أو يُخزَّن ويُحدَّث في الخلفية
  routeRules: {
    "/": { prerender: true },
    "/contact": { prerender: true },
    "/products": { swr: 60 },
    "/products/**": { swr: 3600 },
  },
});
