import { useMemo } from "react";
import { create } from "zustand";
import { persist } from "zustand/middleware";
import { makeT } from "./i18n/format";
import type { Lang } from "./i18n/messages";

type Settings = { lang: Lang; dark: boolean; toggleLanguage: () => void; toggleDark: () => void };

export const useSettings = create<Settings>()(
  persist(
    (set) => ({
      lang: globalThis.document?.documentElement.lang === "ar" ? "ar" : "en",
      dark: false,
      toggleLanguage: () => set((s) => ({ lang: s.lang === "en" ? "ar" : "en" })),
      toggleDark: () => set((s) => ({ dark: !s.dark })),
    }),
    { name: "admin-settings" },
  ),
);

export function useT() {
  const lang = useSettings((s) => s.lang);
  return useMemo(() => makeT(lang), [lang]);
}
