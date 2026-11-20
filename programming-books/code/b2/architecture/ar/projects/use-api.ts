import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { createApi } from "./api";

// خادم وهمي للمثال، فيه منتج واحد، ورد بطيء، وآخر مكسور
const server = createServer((req, res) => {
  res.setHeader("Content-Type", "application/json");
  if (req.url === "/products") return res.end(JSON.stringify([{ id: 1, name: "البرمجة من الصفر", price: 25 }]));
  if (req.url === "/products/2") return res.end(JSON.stringify({ id: 2, name: "Bit mug", price: "8" }));
  if (req.url === "/products/3") return void setTimeout(() => res.end("{}"), 3000);
  res.writeHead(404).end();
});
await new Promise<void>((ready) => server.listen(0, ready));
const api = createApi(`http://localhost:${(server.address() as AddressInfo).port}`);

for (const call of [() => api.products(), () => api.product(9), () => api.product(2), () => api.product(3)]) {
  const result = await call();
  if (result.ok) console.log("✓ المنتجات:", JSON.stringify(result.data));
  else console.log("✗", JSON.stringify(result.error));
}
server.closeAllConnections();
server.close();
