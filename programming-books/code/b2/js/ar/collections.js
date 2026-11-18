// Map: مفاتيح من أي نوع، بترتيب الإضافة
const visits = new Map();
for (const page of ["/home", "/shop", "/home", "/cart", "/home"]) {
  visits.set(page, (visits.get(page) ?? 0) + 1);
}
console.log(visits);
console.log([...visits].toSorted((a, b) => b[1] - a[1])[0]);

// Set: كل قيمة مرة واحدة
const tags = new Set(["js", "css", "js", "html", "css"]);
console.log(tags.size, tags.has("css"), [...tags]);
