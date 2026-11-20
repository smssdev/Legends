type Product = { name: string; price: number; quantity: number };

function lineTotal(product: Product) {
  return product.price * product.quantitiy;
}

const book: Product = { name: "Book", price: "25", quantity: 2 };
lineTotal(book);
lineTotal({ name: "Mug", price: 8 });
