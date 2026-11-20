type Product = { readonly id: number; name: string; price: number };
type CartLine = { product: Product; quantity: number };
type Cart = { readonly lines: readonly CartLine[]; coupon?: string };

const DISCOUNTS: Record<string, number> = { WELCOME10: 0.1 };

function add(cart: Cart, product: Product, quantity = 1): Cart {
  const existing = cart.lines.find((line) => line.product.id === product.id);
  const lines = existing
    ? cart.lines.map((line) => (line === existing ? { ...line, quantity: line.quantity + quantity } : line))
    : [...cart.lines, { product, quantity }];
  return { ...cart, lines };
}

function total(cart: Cart): number {
  const sum = cart.lines.reduce((s, line) => s + line.product.price * line.quantity, 0);
  const discount = cart.coupon ? (DISCOUNTS[cart.coupon] ?? 0) : 0;
  return Math.round(sum * (1 - discount) * 100) / 100;
}

const book: Product = { id: 1, name: "Book", price: 25 };
const mug: Product = { id: 2, name: "Mug", price: 8 };

let cart: Cart = { lines: [] };
cart = add(cart, book);
cart = add(cart, mug, 2);
cart = add(cart, book);
console.log(cart.lines.map((l) => `${l.quantity} × ${l.product.name}`).join(", "));
console.log("Total:", total(cart));
console.log("With WELCOME10:", total({ ...cart, coupon: "WELCOME10" }));
