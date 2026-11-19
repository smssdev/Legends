import { computed, inject, provide, watchEffect, type InjectionKey, type Ref } from "vue";
import { useLocalStorage, usePreferredDark } from "@vueuse/core";

type Theme = { dark: Readonly<Ref<boolean>>; toggle: () => void };
const ThemeKey: InjectionKey<Theme> = Symbol("theme");

export function provideTheme() {
  const system = usePreferredDark();
  const saved = useLocalStorage<boolean | null>("dark", null);
  const dark = computed(() => saved.value ?? system.value);
  watchEffect(() => document.documentElement.classList.toggle("dark", dark.value));
  provide(ThemeKey, { dark, toggle: () => (saved.value = !dark.value) });
}

export function useTheme(): Theme {
  const theme = inject(ThemeKey);
  if (!theme) throw new Error("useTheme() must be used inside a component that called provideTheme()");
  return theme;
}
