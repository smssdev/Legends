<script setup lang="ts">
// The language switch [UP2]: العربية or English, on the account page and the sign-in page. The names of the leagues,
// clubs and players follow (the names switch [X40] can still change them alone), and a signed-in coach's choice is
// saved on the account for every device.
import { api } from '../api/client'
import { locale, setLocale, type Locale } from '../lib/i18n'
import { setNamesLang } from '../lib/names'
import { useAuth } from '../stores/auth'

// [Sprint 75 W11, WEB-11] Compact on the visitor's bar (the home page's header): each language's own short name.
defineProps<{ compact?: boolean }>()
const auth = useAuth()
async function choose(l: Locale) {
  if (l === locale.value) return
  setLocale(l)
  setNamesLang(l)
  if (auth.user) {
    try {
      const { data } = await api.PATCH('/auth/me', { body: { locale: l } })
      if (data?.user) auth.set(data.user)
    } catch {
      // kept on this device; the account follows next time
    }
  }
}
</script>

<template>
  <div class="inline-flex rounded-lg bg-surface-sunk p-1" role="radiogroup" :aria-label="$t('اللغة')">
    <button
      v-for="[l, label, short] in [
        ['ar', 'العربية', 'ع'],
        ['en', 'English', 'EN'],
      ] as const"
      :key="l"
      type="button"
      role="radio"
      :aria-checked="locale === l"
      :aria-label="compact ? label : undefined"
      class="h-touch rounded-md text-sm font-bold"
      :class="[locale === l ? 'bg-gold text-on-gold' : 'text-text-soft', compact ? 'min-w-touch px-2' : 'px-4']"
      :lang="l"
      @click="choose(l)"
    >
      {{ compact ? short : $t(label) }}
    </button>
  </div>
</template>
