import { computed } from "vue";
import { defineStore } from "pinia";
import { useLocalStorage } from "@vueuse/core";
import { makeT } from "./i18n/format";
import type { Lang } from "./i18n/messages";

// إعدادات التطبيق في مخزن Pinia، وuseLocalStorage تتذكرها
export const useSettings = defineStore("settings", () => {
  const lang = useLocalStorage<Lang>("admin-lang", globalThis.document?.documentElement.lang === "ar" ? "ar" : "en");
  const dark = useLocalStorage("admin-dark", false);
  const t = computed(() => makeT(lang.value));

  return {
    lang,
    dark,
    t,
    toggleLanguage: () => (lang.value = lang.value === "en" ? "ar" : "en"),
    toggleDark: () => (dark.value = !dark.value),
  };
});
