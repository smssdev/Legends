type Product = { id: number; name: string; price: number };

function isProduct(value: unknown): value is Product {
  return (
    typeof value === "object" && value !== null &&
    "id" in value && typeof value.id === "number" &&
    "name" in value && typeof value.name === "string" &&
    "price" in value && typeof value.price === "number"
  );
}

function isProductList(value: unknown): value is Product[] {
  return Array.isArray(value) && value.every(isProduct);
}

for (const json of ['[{"id":1,"name":"Book","price":25}]', '[{"id":1,"name":"Book","price":"25"}]', '{"id":1}']) {
  const data: unknown = JSON.parse(json);
  console.log(isProductList(data) ? `OK: ${data.length} product(s)` : "Rejected");
}
