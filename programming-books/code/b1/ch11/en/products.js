const products = [
  { id: 1, name: "Code from Zero", price: 25, category: "book" },
  { id: 2, name: "Bit mug", price: 8, category: "mug" },
  { id: 3, name: "Senior Frontend", price: 30, category: "book" },
  { id: 4, name: "Bit sticker", price: 3, category: "sticker" },
];

const books = products.filter((p) => p.category === "book");
console.log(books.map((p) => p.name));

const found = products.find((p) => p.id === 2);
console.log(found.name, found.price);

const cheapest = products.reduce((a, b) => (b.price < a.price ? b : a));
console.log(cheapest.name);
