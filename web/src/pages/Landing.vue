<script setup lang="ts">
// [X58] The visitor's home page (the owner's request 2026-10-29): what GLM is, what is in it, how to start, and the
// common questions, all readable before signing in, as Google AdSense asks of a site, and as a visitor deserves.
// Every number in it is the game's own (the slots, the guide); nothing here is a rule, only a description.
import PublicFooter from '../components/PublicFooter.vue'

const FEATURES = [
  { icon: '◎', title: 'مباراة حية تديرها لحظة بلحظة', body: 'تابع مباراتك دقيقة بدقيقة، وبدّل لاعبيك وغيّر تكتيكك أثناء اللعب، وخصمك يرى ما يحدث في الملعب لا خطتك.' },
  { icon: '⚑', title: 'دوريات خاصة مع أصحابك', body: 'أنشئ دورياً بكود، وادعُ أصحابك برابط على واتساب، وتنافسوا على الدوري والكأس كل موسم.' },
  { icon: '♟', title: 'تكتيك له معنى', body: 'خطة اللعب، والضغط، والأسلوب، والإيقاع، والرقابة، ومصيدة التسلل. التكتيك يغيّر طريقة لعب فريقك، فيكون للأضعف رد على الأقوى.' },
  { icon: '⇄', title: 'سوق انتقالات حي', body: 'اشترِ من السوق ومن المدربين الآخرين، واعرض لاعبيك للبيع، وأرسل الكشاف يبحث لك عن المواهب.' },
  { icon: '▲', title: 'التدريب والجهاز الفني', body: 'تعاقد مع مدرب لكل خط، ودرّب لاعبيك ليتطوروا حسب أعمارهم وإمكانياتهم.' },
  { icon: '▣', title: 'ملعبك وأموال ناديك', body: 'ابنِ المدرجات وأرضية الملعب ومنشأة التدريب، واختر الراعي المناسب، وأدر ميزانية ناديك.' },
  { icon: '▶', title: 'مشهد المباراة والمعلق', body: 'شاهد كل هجمة على ملعب متحرك، مع تعليق مكتوب ومعلق صوتي بالإنجليزية، ومشهد ثلاثي الأبعاد قادم.' },
  { icon: '✦', title: 'المدرب المساعد', body: 'مساعدك في كل شاشة: يشرح لك أي جزء من اللعبة، ويقرأ أرقام فريقك وينصحك، والقرار لك.' },
]
const STEPS = [
  { title: 'أنشئ حسابك', body: 'بحساب Google بنقرة، أو بثلاث خانات: الاسم واسم المستخدم وكلمة المرور.' },
  { title: 'أنشئ دورياً أو انضم بكود', body: 'دوري خاص بأصحابك، تختار فيه عدد الفرق وأوقات المباريات.' },
  { title: 'جهّز ناديك', body: 'اختر ناديك المفضل، ورتّب التشكيلة، واضبط التكتيك، وابدأ التدريب.' },
  { title: 'عِش المباراة', body: 'ادخل المباراة مباشرة وأدرها، أو اتركها تُلعب بخطتك وتابع ملخصها بعدها.' },
]
const FAQ = [
  { q: 'هل اللعبة مجانية؟', a: 'نعم، بالكامل. تموّلها الإعلانات، ولا شيء فيها يُشترى بمال حقيقي.' },
  { q: 'هل أحتاج إلى تحميل تطبيق؟', a: 'لا. تعمل من المتصفح على الجوال والكمبيوتر، ويمكنك تثبيتها على الشاشة الرئيسية كتطبيق.' },
  { q: 'ماذا لو فاتتني مباراة؟', a: 'تُلعب وحدها بتشكيلتك وتكتيكك، وتجد عند عودتك ملخصاً سريعاً لما فاتك.' },
  { q: 'كم نادياً أدرّب؟', a: 'حتى 8 أندية في دوريات مختلفة، تُفتح فتحاتها مع عمر حسابك.' },
  { q: 'هل الأندية واللاعبون حقيقيون؟', a: 'الأسماء لأغراض اللعب فقط، وGLM لعبة مستقلة غير تابعة لأي نادٍ أو دوري أو اتحاد.' },
  { q: 'بأي لغة اللعبة؟', a: 'بالعربية والإنجليزية، وتبدّل بينهما متى شئت.' },
]
</script>

<template>
  <div class="landing -mx-3 -mt-5 flex flex-col md:-mx-6">
    <!-- The hero: the stadium at night, the promise and the two ways in. -->
    <section class="hero theme-night relative overflow-hidden px-4 py-14 text-center md:py-24">
      <div class="relative mx-auto flex max-w-3xl flex-col items-center gap-5">
        <img src="/brand/emblem.svg" alt="GLM" class="size-28 drop-shadow-[0_10px_30px_rgba(245,184,46,0.35)] md:size-36" />
        <span class="rounded-pill bg-gold/15 px-4 py-1 text-sm font-bold text-gold">{{ $t('لعبة إدارة كرة قدم عربية مجانية') }}</span>
        <h1 class="font-display text-4xl font-extrabold leading-tight md:text-6xl">{{ $t('دوريك. فريقك.') }} <span class="text-gold">{{ $t('أسطورتك.') }}</span></h1>
        <p class="max-w-xl text-lg text-text-soft">{{ $t('درّب ناديك المفضل ضد أصحابك في دوريات خاصة، وأدر كل مباراة مباشرة لحظة بلحظة، من الجوال أو الكمبيوتر.') }}</p>
        <div class="flex flex-wrap justify-center gap-3">
          <RouterLink to="/register" class="flex h-12 items-center rounded-lg bg-gold px-7 text-lg font-bold text-on-gold">{{ $t('ابدأ مجاناً') }}</RouterLink>
          <RouterLink to="/guide" class="flex h-12 items-center rounded-lg border border-text/25 px-7 font-bold">{{ $t('طريقة اللعب') }}</RouterLink>
        </div>
        <RouterLink to="/login" class="flex min-h-touch items-center text-sm text-text-muted">{{ $t('عندك حساب؟') }} <b class="ms-1 text-gold">{{ $t('سجّل الدخول') }}</b></RouterLink>
      </div>
    </section>

    <div class="mx-auto flex w-full max-w-5xl flex-col gap-14 px-4 py-12">
      <!-- What is in the game. -->
      <section class="flex flex-col gap-5" aria-labelledby="l-features">
        <div class="flex flex-col gap-2 text-center">
          <h2 id="l-features" class="font-display text-3xl font-extrabold">{{ $t('كل ما يحتاجه مدرب حقيقي') }}</h2>
          <p class="text-text-soft">{{ $t('إدارة كاملة لناديك، بواجهة بسيطة تتنقل فيها بسهولة.') }}</p>
        </div>
        <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <article v-for="f in FEATURES" :key="f.title" class="flex flex-col gap-2 rounded-2xl border border-text/10 bg-surface p-5">
            <span class="grid size-11 place-items-center rounded-full bg-brand text-xl text-white shadow-md" aria-hidden="true">{{ f.icon }}</span>
            <h3 class="font-bold">{{ $t(f.title) }}</h3>
            <p class="text-sm leading-relaxed text-text-soft">{{ $t(f.body) }}</p>
          </article>
        </div>
      </section>

      <!-- How to start. -->
      <section class="flex flex-col gap-5" aria-labelledby="l-steps">
        <h2 id="l-steps" class="text-center font-display text-3xl font-extrabold">{{ $t('ابدأ في أربع خطوات') }}</h2>
        <ol class="grid gap-3 md:grid-cols-4">
          <li v-for="(s, i) in STEPS" :key="s.title" class="flex flex-col gap-2 rounded-2xl bg-surface p-5">
            <span class="font-numbers text-3xl font-extrabold text-gold">{{ i + 1 }}</span>
            <h3 class="font-bold">{{ $t(s.title) }}</h3>
            <p class="text-sm leading-relaxed text-text-soft">{{ $t(s.body) }}</p>
          </li>
        </ol>
      </section>

      <!-- Why GLM. -->
      <section class="grid gap-3 rounded-2xl border border-gold/30 bg-surface p-6 md:grid-cols-3" :aria-label="$t('لماذا GLM؟')">
        <div class="flex flex-col gap-1"><b class="text-gold">{{ $t('عربية من الأساس') }}</b><p class="text-sm text-text-soft">{{ $t('صُممت بالعربية أولاً، بأسماء الأندية واللاعبين بالعربية، ومعها الإنجليزية.') }}</p></div>
        <div class="flex flex-col gap-1"><b class="text-gold">{{ $t('مجانية بالكامل') }}</b><p class="text-sm text-text-soft">{{ $t('بلا اشتراك، ولا شيء يُشترى بمال حقيقي: الفوز بقرارك لا بمحفظتك.') }}</p></div>
        <div class="flex flex-col gap-1"><b class="text-gold">{{ $t('على أي جهاز') }}</b><p class="text-sm text-text-soft">{{ $t('من المتصفح على الجوال والكمبيوتر، وحسابك واحد على كل الأجهزة.') }}</p></div>
      </section>

      <!-- The common questions. -->
      <section class="flex flex-col gap-4" aria-labelledby="l-faq">
        <h2 id="l-faq" class="text-center font-display text-3xl font-extrabold">{{ $t('أسئلة شائعة') }}</h2>
        <div class="mx-auto flex w-full max-w-3xl flex-col gap-2">
          <details v-for="f in FAQ" :key="f.q" class="rounded-xl bg-surface px-4">
            <summary class="flex min-h-touch cursor-pointer items-center font-bold">{{ $t(f.q) }}</summary>
            <p class="pb-4 leading-relaxed text-text-soft">{{ $t(f.a) }}</p>
          </details>
        </div>
        <RouterLink to="/guide" class="flex min-h-touch items-center self-center font-bold text-gold">{{ $t('الدليل الكامل: طريقة اللعب') }}</RouterLink>
      </section>

      <!-- The last call. -->
      <section class="flex flex-col items-center gap-4 text-center">
        <h2 class="font-display text-3xl font-extrabold">{{ $t('ناديك ينتظر مدربه') }}</h2>
        <RouterLink to="/register" class="flex h-12 items-center rounded-lg bg-gold px-7 text-lg font-bold text-on-gold">{{ $t('أنشئ حسابك مجاناً') }}</RouterLink>
      </section>
    </div>
    <PublicFooter />
  </div>
</template>

<style scoped>
.hero {
  background:
    url("/art/pattern-star.svg") center / 40px 40px repeat,
    radial-gradient(ellipse 80% 60% at 50% 30%, color-mix(in srgb, var(--color-brand) 45%, transparent), transparent 70%),
    linear-gradient(180deg, color-mix(in srgb, var(--color-bg-deep) 35%, transparent), var(--color-bg-deep)),
    url("/art/stadium-blur.jpg") center / cover no-repeat;
  background-blend-mode: soft-light, normal, normal, normal;
}
</style>
