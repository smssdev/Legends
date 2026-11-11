// [Sprint 55 W1] The dock stands at the line's start (right in Arabic, left in English), so what it opens drops beside
// it on the other side.
import { computed } from 'vue'
import { locale } from '../../lib/i18n'

export const dockSide = computed<'left' | 'right'>(() => (locale.value === 'ar' ? 'left' : 'right'))
