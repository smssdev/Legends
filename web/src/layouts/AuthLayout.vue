<script setup lang="ts">
// Sign-in screens (docs/design/legends-ui: WebLogin, MobileLogin, WebRegister, MobileRegister):
// on the computer the brand on one side and the form on the other; on the phone the form alone.
// [X32] In Legends' signature: our blurred stadium under an emerald glow and the star lattice, the form on a panel.
</script>

<template>
  <div class="grid min-h-dvh md:grid-cols-2">
    <aside class="auth-art relative hidden overflow-hidden md:flex md:flex-col md:justify-center md:gap-6 md:p-14">
      <img src="/brand/emblem.svg" alt="GLM" class="relative size-48 drop-shadow-[0_10px_30px_rgba(245,184,46,0.35)]" />
      <h2 class="relative font-display text-5xl font-extrabold leading-tight">دوريك. فريقك.<br /><span class="text-gold">أسطورتك.</span></h2>
      <p class="relative text-lg text-text-soft">درّب ناديك المفضل ضد أصحابك، وعِش كل مباراة لحظة بلحظة.</p>
      <ul class="relative flex flex-col gap-3 text-text-soft">
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-full bg-brand text-white shadow-md">◎</span>مباراة حية: تبدّل وتغيّر تكتيكك لحظياً</li>
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-full bg-brand text-white shadow-md">⚑</span>دوريات خاصة بكود مع أصحابك</li>
        <li class="flex items-center gap-3"><span class="flex size-9 items-center justify-center rounded-full bg-brand text-white shadow-md">★</span>أندية ولاعبون حقيقيون، ودوري وكأس كل موسم</li>
      </ul>
    </aside>
    <main class="relative flex flex-col justify-center overflow-hidden px-4 py-8 md:px-14">
      <!-- On the phone the stadium tops the form. -->
      <div class="auth-top pointer-events-none absolute inset-x-0 top-0 h-72 md:hidden" aria-hidden="true" />
      <div class="auth-panel relative mx-auto flex w-full max-w-md flex-col gap-5 rounded-2xl p-5 md:p-7">
        <RouterLink to="/" class="flex items-center gap-3 md:hidden">
          <BrandMark />
        </RouterLink>
        <RouterView />
      </div>
    </main>
  </div>
</template>

<style scoped>
.auth-art {
  background:
    url("/art/pattern-star.svg") center / 40px 40px repeat,
    radial-gradient(ellipse 80% 60% at 60% 30%, color-mix(in srgb, var(--color-brand) 45%, transparent), transparent 70%),
    linear-gradient(180deg, color-mix(in srgb, var(--color-bg-deep) 35%, transparent), var(--color-bg-deep)),
    url("/art/stadium-blur.jpg") center / cover no-repeat;
  background-blend-mode: soft-light, normal, normal, normal;
}
.auth-art::after {
  content: "";
  position: absolute;
  inset-block: 0;
  inset-inline-end: 0;
  width: 3px;
  background: linear-gradient(180deg, transparent, var(--color-brand-light), var(--color-gold), transparent);
}
.auth-top {
  background:
    linear-gradient(180deg, transparent 40%, var(--color-bg)),
    radial-gradient(ellipse 90% 70% at 50% 20%, color-mix(in srgb, var(--color-brand) 40%, transparent), transparent 70%),
    url("/art/stadium-blur-m.jpg") center top / cover no-repeat;
}
.auth-panel {
  background: color-mix(in srgb, var(--color-panel) 85%, transparent);
  border: 1px solid color-mix(in srgb, var(--color-brand-light) 22%, transparent);
  border-top: 4px solid var(--color-brand);
  box-shadow: 0 30px 60px -30px rgb(0 0 0 / 0.9);
}
</style>
