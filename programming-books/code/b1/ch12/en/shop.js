const catalog = [
  { id: 1, name: "Code from Zero", price: 25 },
  { id: 2, name: "Bit mug", price: 8 },
  { id: 3, name: "Bit sticker", price: 3 },
  { id: 4, name: "Bit T-shirt", price: 15 },
];

const cart = [];

// Draw one card per product
function renderProducts() {
  const container = document.querySelector("#products");
  for (const product of catalog) {
    const card = document.createElement("article");
    card.className = "card";

    const name = document.createElement("h3");
    name.textContent = product.name;

    const price = document.createElement("p");
    price.textContent = `$${product.price}`;

    const button = document.createElement("button");
    button.textContent = "Add to cart";
    button.addEventListener("click", () => addToCart(product.id));

    card.append(name, price, button);
    container.append(card);
  }
}

function addToCart(productId) {
  const line = cart.find((item) => item.productId === productId);
  if (line) {
    line.quantity++;
  } else {
    cart.push({ productId, quantity: 1 });
  }
  renderCart();
}

// Redraw the cart from the data every time it changes
function renderCart() {
  const list = document.querySelector("#cart-lines");
  list.replaceChildren();

  let total = 0;
  for (const item of cart) {
    const product = catalog.find((p) => p.id === item.productId);
    const lineTotal = product.price * item.quantity;
    total += lineTotal;

    const li = document.createElement("li");
    li.textContent = `${product.name} × ${item.quantity}`;
    const amount = document.createElement("span");
    amount.textContent = `$${lineTotal}`;
    li.append(amount);
    list.append(li);
  }

  document.querySelector("#cart-total").textContent =
    cart.length === 0 ? "Your cart is empty." : `Total: $${total}`;
}

renderProducts();
renderCart();
