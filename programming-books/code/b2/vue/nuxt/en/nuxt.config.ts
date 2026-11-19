export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: false },
  css: ["~/assets/main.css"],
  // How each address is made: prerendered at build time, or cached and refreshed in the background
  routeRules: {
    "/": { prerender: true },
    "/contact": { prerender: true },
    "/products": { swr: 60 },
    "/products/**": { swr: 3600 },
  },
});
