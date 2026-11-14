<script setup lang="ts">
// [X89] Said on the screen whenever the game sends an email (the owner's report 2026-11-02: most coaches never look in
// spam): where it went, and, if it is not in the inbox within a minute, the three steps to find it and to make the next
// ones land in the inbox. «أرسل مرة أخرى» when the screen can send it again.
import { EMAIL } from '../content/site'

defineProps<{ to?: string | null; resend?: boolean; busy?: boolean }>()
defineEmits<{ resend: [] }>()
</script>

<template>
  <section
    class="flex flex-col gap-3 rounded-xl border border-success/40 bg-success/10 p-4 text-sm"
    role="status"
    :aria-label="$t('أرسلنا لك بريداً')"
  >
    <p class="flex items-start gap-2 font-bold text-success">
      <svg viewBox="0 0 24 24" class="mt-0.5 size-5 shrink-0" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
        <path d="M3 6h18v12H3zM3 7l9 6 9-6" />
      </svg>
      <span
        >{{ to ? $t('أرسلنا الرسالة إلى {v0}.', { v0: to }) : $t('أرسلنا الرسالة إلى بريدك.') }}
        <span class="font-normal text-text"
          >{{ $t('من') }} <b dir="ltr">{{ EMAIL }}</b></span
        ></span
      >
    </p>
    <div class="rounded-lg bg-surface p-3">
      <b class="block pb-1">{{ $t('لم تجدها خلال دقيقة؟') }}</b>
      <ol class="list-decimal space-y-1 ps-5 text-text-soft">
        <li>{{ $t('افتح مجلد «الرسائل غير المرغوب فيها» (Spam) في بريدك، وفي Gmail أيضاً «العروض الترويجية».') }}</li>
        <li>{{ $t('افتح رسالتنا واضغط «ليست رسالة غير مرغوب فيها» (Not spam)، فتصلك رسائلنا بعدها في البريد الوارد.') }}</li>
        <li>{{ $t('أضف {v0} إلى جهات الاتصال.', { v0: EMAIL }) }}</li>
      </ol>
    </div>
    <button
      v-if="resend"
      type="button"
      class="h-touch self-start rounded-md bg-surface-raised px-4 font-bold disabled:opacity-40"
      :disabled="busy"
      @click="$emit('resend')"
    >
      {{ busy ? '...' : $t('أرسل مرة أخرى') }}
    </button>
  </section>
</template>
