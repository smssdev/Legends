// ar/plurals.ts
var ar = new Intl.PluralRules("ar");
var en = new Intl.PluralRules("en");
for (const n of [0, 1, 2, 3, 10, 11, 100, 101]) {
  console.log(String(n).padStart(3), "ar:", ar.select(n).padEnd(5), " en:", en.select(n));
}
console.log("ar categories:", ar.resolvedOptions().pluralCategories.join(", "));
