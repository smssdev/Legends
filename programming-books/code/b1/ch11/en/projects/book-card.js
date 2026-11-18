const book = {
  title: "The Little Prince",
  author: "Antoine de Saint-Exupéry",
  pages: 312,
  read: false,
};

book.read = true;
book.rating = 5;

for (const [key, value] of Object.entries(book)) {
  console.log(key + ":", value);
}
console.log("Properties:", Object.keys(book).length);
