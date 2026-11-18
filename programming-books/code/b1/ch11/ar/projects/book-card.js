const book = {
  title: "الأمير الصغير",
  author: "أنطوان دو سانت إكزوبيري",
  pages: 312,
  read: false,
};

book.read = true;
book.rating = 5;

for (const [key, value] of Object.entries(book)) {
  console.log(key + ":", value);
}
console.log("عدد الخصائص:", Object.keys(book).length);
