<script setup lang="ts">
// Sign-in screens (docs/design/legends-ui: WebLogin, MobileLogin, WebRegister, MobileRegister):
// on the computer the brand on one side and the form on the other; on the phone the form alone.
</script>

<template>
  <div class="grid min-h-dvh md:grid-cols-2">
    <aside class="relative hidden overflow-hidden bg-gradient-to-b from-[#123a7a] to-bg-deep md:flex md:flex-col md:justify-center md:gap-6 md:p-14">
      <img src="/icon-512.png" alt="" class="size-44 rounded-xxl" />
      <h2 class="font-display text-5xl font-extrabold leading-tight">دوريك. فريقك.<br /><span class="text-gold">أسطورتك.</span></h2>
      <p class="text-lg text-text-soft">درّب ناديك المفضل ضد أصحابك، وعِش كل مباراة لحظة بلحظة.</p>
      <ul class="flex flex-col gap-3 text-text-soft">
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-lg bg-surface text-gold">◎</span>مباراة حية: تبدّل وتغيّر تكتيكك لحظياً</li>
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-lg bg-surface text-gold">⚑</span>دوريات خاصة بكود مع أصحابك</li>
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-lg bg-surface text-gold">★</span>أندية ولاعبون حقيقيون، ودوري وكأس كل موسم</li>
      </ul>
    </aside>
    <main class="flex flex-col justify-center px-4 py-8 md:px-14">
      <div class="mx-auto flex w-full max-w-md flex-col gap-5">
        <RouterLink to="/" class="flex items-center gap-3 md:hidden">
          <img src="/icon-192.png" alt="" class="size-10 rounded-md" />
          <span class="font-display text-xl font-extrabold tracking-wide text-gold" dir="ltr">LEGENDS</span>
        </RouterLink>
        <RouterView />
      </div>
    </main>
  </div>
</template>
