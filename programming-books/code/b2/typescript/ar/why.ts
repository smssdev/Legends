type Product = { name: string; price: number; quantity: number };

function lineTotal(product: Product) {
  return product.price * product.quantitiy;
}

const book: Product = { name: "كتاب", price: "25", quantity: 2 };
lineTotal(book);
lineTotal({ name: "كوب", price: 8 });
