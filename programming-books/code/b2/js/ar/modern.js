const user = { name: "عمر", address: null, settings: { theme: "" } };

// ?. تتوقف عند null أو undefined بدل الانهيار
console.log(user.address?.city);
console.log(user.address?.city ?? "غير معروف");

// || تستبدل كل قيمة كاذبة، و?? تستبدل null وundefined فقط
console.log(user.settings.theme || "light", user.settings.theme ?? "light");

// ??= تُسند فقط حين تكون القيمة ناقصة
user.settings.fontSize ??= 16;
console.log(user.settings);

const scores = [72, 95, 88, 61];
console.log(scores.at(-1), scores.findLast((s) => s > 80));
console.log(scores.toSorted((a, b) => b - a), scores); // toSorted تُرجع نسخة: يبقى الأصل بترتيبه
