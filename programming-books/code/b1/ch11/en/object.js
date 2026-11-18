const book = {
  title: "Code from Zero",
  pages: 340,
  inStock: true,
  tags: ["beginners", "javascript"],
};

console.log(book.title);
console.log(book["pages"]);
console.log(book.tags[0]);

book.pages = 352;
book.price = 25;
console.log(book);
