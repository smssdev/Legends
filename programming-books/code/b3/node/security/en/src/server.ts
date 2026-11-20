import { buildApp } from "./app.ts";
import { config } from "./config.ts";

const app = await buildApp();
await app.listen({ port: config.PORT });
console.log(`Listening on http://localhost:${config.PORT}`);
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
