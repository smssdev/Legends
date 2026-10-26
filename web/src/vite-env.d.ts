/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_REVERB_APP_KEY?: string
  readonly VITE_REVERB_HOST?: string
  readonly VITE_REVERB_PORT?: string
  readonly VITE_REVERB_SCHEME?: string
}

// The names switch's helpers in every template [X40, lib/names.ts].
declare module 'vue' {
  interface ComponentCustomProperties {
    $pn: (s: string | null | undefined) => string
    $cn: (s: string | null | undefined) => string
    $ln: (s: string | null | undefined) => string
    $nm: (s: string | null | undefined) => string
    // [UP2] A sentence in the coach's language (lib/i18n.ts).
    $t: (ar: string, vars?: Record<string, string | number>) => string
  }
}
export {}
