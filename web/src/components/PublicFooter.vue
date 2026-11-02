<script setup lang="ts">
// [X59] The foot of the public pages: the guide, the developers, the privacy policy, the terms and the support.
import SupportLinks from './SupportLinks.vue'
</script>

<template>
  <footer class="border-t border-text/10 bg-surface-sunk/40">
    <div class="mx-auto flex max-w-5xl flex-col gap-4 px-4 py-6">
      <nav class="flex flex-wrap gap-x-5 text-sm font-bold" :aria-label="$t('روابط')">
        <RouterLink to="/guide" class="flex min-h-touch items-center">{{ $t('طريقة اللعب') }}</RouterLink>
        <RouterLink to="/developers" class="flex min-h-touch items-center">{{ $t('فريق التطوير') }}</RouterLink>
        <RouterLink to="/privacy" class="flex min-h-touch items-center">{{ $t('سياسة الخصوصية') }}</RouterLink>
        <RouterLink to="/terms" class="flex min-h-touch items-center">{{ $t('الشروط والأحكام') }}</RouterLink>
      </nav>
      <SupportLinks compact />
      <p class="text-xs text-text-muted">{{ $t('المدرب الأسطورة لعبة مستقلة، غير تابعة لأي نادٍ أو دوري أو اتحاد كرة قدم.') }} © <span class="font-numbers" dir="ltr">2026</span> <span dir="ltr">Game Legend Manager</span></p>
    </div>
  </footer>
</template>
