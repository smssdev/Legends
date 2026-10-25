<script setup lang="ts">
// Sign-in screens (docs/design/legends-ui: WebLogin, MobileLogin, WebRegister, MobileRegister):
// on the computer the brand on one side and the form on the other; on the phone the form alone.
</script>

<template>
  <div class="grid min-h-dvh md:grid-cols-2">
    <aside class="relative hidden overflow-hidden bg-gradient-to-b from-[#123a7a] to-bg-deep md:flex md:flex-col md:justify-center md:gap-6 md:p-14">
      <!-- Our night stadium behind the brand [X29]. -->
      <img src="/art/stadium-night.svg" alt="" aria-hidden="true" class="pointer-events-none absolute inset-0 size-full object-cover object-bottom opacity-90" />
      <div class="pointer-events-none absolute inset-0 bg-gradient-to-b from-bg-deep/70 via-transparent to-bg-deep/40" aria-hidden="true" />
      <img src="/brand/emblem.svg" alt="الأساطير" class="relative size-48 drop-shadow-[0_10px_30px_rgba(245,184,46,0.35)]" />
      <h2 class="relative font-display text-5xl font-extrabold leading-tight">دوريك. فريقك.<br /><span class="text-gold">أسطورتك.</span></h2>
      <p class="relative text-lg text-text-soft">درّب ناديك المفضل ضد أصحابك، وعِش كل مباراة لحظة بلحظة.</p>
      <ul class="relative flex flex-col gap-3 text-text-soft">
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-lg bg-surface/80 text-gold backdrop-blur">◎</span>مباراة حية: تبدّل وتغيّر تكتيكك لحظياً</li>
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-lg bg-surface/80 text-gold backdrop-blur">⚑</span>دوريات خاصة بكود مع أصحابك</li>
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-lg bg-surface/80 text-gold backdrop-blur">★</span>أندية ولاعبون حقيقيون، ودوري وكأس كل موسم</li>
      </ul>
    </aside>
    <main class="relative flex flex-col justify-center overflow-hidden px-4 py-8 md:px-14">
      <!-- On the phone the stadium tops the form. -->
      <img src="/art/stadium-night.svg" alt="" aria-hidden="true" class="pointer-events-none absolute inset-x-0 top-0 -z-10 h-64 w-full object-cover object-bottom opacity-60 md:hidden" />
      <div class="mx-auto flex w-full max-w-md flex-col gap-5">
        <RouterLink to="/" class="flex items-center gap-3 md:hidden">
          <BrandMark />
        </RouterLink>
        <RouterView />
      </div>
    </main>
  </div>
</template>
