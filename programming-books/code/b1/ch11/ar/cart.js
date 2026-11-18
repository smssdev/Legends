const catalog = [
  { id: 1, name: "البرمجة من الصفر", price: 25 },
  { id: 2, name: "كوب بِت", price: 8 },
  { id: 3, name: "ملصق بِت", price: 3 },
];

const cart = [];

function addToCart(productId, quantity = 1) {
  const line = cart.find((item) => item.productId === productId);
  if (line) {
    line.quantity += quantity;
  } else {
    cart.push({ productId, quantity });
  }
}

function lineTotal(item) {
  const product = catalog.find((p) => p.id === item.productId);
  return product.price * item.quantity;
}

function cartTotal() {
  return cart.reduce((sum, item) => sum + lineTotal(item), 0);
}

addToCart(1);
addToCart(3, 4);
addToCart(1);

for (const item of cart) {
  const product = catalog.find((p) => p.id === item.productId);
  console.log(`${product.name} × ${item.quantity} = ${lineTotal(item)}`);
}
console.log(`المجموع: ${cartTotal()}`);

// جاهزة للحفظ أو الإرسال إلى خادم
console.log(JSON.stringify(cart));
