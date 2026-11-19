export type Post = { slug: string; title: string; body: string; minutes: number };

export const posts: Post[] = [
  { slug: "why-typescript", title: "لماذا أحب TypeScript", body: "الأنواع تلتقط الأخطاء وأنا أكتب، فتبقى أمسياتي فارغة.", minutes: 4 },
  { slug: "rules-for-state", title: "ثلاث قواعد للحالة", body: "احفظ الأقل، واحسب الباقي، واجعل لكل قطعة مالكاً واحداً.", minutes: 6 },
  { slug: "keys-explained", title: "المفاتيح ببساطة", body: "المفتاح يخبر Vue أي عنصر هو أيّه بين تحديثين.", minutes: 3 },
];
