import { buildApp } from "./app.ts";

const app = await buildApp();
await app.listen({ port: 3000 });
console.log("Listening on http://localhost:3000");
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
