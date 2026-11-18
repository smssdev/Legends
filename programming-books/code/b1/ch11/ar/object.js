const book = {
  title: "البرمجة من الصفر",
  pages: 340,
  inStock: true,
  tags: ["مبتدئين", "جافاسكربت"],
};

console.log(book.title);
console.log(book["pages"]);
console.log(book.tags[0]);

book.pages = 352;
book.price = 25;
console.log(book);
