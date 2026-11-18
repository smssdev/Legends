const user = { name: "Omar", address: null, settings: { theme: "" } };

// ?. stops at null or undefined instead of crashing
console.log(user.address?.city);
console.log(user.address?.city ?? "unknown");

// || replaces every falsy value; ?? only null and undefined
console.log(user.settings.theme || "light", user.settings.theme ?? "light");

// ??= assigns only when the value is missing
user.settings.fontSize ??= 16;
console.log(user.settings);

const scores = [72, 95, 88, 61];
console.log(scores.at(-1), scores.findLast((s) => s > 80));
console.log(scores.toSorted((a, b) => b - a), scores); // toSorted returns a copy: the original keeps its order
