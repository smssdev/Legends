// en/projects/use-api.ts
import { createServer } from "node:http";

// en/projects/api.ts
import { z } from "zod";
var Product = z.object({ id: z.number(), name: z.string(), price: z.number().nonnegative() });
function createApi(base, fetcher = fetch) {
  async function get(path, schema) {
    let response;
    try {
      response = await fetcher(base + path, { signal: AbortSignal.timeout(2e3) });
    } catch (e) {
      return { ok: false, error: { kind: "network", message: e.name } };
    }
    if (response.status === 404) return { ok: false, error: { kind: "not-found", path } };
    if (!response.ok) return { ok: false, error: { kind: "server", status: response.status } };
    const parsed = schema.safeParse(await response.json());
    if (!parsed.success) {
      return { ok: false, error: { kind: "invalid", issues: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`) } };
    }
    return { ok: true, data: parsed.data };
  }
  return {
    products: () => get("/products", z.array(Product)),
    product: (id) => get(`/products/${id}`, Product)
  };
}

// en/projects/use-api.ts
var server = createServer((req, res) => {
  res.setHeader("Content-Type", "application/json");
  if (req.url === "/products") return res.end(JSON.stringify([{ id: 1, name: "Code from Zero", price: 25 }]));
  if (req.url === "/products/2") return res.end(JSON.stringify({ id: 2, name: "Bit mug", price: "8" }));
  if (req.url === "/products/3") return void setTimeout(() => res.end("{}"), 3e3);
  res.writeHead(404).end();
});
await new Promise((ready) => server.listen(0, ready));
var api = createApi(`http://localhost:${server.address().port}`);
for (const call of [() => api.products(), () => api.product(9), () => api.product(2), () => api.product(3)]) {
  const result = await call();
  if (result.ok) console.log("\u2713 Products:", JSON.stringify(result.data));
  else console.log("\u2717", JSON.stringify(result.error));
}
server.closeAllConnections();
server.close();
