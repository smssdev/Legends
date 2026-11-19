import { buildApp } from "./src/app.ts";

const app = await buildApp();
for (const q of ["حز", "x"]) {
  const res = await app.inject(`/v1/products?q=${encodeURIComponent(q)}&limit=1`);
  const body = res.json();
  console.log(res.statusCode, JSON.stringify(body.data?.map((p: { name: string }) => p.name) ?? body.errors));
  if (body.next_cursor) {
    const next = (await app.inject(`/v1/products?q=${encodeURIComponent(q)}&limit=1&cursor=${body.next_cursor}`)).json();
    console.log("next:", JSON.stringify(next.data.map((p: { name: string }) => p.name)));
  }
}
