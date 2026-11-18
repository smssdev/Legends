const products = [
  { id: 1, name: "البرمجة من الصفر", price: 25, category: "كتاب" },
  { id: 2, name: "كوب بِت", price: 8, category: "كوب" },
  { id: 3, name: "هندسة الواجهات", price: 30, category: "كتاب" },
  { id: 4, name: "ملصق بِت", price: 3, category: "ملصق" },
];

const books = products.filter((p) => p.category === "كتاب");
console.log(books.map((p) => p.name));

const found = products.find((p) => p.id === 2);
console.log(found.name, found.price);

const cheapest = products.reduce((a, b) => (b.price < a.price ? b : a));
console.log(cheapest.name);
