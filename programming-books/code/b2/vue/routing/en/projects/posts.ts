export type Post = { slug: string; title: string; body: string; minutes: number };

export const posts: Post[] = [
  { slug: "why-typescript", title: "Why I love TypeScript", body: "Types catch mistakes while I type, so my evenings are free.", minutes: 4 },
  { slug: "rules-for-state", title: "Three rules for state", body: "Keep it minimal, compute the rest, and give each piece one owner.", minutes: 6 },
  { slug: "keys-explained", title: "Keys, explained", body: "A key tells Vue which item is which between two updates.", minutes: 3 },
];
