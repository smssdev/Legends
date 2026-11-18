type Book = { readonly isbn: string; title: string; subtitle?: string; authors: string[] };

function label(book: Book): string {
  return book.subtitle ? `${book.title}: ${book.subtitle}` : book.title;
}

console.log(label({ isbn: "1", title: "Code from Zero", authors: ["S. Salah"] }));
console.log(label({ isbn: "2", title: "Senior Frontend", subtitle: "React Edition", authors: ["S. Salah"] }));
