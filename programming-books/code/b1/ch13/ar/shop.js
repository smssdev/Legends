let catalog = [];

const cart = [];

// ارسم بطاقة لكل منتج
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
    button.textContent = "أضف إلى السلة";
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

// أعد رسم السلة من البيانات كلما تغيرت
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
    cart.length === 0 ? "سلتك فارغة." : `المجموع: $${total}`;
}

// حمّل المنتجات من الخادم، ثم ارسم الصفحة
async function start() {
  const status = document.querySelector("#status");
  status.textContent = "جارٍ تحميل المنتجات…";
  try {
    const response = await fetch("products.json");
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    catalog = await response.json();
    status.textContent = "";
    renderProducts();
    renderCart();
  } catch (error) {
    status.textContent = "عذراً، تعذّر تحميل المنتجات. حاول مرة أخرى.";
    console.error(error);
  }
}

start();
