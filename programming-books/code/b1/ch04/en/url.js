const address = new URL(
  "https://shop.example.com:8080/products/shoes?size=42&color=red#reviews"
);

console.log(address.protocol);
console.log(address.hostname);
console.log(address.port);
console.log(address.pathname);
console.log(address.searchParams.get("size"));
console.log(address.hash);
